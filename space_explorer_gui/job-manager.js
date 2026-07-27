const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const readline = require("readline");
const db = require("./db");
const analyze = require(path.join(__dirname, "..", "verifier", "analyze.js"));

const PROJECT_ROOT = path.resolve(__dirname, "..");
const SURFACE_GEN_DIR = path.join(PROJECT_ROOT, "surface_generator");
const UNIVERSE_GEN_DIR = path.join(PROJECT_ROOT, "universe_generator", "zig");

// Shared repo output hierarchy (universe → seeds → zones → surface):
//   output/<bucket>/seeds.jsonl                      universe job (bucket = upper bound, e.g. "100k")
//   output/<bucket>/seed_<n>/zones.jsonl             filtered world line for that seed
//   output/<bucket>/seed_<n>/<Zone>/ore.jsonl        surface
//   output/<bucket>/seed_<n>/<Zone>/summary.json
//   output/<bucket>/seed_<n>/<Zone>/ore.png
const OUTPUT_DIR = process.env.SE_GUI_OUTPUT || path.join(PROJECT_ROOT, "output");
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

// Every universe job is exactly one fixed-size bucket. Override with
// UNIVERSE_BUCKET_SIZE (e.g. 10000 for a faster demo).
const BUCKET_SIZE = parseInt(process.env.UNIVERSE_BUCKET_SIZE || "10000");

// Bucket label from the job's upper bound: 100k, 200k, ..., 1M, 1.1M, ...
// K2-enabled buckets get a "-k2" suffix so they live in separate folders/jobs
// from the vanilla run of the same seed range (output/100k vs output/100k-k2).
function bucketLabel(seedEnd, k2) {
  let base;
  if (seedEnd >= 1_000_000) {
    const m = seedEnd / 1_000_000;
    base = `${Number.isInteger(m) ? m : m.toFixed(1)}M`;
  } else {
    base = `${seedEnd / 1000}k`;
  }
  return k2 ? `${base}-k2` : base;
}

function bucketDir(label) {
  return path.join(OUTPUT_DIR, label);
}

function seedDir(label, seed) {
  return path.join(bucketDir(label), `seed_${seed}`);
}

// ── Binary discovery ───────────────────────────────────────────────────

let segenPath = null;
let seedgenPath = null;

function findSegenBinary() {
  if (segenPath && fs.existsSync(segenPath)) return segenPath;
  const candidates = [
    path.join(SURFACE_GEN_DIR, "zig-out", "bin", "segen"),
    path.join(SURFACE_GEN_DIR, "zig-out", "segen"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) { segenPath = c; return c; }
  }
  return null;
}

function findSeedgenBinary() {
  if (seedgenPath && fs.existsSync(seedgenPath)) return seedgenPath;
  const candidates = [
    path.join(UNIVERSE_GEN_DIR, "seedgen"),
    path.join(UNIVERSE_GEN_DIR, "seedgen.native"),
    path.join(UNIVERSE_GEN_DIR, "seedgen-macos"),
    path.join(UNIVERSE_GEN_DIR, "zig-out", "bin", "seedgen"),
    path.join(UNIVERSE_GEN_DIR, "zig-out", "seedgen"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) { seedgenPath = c; return c; }
  }
  return null;
}

function requireSegen() {
  const bin = findSegenBinary();
  if (!bin) throw new Error(
    "segen binary not found. Build it first:\n" +
    "  cd surface_generator && zig build -Doptimize=ReleaseFast"
  );
  return bin;
}

function requireSeedgen() {
  const bin = findSeedgenBinary();
  if (!bin) throw new Error(
    "seedgen binary not found. Build it first:\n" +
    "  cd universe_generator/zig && zig build-exe main.zig gen.zig data.zig -O ReleaseFast -femit-bin=seedgen -target native"
  );
  return bin;
}

// ── Universe bucket creation ───────────────────────────────────────────

// Queue `units` bucket jobs of exactly BUCKET_SIZE seeds each, continuing
// after the highest already-queued/finished bucket. Returns the job ids.
function createUniverseBuckets(units, k2Enabled) {
  const d = db.getDb();
  const k2 = k2Enabled ? 1 : 0;
  // Progress the seed range PER k2-mode: vanilla and K2 each cover 0→N
  // independently (so "0-10M vanilla" and "0-10M K2" can both exist). Cancelled
  // and failed buckets imported no seeds, so ignore them — their ranges are free
  // to reuse, and cancelling everything lets a fresh run restart at 0.
  const row = d.prepare(
    "SELECT MAX(seed_end) AS m FROM universe_jobs WHERE k2_enabled = ? AND status NOT IN ('cancelled','failed')"
  ).get(k2);
  const base = row && row.m ? row.m : 0;
  const ids = [];
  for (let i = 0; i < units; i++) {
    const start = base + i * BUCKET_SIZE;
    const end = start + BUCKET_SIZE;
    const label = bucketLabel(end, k2Enabled);
    const id = db.createUniverseJob(start, end, 1, k2Enabled);
    db.updateUniverseJob(id, { bucket: label });
    ids.push(id);
  }
  return ids;
}

// ── Job processing loop ───────────────────────────────────────────────

// ONE shared worker pool: `maxWorkers` threads, each of which picks up whichever
// job is next (universe seedgen OR surface segen). Optional per-type caps limit
// how many of the pool a type may use at once (default = maxWorkers = no limit,
// i.e. fully shared). Set e.g. universe=5/surface=5 to reserve the split.
let maxWorkers = parseInt(process.env.WORKERS || "10");
let maxUniverse = parseInt(process.env.UNIVERSE_CONCURRENCY || String(maxWorkers));
let maxSurface = parseInt(process.env.SURFACE_CONCURRENCY || String(maxWorkers));
const runningUniverse = new Set();
const runningSurface = new Set();

// Live child processes by job id, so cancel-all can actually kill running work.
const universeChildren = new Map();
const surfaceChildren = new Map();

// Cancel every queued/running job and kill their processes. Jobs already
// marked 'cancelled' are skipped by their close handlers (see the guards) so a
// killed child doesn't resurrect itself as 'failed'/'done'.
function cancelAllJobs() {
  const d = db.getDb();
  const now = new Date().toISOString();
  const u = d.prepare(
    "UPDATE universe_jobs SET status='cancelled', finished_at=? WHERE status IN ('queued','running')"
  ).run(now);
  const s = d.prepare(
    "UPDATE surface_jobs SET status='cancelled', finished_at=? WHERE status IN ('queued','running')"
  ).run(now);
  for (const child of universeChildren.values()) { try { child.kill("SIGTERM"); } catch (_) {} }
  for (const child of surfaceChildren.values()) { try { child.kill("SIGTERM"); } catch (_) {} }
  console.log(`[cancel-all] cancelled ${u.changes} universe + ${s.changes} surface jobs`);
  return { universe: u.changes, surface: s.changes };
}

// FULL RESET for testing: kill running work, wipe all generated data (jobs,
// seeds, zones, filtered sets) from the DB, and empty the output/ directory.
// Config is kept: filter presets (filter_defs) and settings (worker limits).
function wipeSystem() {
  cancelAllJobs(); // mark cancelled + SIGTERM any running children
  const d = db.getDb();
  // FK-safe order: children before parents (seeds/zones reference universe_jobs,
  // surface_jobs reference zones), so universe_jobs is deleted LAST.
  const tables = ["surface_jobs", "zones", "seeds",
                  "seed_filter_members", "seed_filters", "job_logs", "universe_jobs"];
  const tx = d.transaction(() => {
    for (const t of tables) { try { d.prepare(`DELETE FROM ${t}`).run(); } catch (_) {} }
  });
  tx();
  let removed = 0;
  try {
    for (const e of fs.readdirSync(OUTPUT_DIR)) {
      fs.rmSync(path.join(OUTPUT_DIR, e), { recursive: true, force: true });
      removed++;
    }
  } catch (e) { console.log("[wipe] output clear:", e.message); }
  console.log(`[wipe] cleared ${tables.length} tables + ${removed} output entries`);
  return { ok: true, outputRemoved: removed };
}

// Remove all CANCELLED job rows and their on-disk data. A bucket folder is
// deleted only if no surviving (non-cancelled) job shares its label, so live
// data is never touched. Also drops any partial seeds/zones imported under a
// cancelled job. Never kills processes (cancel-all already did).
function clearCancelledJobs() {
  const d = db.getDb();
  const cancelledUniverse = d.prepare("SELECT id, bucket FROM universe_jobs WHERE status='cancelled'").all();

  // Which bucket folders are safe to delete (no non-cancelled job on that label).
  let dirsRemoved = 0;
  const buckets = [...new Set(cancelledUniverse.map(j => j.bucket).filter(Boolean))];
  for (const b of buckets) {
    const survivor = d.prepare(
      "SELECT 1 FROM universe_jobs WHERE bucket=? AND status!='cancelled' LIMIT 1"
    ).get(b);
    if (survivor) continue;
    const dir = bucketDir(b);
    try {
      if (fs.existsSync(dir)) { fs.rmSync(dir, { recursive: true, force: true }); dirsRemoved++; }
    } catch (e) { console.log(`[clear-cancelled] could not remove ${dir}: ${e.message}`); }
  }

  // Cancelled surface jobs first (they may reference zones via FK). No outer
  // transaction: guard each universe-job delete so one blocked by a surviving
  // dependent row (unexpected — cancelled buckets import nothing) is skipped,
  // not the whole sweep.
  const s = d.prepare("DELETE FROM surface_jobs WHERE status='cancelled'").run();
  let uCount = 0;
  for (const j of cancelledUniverse) {
    try {
      d.prepare("DELETE FROM zones WHERE job_id=?").run(j.id); // partial import cleanup (usually 0)
      d.prepare("DELETE FROM seeds WHERE job_id=?").run(j.id);
      d.prepare("DELETE FROM universe_jobs WHERE id=?").run(j.id);
      uCount++;
    } catch (e) {
      console.log(`[clear-cancelled] kept universe job ${j.id} (${j.bucket}): ${e.message}`);
    }
  }
  console.log(`[clear-cancelled] removed ${uCount} universe + ${s.changes} surface entries, ${dirsRemoved} bucket dir(s)`);
  return { universe: uCount, surface: s.changes, dirsRemoved };
}

const clampInt = (n, lo, hi) => Math.max(lo, Math.min(hi, n | 0));

// Set the shared pool size and optional per-type caps. Caps are clamped to the
// pool size. Any field left undefined is unchanged. Persisted to the DB so the
// limits survive restarts.
function setWorkerLimits({ total, universe, surface }, { persist = true } = {}) {
  if (total != null && !Number.isNaN(total)) maxWorkers = clampInt(total, 1, 32);
  if (universe != null && !Number.isNaN(universe)) maxUniverse = clampInt(universe, 0, maxWorkers);
  if (surface != null && !Number.isNaN(surface)) maxSurface = clampInt(surface, 0, maxWorkers);
  maxUniverse = Math.min(maxUniverse, maxWorkers);
  maxSurface = Math.min(maxSurface, maxWorkers);
  if (persist) {
    try { db.setSetting("worker_limits", JSON.stringify({ total: maxWorkers, universe: maxUniverse, surface: maxSurface })); }
    catch (e) { console.log("[workers] persist failed:", e.message); }
  }
}

// Load persisted limits from the DB (overriding the env/default) at startup.
(function loadPersistedWorkerLimits() {
  try {
    const raw = db.getSetting("worker_limits");
    if (raw) setWorkerLimits(JSON.parse(raw), { persist: false });
  } catch (_) { /* table not ready / bad JSON — keep env defaults */ }
})();

// Live snapshot: pool size, per-type caps/running/queued, and the running jobs
// (so the UI can label each worker universe vs surface).
function workerStatus() {
  const d = db.getDb();
  const uniJobs = [...runningUniverse].map(id => db.getUniverseJob(id)).filter(Boolean);
  const surfJobs = [...runningSurface].map(id => db.getSurfaceJob(id)).filter(Boolean);
  const q = (t) => d.prepare(`SELECT COUNT(*) n FROM ${t} WHERE status='queued'`).get().n;
  return {
    total: maxWorkers,
    running: uniJobs.length + surfJobs.length,
    universe: { cap: maxUniverse, running: uniJobs.length, queued: q("universe_jobs"), jobs: uniJobs },
    surface: { cap: maxSurface, running: surfJobs.length, queued: q("surface_jobs"), jobs: surfJobs },
  };
}

function startUniverse(job) {
  db.updateUniverseJob(job.id, { status: "running", started_at: new Date().toISOString() });
  runningUniverse.add(job.id);
  runUniverseBucket(job)
    .catch(e => db.updateUniverseJob(job.id, { status: "failed", error: String(e).slice(0, 500), finished_at: new Date().toISOString() }))
    .finally(() => runningUniverse.delete(job.id));
}

function startSurface(job) {
  db.updateSurfaceJob(job.id, { status: "running", started_at: new Date().toISOString() });
  runningSurface.add(job.id);
  runSurfaceJob(job)
    .catch(e => db.updateSurfaceJob(job.id, { status: "failed", error: String(e).slice(0, 500), finished_at: new Date().toISOString() }))
    .finally(() => runningSurface.delete(job.id));
}

const MAX_RETRIES = parseInt(process.env.WORKER_MAX_RETRIES || "3");
const RETRY_BACKOFF_MS = 15_000;                         // wait before retrying a failure
const JOB_TIMEOUT_MS = parseInt(process.env.WORKER_TIMEOUT_MIN || "20") * 60_000;

// Self-healing sweep (runs every tick): recover from restarts, hangs, and
// transient failures so the queue never wedges.
function recoverJobs() {
  const d = db.getDb();

  // 1. Orphaned 'running' jobs — status says running but no live worker owns
  //    them (e.g. after a server restart/crash). Reset to 'queued' so a worker
  //    picks them up (and the UI stops showing a phantom "running").
  for (const j of d.prepare("SELECT id FROM universe_jobs WHERE status='running'").all())
    if (!runningUniverse.has(j.id)) db.updateUniverseJob(j.id, { status: "queued", started_at: null });
  for (const j of d.prepare("SELECT id FROM surface_jobs WHERE status='running'").all())
    if (!runningSurface.has(j.id)) db.updateSurfaceJob(j.id, { status: "queued", started_at: null });

  // 2. Hung workers — a tracked job running longer than JOB_TIMEOUT_MS. Kill the
  //    process; its close handler fails it and step 3 retries it.
  const cutoff = Date.now() - JOB_TIMEOUT_MS;
  const startedMs = (table, id) => {
    const r = d.prepare(`SELECT started_at FROM ${table} WHERE id=?`).get(id);
    return r && r.started_at ? Date.parse(r.started_at) : Date.now();
  };
  for (const [id, child] of universeChildren)
    if (startedMs("universe_jobs", id) < cutoff) { console.log(`[recover] killing hung universe job ${id}`); try { child.kill("SIGTERM"); } catch (_) {} }
  for (const [id, child] of surfaceChildren)
    if (startedMs("surface_jobs", id) < cutoff) { console.log(`[recover] killing hung surface job ${id}`); try { child.kill("SIGTERM"); } catch (_) {} }

  // 3. Retry failed jobs (bounded), after a short backoff to avoid thrashing.
  const backoff = new Date(Date.now() - RETRY_BACKOFF_MS).toISOString();
  d.prepare(
    "UPDATE universe_jobs SET status='queued', retries=retries+1, error=NULL, started_at=NULL " +
    "WHERE status='failed' AND retries < ? AND (finished_at IS NULL OR finished_at < ?)"
  ).run(MAX_RETRIES, backoff);
  d.prepare(
    "UPDATE surface_jobs SET status='queued', retries=retries+1, error=NULL, started_at=NULL " +
    "WHERE status='failed' AND retries < ? AND (finished_at IS NULL OR finished_at < ?)"
  ).run(MAX_RETRIES, backoff);
}

// One shared pool: fill up to `maxWorkers` threads, each taking whichever job is
// next-eligible (respecting the per-type caps). When both a universe and a
// surface job are eligible, the earlier-created one goes first.
async function processQueue() {
  const d = db.getDb();

  recoverJobs();

  // A permanently-failed ore-prep (retries exhausted) cascades failure to its
  // dependent cell jobs so they don't wait forever.
  d.prepare(
    "UPDATE surface_jobs SET status='failed', error='prerequisite ore pass failed', finished_at=? " +
    "WHERE status='queued' AND depends_on IN (SELECT id FROM surface_jobs WHERE status='failed' AND retries >= ?)"
  ).run(new Date().toISOString(), MAX_RETRIES);

  while (runningUniverse.size + runningSurface.size < maxWorkers) {
    const uni = runningUniverse.size < maxUniverse
      ? d.prepare(
          "SELECT * FROM universe_jobs WHERE status='queued' AND id NOT IN " +
          `(${[...runningUniverse, -1].join(",")}) ORDER BY seed_start LIMIT 1`
        ).get()
      : null;
    const surf = runningSurface.size < maxSurface
      ? d.prepare(
          "SELECT * FROM surface_jobs WHERE status='queued' AND id NOT IN " +
          `(${[...runningSurface, -1].join(",")}) ` +
          "AND (depends_on IS NULL OR depends_on IN (SELECT id FROM surface_jobs WHERE status='done')) " +
          "ORDER BY created_at LIMIT 1"
        ).get()
      : null;

    if (!uni && !surf) break;
    const pickUniverse = uni && (!surf || (uni.created_at || "") <= (surf.created_at || ""));
    if (pickUniverse) startUniverse(uni);
    else startSurface(surf);
  }
}

// ── Universe bucket run (one seedgen process per 100k bucket) ──────────

function runUniverseBucket(job) {
  return new Promise((resolve) => {
    let binPath;
    try {
      binPath = requireSeedgen();
    } catch (e) {
      db.updateUniverseJob(job.id, { status: "failed", error: e.message, finished_at: new Date().toISOString() });
      db.addJobLog("universe", job.id, e.message);
      return resolve();
    }

    const label = job.bucket || bucketLabel(job.seed_end, job.k2_enabled);
    const dir = bucketDir(label);
    fs.mkdirSync(dir, { recursive: true });
    const outFile = path.join(dir, "seeds.jsonl");

    const env = {
      ...process.env,
      START_SEED: String(job.seed_start),
      END_SEED: String(job.seed_end),
      SE_K2: job.k2_enabled ? "1" : "0",
      MIN_NAQ_DV: "20000",
      MIN_PROD_MODULES: "4",
      WORKER_ID: "0",
    };

    console.log(`[universe ${label}] seeds ${job.seed_start.toLocaleString()} → ${job.seed_end.toLocaleString()}`);
    db.addJobLog("universe", job.id, `Bucket ${label}: scanning ${BUCKET_SIZE.toLocaleString()} seeds`);

    const child = spawn(binPath, [], { env, stdio: ["ignore", "pipe", "pipe"] });
    universeChildren.set(job.id, child);
    const outStream = fs.createWriteStream(outFile);
    child.stdout.pipe(outStream);

    let passedSeeds = 0;
    let lastLogTime = Date.now();
    child.stderr.on("data", data => {
      const text = data.toString();
      for (const line of text.split("\n")) {
        const m = line.match(/passed\s+(\d+)/);
        if (m) passedSeeds = parseInt(m[1]);
        if (Date.now() - lastLogTime > 5000) {
          lastLogTime = Date.now();
          const sm = line.match(/seed\s+(\d+)\s+rate\s+(\d+)/);
          if (sm) db.addJobLog("universe", job.id,
            `Bucket ${label}: seed ${parseInt(sm[1]).toLocaleString()}, rate ${sm[2]}/s, passed ${passedSeeds}`);
        }
      }
    });

    child.on("close", async code => {
      universeChildren.delete(job.id);
      outStream.end();
      // Cancelled out from under us — leave the 'cancelled' status intact.
      if ((db.getUniverseJob(job.id) || {}).status === "cancelled") return resolve();
      if (code !== 0) {
        db.updateUniverseJob(job.id, { status: "failed", error: `seedgen exit ${code}`, finished_at: new Date().toISOString() });
        return resolve();
      }
      try {
        const { seeds, zones } = await importBucket(outFile, job.id, label);
        db.updateUniverseJob(job.id, {
          status: "done",
          passed_seeds: seeds,
          total_zones: zones,
          output_file: path.relative(PROJECT_ROOT, outFile),
          finished_at: new Date().toISOString(),
        });
        db.addJobLog("universe", job.id, `Bucket ${label} done: ${seeds} seeds passed, ${zones} zones`);
      } catch (e) {
        db.updateUniverseJob(job.id, { status: "failed", error: String(e).slice(0, 500), finished_at: new Date().toISOString() });
      }
      resolve();
    });

    child.on("error", err => {
      universeChildren.delete(job.id);
      if ((db.getUniverseJob(job.id) || {}).status === "cancelled") return resolve();
      db.updateUniverseJob(job.id, { status: "failed", error: `spawn: ${err.message}`, finished_at: new Date().toISOString() });
      resolve();
    });
  });
}

// Import a bucket's seeds.jsonl into the seeds + zones tables.
async function importBucket(filePath, jobId, label) {
  const rl = readline.createInterface({ input: fs.createReadStream(filePath) });
  const seedRows = [];
  const zoneRows = [];
  let zones = 0;

  for await (const line of rl) {
    if (!line.trim().startsWith("{")) continue;
    let data;
    try { data = JSON.parse(line); } catch (_) { continue; }
    if (!data.z) continue;
    let criteria = null;
    try { criteria = JSON.stringify(analyze.evaluateWorld(data)); } catch (_) {}
    seedRows.push({
      seed: data.s,
      job_id: jobId,
      bucket: label,
      loot: data.l || "",
      k2: !!data.k,
      zone_count: data.z.length,
      line,
      criteria,
    });
    for (const z of data.z) {
      zoneRows.push({
        job_id: jobId,
        seed: data.s,
        name: z.n,
        zone_type: z.t,
        radius: z.r || null,
        primary_resource: z.p || null,
        temperature: z.temperature || null,
        water: z.water || null,
        moisture: z.moisture || null,
        trees: z.trees || null,
        aux: z.aux || null,
        cliff: z.cliff || null,
        enemy: z.enemy || null,
        delta_v: z.dv || null,
        star_gravity_well: null,
        planet_gravity_well: null,
        resource_scores: z.rs || null,
        resource_yields: z.y || null,
        stellar_x: null,
        stellar_y: null,
      });
      zones++;
    }
  }

  db.insertSeeds(seedRows);
  const d = db.getDb();
  const stmt = d.prepare(`
    INSERT OR REPLACE INTO zones
      (job_id, seed, name, zone_type, radius, primary_resource,
       temperature, water, moisture, trees, aux, cliff, enemy,
       delta_v, star_gravity_well, planet_gravity_well,
       resource_scores, resource_yields, stellar_x, stellar_y)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const tx = d.transaction(() => {
    for (const z of zoneRows) {
      stmt.run(
        z.job_id, z.seed, z.name, z.zone_type, z.radius, z.primary_resource,
        z.temperature, z.water, z.moisture, z.trees, z.aux, z.cliff, z.enemy,
        z.delta_v, z.star_gravity_well, z.planet_gravity_well,
        z.resource_scores ? JSON.stringify(z.resource_scores) : null,
        z.resource_yields ? JSON.stringify(z.resource_yields) : null,
        z.stellar_x, z.stellar_y
      );
    }
  });
  tx();
  return { seeds: seedRows.length, zones };
}

// ── Second-layer seed filter (persisted subset of a bucket) ────────────

// Apply analyze criteria to a bucket's seeds, persist a named filter (DB rows +
// output/<bucket>/<name>.jsonl in universe format with zones trimmed to the
// criteria-relevant ones). Lives alongside seeds.jsonl in the same folder.
// `rules` is an analyze ruleset (see analyze.matchFilter); `loot` an optional
// loot-prefix constraint. Emits the world lines with zones trimmed to the ones
// the rules selected (so the surface generator only sees relevant zones).
function createFilteredSet(bucket, name, rules, loot) {
  const safeName = name.replace(/[^a-zA-Z0-9_-]/g, "_");
  const seeds = db.getSeeds({ bucket });
  const members = [];
  const lines = [];
  for (const s of seeds) {
    let c = null;
    try { c = JSON.parse(s.criteria); } catch (_) {}
    if (!c) continue;
    if (loot && !(s.loot || "").startsWith(loot)) continue;
    const m = analyze.matchFilter(c, rules);
    if (!m.match) continue;
    members.push(s.seed);
    try {
      const world = JSON.parse(s.line);
      const keep = new Set(m.zones.length ? m.zones : (c.selectedZones || []));
      lines.push(JSON.stringify({ ...world, z: (world.z || []).filter(z => keep.has(z.n)) }));
    } catch (_) {}
  }
  const dir = bucketDir(bucket);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, `${safeName}.jsonl`), lines.join("\n") + (lines.length ? "\n" : ""));

  const filterId = db.createSeedFilter({ bucket, name: safeName, rules, loot: loot || "", matched: members.length });
  db.setFilterMembers(filterId, members);
  return { filterId, matched: members.length, name: safeName };
}

// ── Seed drill-down: filtered world file ───────────────────────────────

// Write output/<bucket>/seed_<n>/zones.jsonl — the world line with z filtered
// to `zoneNames` (or all zones when null). This file feeds segen --zones and
// records "which zones exist" at this depth of the drill-down.
function writeSeedZonesFile(seedRow, zoneNames) {
  const dir = seedDir(seedRow.bucket, seedRow.seed);
  fs.mkdirSync(dir, { recursive: true });
  const world = JSON.parse(seedRow.line);
  const filtered = zoneNames
    ? { ...world, z: (world.z || []).filter(z => zoneNames.includes(z.n)) }
    : world;
  const file = path.join(dir, "zones.jsonl");
  fs.writeFileSync(file, JSON.stringify(filtered) + "\n");
  return file;
}

// ── Tiled surface planning + stitching ─────────────────────────────────

const STITCH = path.join(PROJECT_ROOT, "calibration", "mod-dump", "stitch_surface.py");

// Static cell edge (tiles). Grid is chosen so every cell is ~this size on ANY
// planet, so each surface job processes a near-constant tile count and finishes
// in roughly the same time (cellW = ceil(2r/N) ≈ SURFACE_CELL_TILES). Bump this
// to trade fewer/larger jobs for more/smaller ones.
const SURFACE_CELL_TILES = 1024;
// Safety cap on N (grid is N×N). Set well above the real radius range (max
// radius ~10000 → N=20) so it never bites in practice; guards pathological huge
// bodies from exploding into thousands of jobs.
const SURFACE_GRID_CAP = 32;

// Grid size for a zone: N×N cells of ~SURFACE_CELL_TILES, at least 1 (whole).
function surfaceGridFor(radius) {
  return Math.max(1, Math.min(SURFACE_GRID_CAP, Math.ceil((radius * 2) / SURFACE_CELL_TILES)));
}

// Cell indices (gx=i%n) of an n×n grid over [-r,r]² that intersect the disk of
// `radius`. Cells fully outside are skipped. Ordered center-outward (by each
// cell centre's distance from the origin) so the central landing area — where
// the player arrives — is generated first and the edges last.
function planSurfaceCells(radius, n) {
  if (n <= 1) return [0];
  const full = radius * 2;
  const cellW = Math.ceil(full / n);
  const cells = [];
  for (let i = 0; i < n * n; i++) {
    const gx = i % n, gy = Math.floor(i / n);
    const x0 = -radius + gx * cellW, x1 = Math.min(radius, x0 + cellW);
    const y0 = -radius + gy * cellW, y1 = Math.min(radius, y0 + cellW);
    if (x1 <= x0 || y1 <= y0) continue;
    const nx = Math.max(x0, Math.min(0, x1 - 1));
    const ny = Math.max(y0, Math.min(0, y1 - 1));
    if (nx * nx + ny * ny <= radius * radius) {
      const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
      cells.push({ i, d2: cx * cx + cy * cy });
    }
  }
  // Nearest-to-centre first; row-major (i) breaks ties for a stable order.
  cells.sort((a, b) => a.d2 - b.d2 || a.i - b.i);
  return cells.map(c => c.i);
}

// How many cells the group SHOULD have (used to detect group completion).
function expectedCells(n, radius) {
  return planSurfaceCells(radius, n).length;
}

// Per-cell placement (as % of the 2r canvas) for the live browser grid, in the
// SAME orientation as the stitched surface.png. Verified pixel-exact against the
// stitcher: place surface_<n>_<cell>.png at (leftPct, topPct) sized wPct×hPct.
function surfaceCellLayout(radius) {
  const n = surfaceGridFor(radius);
  const full = radius * 2;
  const cellW = Math.ceil(full / n);
  const cells = planSurfaceCells(radius, n).map(cell => {
    const gx = cell % n, gy = Math.floor(cell / n);
    const x0 = gx * cellW, y0 = gy * cellW;
    const cw = Math.min(full, x0 + cellW) - x0;
    const ch = Math.min(full, y0 + cellW) - y0;
    return {
      cell, gx, gy,
      leftPct: 100 * x0 / full,
      topPct: 100 * (full - y0 - ch) / full, // final vertical flip
      wPct: 100 * cw / full,
      hPct: 100 * ch / full,
    };
  });
  return { n, cells };
}

function stitchSurface(zoneDir, gridN, radius, prefix = "surface") {
  return new Promise((resolve) => {
    const child = spawn("python3", [STITCH, zoneDir, String(gridN), String(radius), prefix],
      { stdio: ["ignore", "ignore", "pipe"] });
    let err = "";
    child.stderr.on("data", d => err += d);
    child.on("close", code => {
      const png = path.join(zoneDir, prefix + ".png");
      if (code === 0 && fs.existsSync(png)) resolve(png);
      else { console.log("[job-manager] stitch failed:", err.slice(0, 200)); resolve(null); }
    });
    child.on("error", () => resolve(null));
  });
}

// Render kinds → segen layer flag + output filename prefix. 'ore' = compute-only
// (no render). 'surface' is the legacy combined layer.
const RENDER_KINDS = {
  surface: { layer: null, prefix: "surface" },
  terrain: { layer: "terrain", prefix: "terrain" },
  oremap: { layer: "ore", prefix: "oremap" },
};

// ── Surface generation via the segen zone driver ───────────────────────

function runSurfaceJob(job) {
  return new Promise((resolve) => {
    let binPath;
    try {
      binPath = requireSegen();
    } catch (e) {
      db.updateSurfaceJob(job.id, { status: "failed", error: e.message, finished_at: new Date().toISOString() });
      return resolve();
    }

    const seedRow = db.getSeed(job.seed);
    if (!seedRow) {
      db.updateSurfaceJob(job.id, { status: "failed", error: `seed ${job.seed} not in seeds table`, finished_at: new Date().toISOString() });
      return resolve();
    }
    const label = seedRow.bucket;
    const sDir = seedDir(label, job.seed);
    const zonesFile = path.join(sDir, "zones.jsonl");
    if (!fs.existsSync(zonesFile)) writeSeedZonesFile(seedRow, null);

    const rk = RENDER_KINDS[job.kind];         // undefined for the 'ore' compute job
    const isRender = !!rk;
    const prefix = rk ? rk.prefix : null;
    const isCell = isRender && job.grid_cell >= 0 && job.grid_n > 1;
    // 'ore' = amounts only (no image, fast even for huge planets). Render kinds
    // draw a layer (terrain biome+water, oremap ore-on-black, or combined).
    const args = [
      "--zones", zonesFile,
      "--world-seed", String(job.seed),
      "--zone", job.zone_name,
      "--out", bucketDir(label),
      "--ores-only",
    ];
    if (isRender) {
      if (isCell) args.push("--surface-grid", String(job.grid_n), "--surface-cell", String(job.grid_cell));
      else args.push("--render-surface");
      if (rk.layer) args.push("--surface-layer", rk.layer);
      // Render from the cached ore.jsonl (written by the zone's ore-prep job)
      // instead of recomputing zone-wide ore for every cell.
      if (job.load_ore) args.push("--load-ore");
    }

    console.log(`[surface ${job.id}] segen ${args.join(" ")}`);
    const child = spawn(binPath, args, { cwd: SURFACE_GEN_DIR, stdio: ["ignore", "pipe", "pipe"] });
    surfaceChildren.set(job.id, child);

    let stderr = "";
    child.stderr.on("data", d => stderr += d);
    child.stdout.on("data", () => {});

    child.on("close", async code => {
      surfaceChildren.delete(job.id);
      // Cancelled out from under us — don't overwrite the 'cancelled' status.
      if ((db.getSurfaceJob(job.id) || {}).status === "cancelled") return resolve();
      const zDir = path.join(sDir, job.zone_name);
      const fail = (msg) => {
        db.updateSurfaceJob(job.id, { status: "failed", error: String(msg).slice(0, 500), finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Failed: ${String(msg).slice(0, 200)}`);
        resolve();
      };
      if (code !== 0) return fail((stderr.slice(-500)) || `exit ${code}`);

      // Best-effort ore summary (present for ore/surface/oremap; absent for terrain).
      let summary = null, oreCount = 0;
      try {
        summary = fs.readFileSync(path.join(zDir, "summary.json"), "utf8");
        for (const r of Object.values(JSON.parse(summary).resources || {})) oreCount += r.tiles || 0;
      } catch (_) {}

      if (!isRender) {
        // ore-compute job: success = summary.json written
        if (!summary) return fail("ore pass produced no summary.json");
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} ore (${oreCount} tiles)`);
        return resolve();
      }

      // render job — success = the layer BMP was written
      const bmpFile = isCell
        ? path.join(zDir, `${prefix}_${job.grid_n}_${job.grid_cell}.bmp`)
        : path.join(zDir, `${prefix}.bmp`);
      if (!fs.existsSync(bmpFile)) return fail(`no ${prefix} output (${stderr.slice(-200)})`);

      let pngRel = null;
      if (isCell) {
        await cellToPng(bmpFile); // → prefix_N_i.png for the live grid
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, finished_at: new Date().toISOString() });
        const siblings = db.getSurfaceCells(job.seed, job.zone_name, job.grid_n, job.kind);
        const allDone = siblings.length >= expectedCells(job.grid_n, job.radius) &&
                        siblings.every(s => s.status === "done" || s.status === "failed");
        if (allDone) {
          const png = await stitchSurface(zDir, job.grid_n, job.radius, prefix);
          if (png) {
            pngRel = path.relative(OUTPUT_DIR, png);
            for (const s of siblings) db.updateSurfaceJob(s.id, { png_file: pngRel });
            db.addJobLog("surface", job.id, `Stitched ${job.zone_name} ${prefix} (grid ${job.grid_n})`);
          }
        }
      } else {
        const png = await convertBmpToPng(bmpFile); // whole → prefix.png
        if (png && png.endsWith(".png")) pngRel = path.relative(OUTPUT_DIR, png);
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, png_file: pngRel, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} ${prefix}`);
      }
      resolve();
    });

    child.on("error", err => {
      surfaceChildren.delete(job.id);
      if ((db.getSurfaceJob(job.id) || {}).status === "cancelled") return resolve();
      db.updateSurfaceJob(job.id, { status: "failed", error: `spawn: ${err.message}`, finished_at: new Date().toISOString() });
      resolve();
    });
  });
}

// ── PNG Conversion ─────────────────────────────────────────────────────

// segen writes a bespoke BMP (unpadded rows, BGR) that image libs reject;
// calibration/mod-dump/bmp2png.py is the matching stdlib decoder.
const BMP2PNG = path.join(PROJECT_ROOT, "calibration", "mod-dump", "bmp2png.py");

function convertBmpToPng(bmpPath) {
  return new Promise((resolve) => {
    const pngPath = bmpPath.replace(/\.bmp$/, ".png");
    const child = spawn("python3", [BMP2PNG, bmpPath, pngPath], { stdio: ["ignore", "ignore", "pipe"] });
    let err = "";
    child.stderr.on("data", d => err += d);
    child.on("close", code => {
      if (code === 0 && fs.existsSync(pngPath)) resolve(pngPath);
      else { console.log("[job-manager] bmp2png failed:", err.slice(0, 200)); resolve(bmpPath); }
    });
    child.on("error", () => resolve(bmpPath));
  });
}

// One tiled cell BMP → final-oriented PNG (flip + BGR→RGB) for the live grid.
const CELL_PNG = path.join(PROJECT_ROOT, "calibration", "mod-dump", "cell_png.py");
function cellToPng(bmpPath) {
  return new Promise((resolve) => {
    const pngPath = bmpPath.replace(/\.bmp$/, ".png");
    const child = spawn("python3", [CELL_PNG, bmpPath, pngPath], { stdio: ["ignore", "ignore", "pipe"] });
    let err = "";
    child.stderr.on("data", d => err += d);
    child.on("close", code => resolve(code === 0 && fs.existsSync(pngPath) ? pngPath : null));
    child.on("error", () => resolve(null));
  });
}

// ── Polling ────────────────────────────────────────────────────────────

let pollTimer = null;

function startPolling(intervalMs = 2000) {
  if (pollTimer) return;
  pollTimer = setInterval(processQueue, intervalMs);
  processQueue();
}

function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
}

module.exports = {
  processQueue,
  recoverJobs,
  startPolling,
  stopPolling,
  findSegenBinary,
  findSeedgenBinary,
  requireSegen,
  requireSeedgen,
  createUniverseBuckets,
  setWorkerLimits,
  workerStatus,
  cancelAllJobs,
  clearCancelledJobs,
  wipeSystem,
  createFilteredSet,
  writeSeedZonesFile,
  surfaceGridFor,
  planSurfaceCells,
  surfaceCellLayout,
  bucketLabel,
  bucketDir,
  seedDir,
  BUCKET_SIZE,
  OUTPUT_DIR,
};
