const { spawn } = require("child_process");
const path = require("path");
const fs = require("fs");
const readline = require("readline");
const db = require("./db");
const gcs = require("./gcs");  // upload final renders to the public GCS bucket
const analyze = require(path.join(__dirname, "..", "verifier", "analyze.js"));

// Push a finished whole-zone render to the public GCS bucket (best-effort — a
// failed upload must never fail the job). `pngRel` is OUTPUT_DIR-relative and
// points at the final <prefix>.png (not a cell tile).
function uploadFinalRender(seed, zoneName, prefix, pngRel) {
  if (!pngRel || !pngRel.endsWith(`${prefix}.png`)) return;
  gcs.uploadRender(path.join(OUTPUT_DIR, pngRel), seed, zoneName, `${prefix}.png`)
    .catch((e) => console.log(`[gcs ${prefix}] upload ${seed}/${zoneName}: ${e.message}`));
}

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
const BUCKET_SIZE = parseInt(process.env.UNIVERSE_BUCKET_SIZE || "100000");

// Bucket label from the job's upper bound: 100k, 200k, ..., 1M, 1.1M, ...
// K2-enabled buckets get a "-k2" suffix so they live in separate folders/jobs
// from the vanilla run of the same seed range (output/100k vs output/100k-k2).
function bucketLabel(seedEnd, k2) {
  // Label must be UNIQUE per BUCKET_SIZE boundary — it names the output dir and
  // the DB bucket column. The old "1.8M" (toFixed(1)) form only had 0.1M
  // resolution, so with 10k buckets every 10 consecutive buckets above 1M
  // collided on one label and overwrote each other's seeds.jsonl. Use "M" only
  // for whole millions, else "k" (seedEnd is always a multiple of BUCKET_SIZE).
  let base;
  if (seedEnd >= 1_000_000 && seedEnd % 1_000_000 === 0) {
    base = `${seedEnd / 1_000_000}M`;   // 2000000 -> "2M"
  } else if (seedEnd % 1000 === 0) {
    base = `${seedEnd / 1000}k`;        // 1810000 -> "1810k", 20000 -> "20k"
  } else {
    base = `${seedEnd}`;                // sub-1k bucket sizes: raw seed
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

// On Windows `zig build` emits segen.exe / gpu_*.exe, so the bare names below
// never matched on disk and every job failed with "binary not found".
//
// Deliberately NO bare-name fallback on Windows: an extension-less PE file can
// exist on disk yet cannot be launched at all — libuv's spawn appends .com/.exe
// to any command lacking an extension, so spawn() of such a path returns ENOENT
// while fs.existsSync() on it returns true. Accepting it would trade a clear
// "binary not found" for a baffling "spawn ENOENT" on a file you can see.
// A name that already carries an extension is left alone: libuv tries it
// literally.
const IS_WIN = process.platform === "win32";
const winExe = (name) => (IS_WIN && !path.extname(name) ? name + ".exe" : name);
const binCandidate = (dir, name) => path.join(dir, winExe(name));

function findSegenBinary() {
  if (segenPath && fs.existsSync(segenPath)) return segenPath;
  const candidates = [
    binCandidate(path.join(SURFACE_GEN_DIR, "zig-out", "bin"), "segen"),
    binCandidate(path.join(SURFACE_GEN_DIR, "zig-out"), "segen"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) { segenPath = c; return c; }
  }
  return null;
}

function findSeedgenBinary() {
  if (seedgenPath && fs.existsSync(seedgenPath)) return seedgenPath;
  const candidates = [
    // install.mjs emits exactly one name here: seedgen.exe on Windows, seedgen
    // elsewhere. The old seedgen.native / seedgen-macos candidates are gone --
    // they only ever matched hand-built Mach-O/ARM archives, and ranking them
    // above a fresh build meant a stale binary could silently win.
    binCandidate(UNIVERSE_GEN_DIR, "seedgen"),
    binCandidate(path.join(UNIVERSE_GEN_DIR, "zig-out", "bin"), "seedgen"),
    binCandidate(path.join(UNIVERSE_GEN_DIR, "zig-out"), "seedgen"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) { seedgenPath = c; return c; }
  }
  return null;
}

function requireSegen() {
  const bin = findSegenBinary();
  if (!bin) throw new Error(
    `segen binary not found (looked for ${binCandidate(path.join(SURFACE_GEN_DIR, "zig-out", "bin"), "segen")}). ` +
    "Build it first:\n  node install.mjs"
  );
  return bin;
}

const GPU_COMPUTE_DIR = path.join(PROJECT_ROOT, "gpu_compute");
// Resolve a gpu_compute binary by name (gpu_terrain / gpu_biome / gpu_ore),
// caching the resolved path. All share the same build + fetch-wgpu instructions.
const gpuBinPaths = {};
function requireGpuBin(name) {
  if (gpuBinPaths[name] && fs.existsSync(gpuBinPaths[name])) return gpuBinPaths[name];
  const cand = binCandidate(path.join(GPU_COMPUTE_DIR, "zig-out", "bin"), name);
  if (fs.existsSync(cand)) { gpuBinPaths[name] = cand; return cand; }
  throw new Error(
    `${name} binary not found (looked for ${cand}). Build it first:\n` +
    "  node install.mjs"
  );
}
const requireGpuTerrain = () => requireGpuBin("gpu_terrain"); // surface render
const requireGpuBiome = () => requireGpuBin("gpu_biome");     // shared classify mask

const requireGpuOre = () => requireGpuBin("gpu_ore");         // GPU ore placement

function requireSeedgen() {
  const bin = findSeedgenBinary();
  if (!bin) throw new Error(
    `seedgen binary not found (looked for ${binCandidate(UNIVERSE_GEN_DIR, "seedgen")}). ` +
    "Build it first:\n  node install.mjs"
  );
  return bin;
}

// ── Universe bucket creation ───────────────────────────────────────────

// Queue `units` bucket jobs of exactly BUCKET_SIZE seeds each, continuing
// after the highest already-queued/finished bucket. Returns the job ids.
function createUniverseBuckets(units, k2Enabled, startSeed, filter = {}) {
  const d = db.getDb();
  const k2 = k2Enabled ? 1 : 0;
  let base;
  if (startSeed != null && Number.isFinite(startSeed) && startSeed >= 0) {
    // Explicit start override (dev shortcut: jump straight to a seed range
    // known to contain valid seeds). Snap to a bucket boundary so labels/ranges
    // stay aligned with auto-continued buckets.
    base = Math.floor(startSeed / BUCKET_SIZE) * BUCKET_SIZE;
  } else {
    // Progress the seed range PER k2-mode: vanilla and K2 each cover 0→N
    // independently (so "0-10M vanilla" and "0-10M K2" can both exist). Cancelled
    // and failed buckets imported no seeds, so ignore them — their ranges are free
    // to reuse, and cancelling everything lets a fresh run restart at 0.
    const row = d.prepare(
      "SELECT MAX(seed_end) AS m FROM universe_jobs WHERE k2_enabled = ? AND status NOT IN ('cancelled','failed')"
    ).get(k2);
    base = row && row.m ? row.m : 0;
  }
  const ids = [];
  for (let i = 0; i < units; i++) {
    const start = base + i * BUCKET_SIZE;
    const end = start + BUCKET_SIZE;
    const label = bucketLabel(end, k2Enabled);
    const id = db.createUniverseJob(start, end, 1, k2Enabled, filter);
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
// Default to the number of physical cores on Linux (excluding hyperthreads),
// falling back to 8 when we can't determine it (e.g. non-Linux or no /sys).
function physicalCoreCount() {
  if (process.platform !== "linux") return 0;
  try {
    const cpuRoot = "/sys/devices/system/cpu";
    const cpuDirs = fs.readdirSync(cpuRoot).filter((n) => /^cpu\d+$/.test(n));
    const seen = new Set();
    for (const dir of cpuDirs) {
      try {
        const pkg = fs.readFileSync(path.join(cpuRoot, dir, "topology", "physical_package_id"), "utf8").trim();
        const core = fs.readFileSync(path.join(cpuRoot, dir, "topology", "core_id"), "utf8").trim();
        seen.add(`${pkg}:${core}`);
      } catch (_) {}
    }
    if (seen.size > 0) return seen.size;
  } catch (_) {}
  return 0;
}
const defaultWorkers = physicalCoreCount() || 8;
let maxWorkers = parseInt(process.env.WORKERS || String(defaultWorkers));
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
  // Table is job_log (singular) — as "job_logs" this silently hit the per-table
  // catch below on every wipe, so run logs were never actually cleared.
  const tables = ["surface_jobs", "zones", "seeds",
                  "seed_filter_members", "seed_filters", "job_log", "universe_jobs"];
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
      // Tail-filter cutoffs the bucket was queued with (0 = side off).
      NAQ_DV_LOW: String(job.naq_lo || 0),
      NAQ_DV_HIGH: String(job.naq_hi || 0),
      PLANETS_LOW: String(job.pl_lo || 0),
      PLANETS_HIGH: String(job.pl_hi || 0),
      // Percentages (0..100), not counts — see wp/ef in main.zig.
      WATER_PCT_LOW: String(job.wp_lo || 0),
      WATER_PCT_HIGH: String(job.wp_hi || 0),
      ENEMY_PCT_LOW: String(job.ef_lo || 0),
      ENEMY_PCT_HIGH: String(job.ef_hi || 0),
      MIN_PROD_MODULES: "0",
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
      npm: data.npm ?? null,
      npl: data.npl ?? null,
      naqdv: data.naqdv ?? null,
      fdv: data.fdv ?? null,
      ed: data.ed ?? null,
      wp: data.wp ?? null,
      ef: data.ef ?? null,
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

// ── Per-seed universe expansion ────────────────────────────────────────
// Bulk generation stores only the Calidus home system (size). Opening a seed's
// detail page kicks this off to fill in the rest of the universe — every star
// system's planets/moons + deep-space asteroid fields — via seedgen ALL_ZONES=1
// for that single seed, upserting the zones (UNIQUE(seed,name) → dedup).

// Upsert every zone of one parsed universe world line. Returns the zone count.
// ON CONFLICT DO UPDATE (not INSERT OR REPLACE) so an existing zone keeps its id
// — otherwise the reinsert would orphan surface_jobs.zone_id (FK) for zones whose
// surfaces have already been generated.
function upsertWorldZones(data, jobId) {
  const d = db.getDb();
  const stmt = d.prepare(`
    INSERT INTO zones
      (job_id, seed, name, zone_type, radius, primary_resource,
       temperature, water, moisture, trees, aux, cliff, enemy,
       delta_v, star_gravity_well, planet_gravity_well,
       resource_scores, resource_yields, stellar_x, stellar_y, in_calidus)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(seed, name) DO UPDATE SET
      zone_type=excluded.zone_type, radius=excluded.radius,
      primary_resource=excluded.primary_resource,
      temperature=excluded.temperature, water=excluded.water,
      moisture=excluded.moisture, trees=excluded.trees, aux=excluded.aux,
      cliff=excluded.cliff, enemy=excluded.enemy, delta_v=excluded.delta_v,
      resource_scores=excluded.resource_scores,
      resource_yields=excluded.resource_yields,
      -- COALESCE so a re-ingest from an older seedgen (no "c") cannot wipe a
      -- flag an ALL_ZONES expansion already established.
      in_calidus=COALESCE(excluded.in_calidus, zones.in_calidus)`);
  const tx = d.transaction(() => {
    for (const z of data.z) {
      stmt.run(
        jobId, data.s, z.n, z.t, z.r || null, z.p || null,
        z.temperature || null, z.water || null, z.moisture || null, z.trees || null,
        z.aux || null, z.cliff || null, z.enemy || null, z.dv || null, null, null,
        z.rs ? JSON.stringify(z.rs) : null, z.y ? JSON.stringify(z.y) : null, null, null,
        z.c == null ? null : (z.c ? 1 : 0),
      );
    }
  });
  tx();
  return data.z.length;
}

const expandInFlight = new Set();
function isExpanding(seed) { return expandInFlight.has(Number(seed)); }

// Fire-and-forget: generate + ingest the full universe for one already-known
// seed. No-op if unknown, already expanded, or currently expanding. Seedgen for
// a single seed is ~milliseconds; the filters are disabled (the seed already
// passed bulk generation — we just want all its zones).
function expandSeed(seed) {
  seed = Number(seed);
  if (expandInFlight.has(seed)) return;
  const row = db.getSeed(seed);
  if (!row || row.expanded) return;
  let bin;
  try { bin = requireSeedgen(); }
  catch (e) { console.log(`[expand ${seed}] ${e.message}`); return; }
  expandInFlight.add(seed);
  const env = {
    ...process.env,
    START_SEED: String(seed), END_SEED: String(seed + 1),
    SE_K2: row.k2 ? "1" : "0",
    ALL_ZONES: "1",
    MIN_NAQ_DV: "0", MIN_PROD_MODULES: "0", NAQ_SCAN: "0",
  };
  const child = spawn(bin, [], { env, stdio: ["ignore", "pipe", "pipe"] });
  let out = "", err = "";
  child.stdout.on("data", d => out += d);
  child.stderr.on("data", d => err += d);
  child.on("close", code => {
    expandInFlight.delete(seed);
    if (code !== 0) return void console.log(`[expand ${seed}] seedgen exit ${code}: ${err.slice(-200)}`);
    const line = out.split("\n").find(l => l.trim().startsWith("{"));
    if (!line) return void console.log(`[expand ${seed}] no output`);
    let data;
    try { data = JSON.parse(line); } catch (_) { return void console.log(`[expand ${seed}] bad JSON`); }
    if (!data.z) return;
    const n = upsertWorldZones(data, row.job_id);
    let criteria = null;
    try { criteria = JSON.stringify(analyze.evaluateWorld(data)); } catch (_) {}
    db.markSeedExpanded(seed, line, n, criteria, data.npm ?? null, data.naqdv ?? null, data.ed ?? null, data.npl ?? null, data.fdv ?? null);
    console.log(`[expand ${seed}] ingested ${n} zones (full universe)`);
  });
  child.on("error", e => { expandInFlight.delete(seed); console.log(`[expand ${seed}] spawn: ${e.message}`); });
}

// Generate + ingest ONE arbitrary seed on demand. expandSeed only fills in the
// zones of a seed the bulk pass already kept; this creates the seeds row itself,
// so ANY seed number can be pulled up and then searched in the seed list.
//
// Every tail cutoff is explicitly zeroed: the point is to inspect this exact
// seed, not to ask whether it would have survived the rough pass. Such seeds land
// in a synthetic "manual" bucket so they are never mistaken for the output of a
// completed bucket job.
function manualBucket(k2) { return k2 ? "manual-k2" : "manual"; }

function generateSeed(seed, k2 = false) {
  return new Promise((resolve, reject) => {
    seed = Number(seed);
    if (!Number.isInteger(seed) || seed < 0) {
      return reject(new Error("seed must be a non-negative whole number"));
    }
    // Already known: don't duplicate it, just make sure the full universe is in.
    const existing = db.getSeed(seed);
    if (existing) {
      if (!existing.expanded) expandSeed(seed);
      return resolve({ seed, existed: true, bucket: existing.bucket, zones: existing.zone_count });
    }
    let bin;
    try { bin = requireSeedgen(); } catch (e) { return reject(e); }
    const bucket = manualBucket(k2);
    const env = {
      ...process.env,
      START_SEED: String(seed), END_SEED: String(seed + 1),
      SE_K2: k2 ? "1" : "0",
      ALL_ZONES: "1",
      MIN_NAQ_DV: "0", MIN_PROD_MODULES: "0", NAQ_SCAN: "0", METRICS_SCAN: "0",
      NAQ_DV_LOW: "0", NAQ_DV_HIGH: "0", PLANETS_LOW: "0", PLANETS_HIGH: "0",
      WATER_PCT_LOW: "0", WATER_PCT_HIGH: "0",
      ENEMY_PCT_LOW: "0", ENEMY_PCT_HIGH: "0",
    };
    const child = spawn(bin, [], { env, stdio: ["ignore", "pipe", "pipe"] });
    let out = "", err = "";
    child.stdout.on("data", d => out += d);
    child.stderr.on("data", d => err += d);
    child.on("error", e => reject(new Error(`could not run seedgen: ${e.message}`)));
    child.on("close", code => {
      if (code !== 0) return reject(new Error(`seedgen exited ${code}: ${err.slice(-200)}`));
      const line = out.split("\n").find(l => l.trim().startsWith("{"));
      if (!line) return reject(new Error(`seedgen produced no universe for seed ${seed}`));
      let data;
      try { data = JSON.parse(line); } catch (_) { return reject(new Error("seedgen produced unreadable JSON")); }
      if (!data.z) return reject(new Error("seedgen produced a universe with no zones"));
      let criteria = null;
      try { criteria = JSON.stringify(analyze.evaluateWorld(data)); } catch (_) {}
      db.insertSeeds([{
        seed: data.s, job_id: null, bucket, loot: data.l || "", k2: !!data.k,
        zone_count: data.z.length, line, criteria,
        npm: data.npm ?? null, npl: data.npl ?? null, naqdv: data.naqdv ?? null,
        fdv: data.fdv ?? null, ed: data.ed ?? null, wp: data.wp ?? null, ef: data.ef ?? null,
      }]);
      const n = upsertWorldZones(data, null);
      db.markSeedExpanded(seed, line, n, criteria, data.npm ?? null, data.naqdv ?? null,
        data.ed ?? null, data.npl ?? null, data.fdv ?? null);
      console.log(`[generate ${seed}] ingested ${n} zones into ${bucket}`);
      resolve({ seed, existed: false, bucket, zones: n });
    });
  });
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

// ── Tiled surface planning ─────────────────────────────────────────────
// Cells are composed in the browser (CSS grid) — no server-side stitching.

// Static cell edge (tiles). Grid is chosen so every cell is ~this size on ANY
// planet, so each surface job processes a near-constant tile count and finishes
// in roughly the same time (cellW = ceil(2r/N) ≈ SURFACE_CELL_TILES).
//
// The terrain render costs ~9.6 µs/tile (measured: a 951² cell = 8.5 s, and it
// scales cleanly with cell AREA), so a ~320-tile cell ≈ 320² × 9.6 µs ≈ 1 s.
// That is the target: one render job ≈ 1 second. Bump this to trade fewer/larger
// (slower) jobs for more/smaller (faster) ones.
const SURFACE_CELL_TILES = 320;
// Safety cap on N (grid is N×N). Sized so the largest bodies (radius ~10000 →
// 2r/320 ≈ 63) still get ~320-tile, ~1 s cells rather than being forced into
// bigger, slower ones; guards pathological huge bodies from exploding further.
const SURFACE_GRID_CAP = 64;

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

// Per-cell placement (as % of the 2r canvas) for the browser CSS grid, in the
// orientation segen writes cells (north-up: row 0 = north edge, cell gy=0 at the
// top). Place surface_<n>_<cell>.png at (leftPct, topPct) sized wPct×hPct.
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
      topPct: 100 * y0 / full,
      wPct: 100 * cw / full,
      hPct: 100 * ch / full,
    };
  });
  return { n, cells };
}

// Stitch a layer's per-cell PNGs into one full 2r×2r image, then delete the
// cells. Cells are north-up (row 0 = north edge, tile y0), so each cell composites
// at pixel (gx*cellW, gy*cellW) with no flip. Terrain gets an opaque grey (20)
// background (matching the in-disk fill); the ore layer stays transparent so it
// overlays terrain. Returns true once the full image was written (all expected
// cells present), false if any cell is still missing. An in-flight guard makes
// concurrent cell completions safe — only the first to see all cells stitches.
const stitchInFlight = new Set();
async function stitchSurfaceCells(zDir, prefix, radius, n) {
  if (n <= 1) return false; // whole render already writes <prefix>.png
  const key = `${zDir}::${prefix}`;
  if (stitchInFlight.has(key)) return false;
  const idx = planSurfaceCells(radius, n);
  for (const cell of idx) {
    if (!fs.existsSync(path.join(zDir, `${prefix}_${n}_${cell}.png`))) return false; // not all cells rendered yet
  }
  stitchInFlight.add(key);
  try {
    // gpu_stitch composes the cells into <prefix>.png with an ATOMIC write (temp
    // file + rename), so the GUI never sees a half-written image — it keeps
    // showing the live cell grid until the finished file appears, then swaps in
    // one step. Cells are removed only after the stitched image exists.
    const bin = requireGpuBin("gpu_stitch");
    await new Promise((resolve, reject) => {
      const ch = spawn(bin, ["--dir", zDir, "--prefix", prefix, "--grid", String(n), "--radius", String(radius)], { stdio: ["ignore", "ignore", "pipe"] });
      let e = "";
      ch.stderr.on("data", d => e += d);
      ch.on("close", code => code === 0 ? resolve() : reject(new Error(`gpu_stitch exit ${code}: ${e.slice(-200)}`)));
      ch.on("error", reject);
    });
    for (const cell of idx) { try { fs.unlinkSync(path.join(zDir, `${prefix}_${n}_${cell}.png`)); } catch (_) {} }
    return true;
  } finally {
    stitchInFlight.delete(key);
  }
}

// Reconcile the DB against the output/ folder for one zone: drop 'done' surface
// jobs whose artifact no longer exists on disk (e.g. the user deleted the zone
// folder to force a regenerate). The filesystem is the source of truth for "is
// this surface populated"; the DB rows are just an index over it. Skipped while
// any job for the zone is still queued/running (mid-generation), so a not-yet-
// stitched layer is never mistaken for a deleted one. Returns rows removed.
function reconcileZoneSurfaces(zoneId, zDir) {
  const rows = db.getSurfaceJobsForZone(zoneId);
  if (!rows.length) return 0;
  if (rows.some(r => r.status === "queued" || r.status === "running")) return 0;
  const has = (f) => fs.existsSync(path.join(zDir, f));
  // Artifact each 'done' kind leaves behind: ore → summary.json; oremap /
  // gpuoremap / oredump → oremap.png; terrain/gputerrain/surface → terrain.png
  // (or the legacy surface.png).
  const present = (kind) =>
    kind === "ore" ? has("summary.json")
      : (kind === "oremap" || kind === "gpuoremap" || kind === "oredump") ? has("oremap.png")
        : (has("terrain.png") || has("surface.png"));
  const stale = rows.filter(r => r.status === "done" && !present(r.kind)).map(r => r.id);
  return db.deleteSurfaceJobs(stale);
}

// Sweep every zone with a completed generation (used once on startup so folder
// deletions made while the server was down are recognised without visiting each
// seed). Per-seed reconcile on the seed page keeps in-session deletions live.
function reconcileAllSurfaces() {
  let pruned = 0;
  for (const z of db.getDistinctSurfaceZones()) {
    if (!z.bucket) continue;
    pruned += reconcileZoneSurfaces(z.zone_id, path.join(seedDir(z.bucket, z.seed), z.zone_name));
  }
  if (pruned) console.log(`[reconcile] pruned ${pruned} stale surface job row(s) (output folder gone)`);
  return pruned;
}

// Render kinds → segen layer flag + output filename prefix. 'ore' = compute-only
// (no render). 'surface' is the legacy combined layer.
const RENDER_KINDS = {
  surface: { layer: null, prefix: "surface" },
  terrain: { layer: "terrain", prefix: "terrain" },
  oremap: { layer: "ore", prefix: "oremap" },
  // GPU whole-zone terrain preview (gpu_terrain, ~80x faster). Writes terrain.png
  // directly, so buildSurfaceGrid shows it as the full terrain layer.
  gputerrain: { layer: "terrain", prefix: "terrain", gpu: true },
  // GPU ore map (gpu_ore) — asteroid fields only. Depends on an 'oredump' job
  // (segen --gpu-ore-dump does the CPU spot-gen); gpu_ore then tiles + writes
  // oremap_<n>_<cell>.png on the GPU. Bit-exact vs the CPU oracle for fields.
  gpuoremap: { layer: "ore", prefix: "oremap", gpu: true, gpuOre: true },
  // Shared biome/asteroid classify (gpu_biome). Writes biome_<n>_<cell>.bin
  // (u32/tile) — no image. Consumed by both the terrain (gpu_terrain --mask) and
  // ore (gpu_ore --mask) passes so the classifier runs once per surface.
  classify: { layer: null, prefix: "biome", gpu: true, classify: true },
};

// The shared classify mask filename for one cell (matches surface_gpu.zig::maskPath).
function maskCellName(n, cell) {
  return n <= 1 ? "biome.bin" : `biome_${n}_${cell}.bin`;
}

// True when every classify-mask cell for the current grid is on disk — i.e. a
// prior classify (or the sibling layer) already produced the shared mask.
function maskCellsPresent(zDir, radius) {
  const n = surfaceGridFor(radius);
  const cells = n <= 1 ? [-1] : planSurfaceCells(radius, n);
  return cells.every(c => fs.existsSync(path.join(zDir, maskCellName(n, c))));
}

// ── Surface generation via the segen zone driver ───────────────────────

function runSurfaceJob(job) {
  return new Promise((resolve) => {
    const rk = RENDER_KINDS[job.kind];         // undefined for the 'ore' compute job
    const useGpu = !!(rk && rk.gpu);
    let binPath;
    try {
      binPath = (rk && rk.gpuOre) ? requireGpuOre()
        : (rk && rk.classify) ? requireGpuBiome()
        : useGpu ? requireGpuTerrain()
        : requireSegen();
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

    const isRender = !!rk;
    const prefix = rk ? rk.prefix : null;
    const isCell = isRender && !useGpu && job.grid_cell >= 0 && job.grid_n > 1;

    // Keep per-cell progress visible during (re)generation: drop any stitched
    // whole-disk <prefix>.png from a prior run up front, so buildSurfaceGrid
    // shows the live cell grid while cells render and only swaps to the single
    // image once THIS render's cells are stitched at the very end (no flashing
    // between an old whole image and the new cells).
    if (isRender) { try { fs.unlinkSync(path.join(sDir, job.zone_name, `${prefix}.png`)); } catch (_) {} }

    // The CPU spot-gen dump handed from an 'oredump' job to gpu_ore.
    const dumpPath = path.join(sDir, job.zone_name, "gpu_ore_input.bin");

    let args;
    if (rk && rk.gpuOre) {
      // gpu_ore: read the CPU spot-gen dump and render oremap cells on the GPU,
      // tiled like gpu_terrain. --grid must match the GUI's cell layout; the render
      // extent (radius) is baked into the dump by segen --gpu-ore-dump --radius.
      args = ["--dump", dumpPath, "--zones", zonesFile, "--out", bucketDir(label), "--world-seed", String(job.seed), "--zone", job.zone_name, "--grid", String(surfaceGridFor(job.radius))];
      // Reuse the shared classify mask (biome/water/asteroid gate) if a classify
      // job already wrote it — skips gpu_ore's own per-cell classifier pass.
      if (maskCellsPresent(path.join(sDir, job.zone_name), job.radius)) args.push("--mask");
    } else if (job.kind === "oredump") {
      // Serialize per-resource params + precomputed spots for gpu_ore (CPU
      // spot-gen). --radius caps the extent exactly like the CPU render; --out
      // makes segen create the zone dir the dump is written into.
      args = ["--zones", zonesFile, "--world-seed", String(job.seed), "--zone", job.zone_name, "--out", bucketDir(label), "--radius", String(job.radius), "--gpu-ore-dump", dumpPath];
    } else if (useGpu) {
      // gpu_terrain (or gpu_biome for the classify job) processes the zone on the
      // GPU. job.radius is already capped to the max-radius setting; pass it so
      // the inner disk is used (required for asteroid fields, which carry no
      // radius, and caps big planets/moons).
      // Tile the disk like the CPU path: gpu_terrain renders each cell in ONE
      // process (context/pipeline/generators built once) and writes
      // terrain_<n>_<cell>.png center-outward, so the GUI fills cells in as they
      // land. n<=1 (small zones) → a single whole-disk terrain.png.
      const gpuN = surfaceGridFor(job.radius);
      args = ["--zones", zonesFile, "--world-seed", String(job.seed), "--zone", job.zone_name, "--out", bucketDir(label), "--radius", String(job.radius), "--surface-grid", String(gpuN)];
      if (rk.classify) args.push("--classify-only");
      // Colour the shared classify mask instead of re-running render.wgsl, when a
      // classify job already produced it. Falls back to inline classify otherwise.
      else if (maskCellsPresent(path.join(sDir, job.zone_name), job.radius)) args.push("--mask");
    } else {
      // CPU segen. --radius is REQUIRED: it caps the render/ore rect to the same
      // extent the GUI's cell grid (surfaceCellLayout/planSurfaceCells) is laid
      // out for. Without it, segen falls back to the zone's true radius (5000 for
      // asteroid fields, which carry none), so tiled cells come out at the wrong
      // scale (e.g. 770px cells stuffed into 308px slots → scrambled) and the ore
      // compute needlessly covers ~6x the area. fm still uses the true radius.
      args = ["--zones", zonesFile, "--world-seed", String(job.seed), "--zone", job.zone_name, "--out", bucketDir(label), "--radius", String(job.radius), "--ores-only"];
      if (isRender) {
        if (isCell) args.push("--surface-grid", String(job.grid_n), "--surface-cell", String(job.grid_cell));
        else args.push("--render-surface");
        if (rk.layer) args.push("--surface-layer", rk.layer);
        // Render from the cached ore.jsonl (written by the zone's ore-prep job)
        // instead of recomputing zone-wide ore for every cell.
        if (job.load_ore) args.push("--load-ore");
      }
    }

    console.log(`[surface ${job.id}] ${path.basename(binPath)} ${args.join(" ")}`);
    const child = spawn(binPath, args, { cwd: useGpu ? GPU_COMPUTE_DIR : SURFACE_GEN_DIR, stdio: ["ignore", "pipe", "pipe"] });
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

      if (job.kind === "oredump") {
        // GPU ore prep: success = the spot-gen dump exists (no summary here;
        // gpu_ore writes summary.json when it renders).
        if (!fs.existsSync(dumpPath)) return fail("gpu-ore-dump produced no output");
        db.updateSurfaceJob(job.id, { status: "done", bucket: label, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} gpu-ore-dump`);
        return resolve();
      }

      if (rk && rk.classify) {
        // Shared classify prep: success = the mask cells exist (no PNG/summary).
        if (!maskCellsPresent(zDir, job.radius)) return fail(`classify wrote no mask (${stderr.slice(-200)})`);
        db.updateSurfaceJob(job.id, { status: "done", bucket: label, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} classify mask`);
        return resolve();
      }

      if (!isRender) {
        // ore-compute job: success = summary.json written
        if (!summary) return fail("ore pass produced no summary.json");
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} ore (${oreCount} tiles)`);
        return resolve();
      }

      // render job — success = the layer PNG was written. segen emits per-cell
      // PNGs (zigimg); once every cell of a layer lands we stitch them into a
      // single north-up <prefix>.png and delete the cells (one terrain.png +
      // one oremap.png per zone). A GPU render is one process that tiles
      // internally (grid = surfaceGridFor): for grid>1 it writes all cells, so
      // success = every disk-intersecting cell landed, then stitch. grid<=1 →
      // whole render already writes <prefix>.png directly.
      if (useGpu) {
        const gpuN = surfaceGridFor(job.radius);
        if (gpuN > 1) {
          const expected = planSurfaceCells(job.radius, gpuN).length;
          const got = fs.readdirSync(zDir).filter(f => f.startsWith(`${prefix}_${gpuN}_`) && f.endsWith(".png")).length;
          if (got < expected) return fail(`gpu ${prefix}: ${got}/${expected} cells (${stderr.slice(-200)})`);
          const stitched = await stitchSurfaceCells(zDir, prefix, job.radius, gpuN).catch(e => { console.log(`[stitch ${prefix}] ${e.message}`); return false; });
          const pngRel = stitched ? path.relative(OUTPUT_DIR, path.join(zDir, `${prefix}.png`)) : null;
          db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, png_file: pngRel, finished_at: new Date().toISOString() });
          db.addJobLog("surface", job.id, `Done: ${job.zone_name} ${prefix} (gpu ${got} cells${stitched ? ", stitched" : ""})`);
          uploadFinalRender(job.seed, job.zone_name, prefix, pngRel);
          return resolve();
        }
      }

      const stitchedFile = path.join(zDir, `${prefix}.png`);
      const pngFile = isCell
        ? path.join(zDir, `${prefix}_${job.grid_n}_${job.grid_cell}.png`)
        : stitchedFile;
      // A sibling cell that finished first may have already stitched + deleted
      // this cell — that's still success (the layer image exists).
      if (!fs.existsSync(pngFile)) {
        if (isCell && fs.existsSync(stitchedFile)) {
          db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, png_file: path.relative(OUTPUT_DIR, stitchedFile), finished_at: new Date().toISOString() });
          db.addJobLog("surface", job.id, `Done: ${job.zone_name} ${prefix} cell ${job.grid_cell} (stitched by sibling)`);
          uploadFinalRender(job.seed, job.zone_name, prefix, path.relative(OUTPUT_DIR, stitchedFile));
          return resolve();
        }
        return fail(`no ${prefix} output (${stderr.slice(-200)})`);
      }

      // Tiled CPU render: this cell landed. If it was the last of its layer,
      // stitch all cells into a single <prefix>.png and drop the cells.
      let pngRel = isCell ? null : path.relative(OUTPUT_DIR, pngFile);
      if (isCell) {
        const stitched = await stitchSurfaceCells(zDir, prefix, job.radius, job.grid_n).catch(e => { console.log(`[stitch ${prefix}] ${e.message}`); return false; });
        if (stitched) pngRel = path.relative(OUTPUT_DIR, stitchedFile);
      }
      db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, png_file: pngRel, finished_at: new Date().toISOString() });
      db.addJobLog("surface", job.id, `Done: ${job.zone_name} ${prefix}${isCell ? ` cell ${job.grid_cell}` : ""}`);
      uploadFinalRender(job.seed, job.zone_name, prefix, pngRel); // stitched whole render only (no-op for cells)
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

// (bmp2png.py / cell_png.py removed — segen emits PNG directly via zigimg.)

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
  expandSeed,
  isExpanding,
  generateSeed,
  writeSeedZonesFile,
  surfaceGridFor,
  planSurfaceCells,
  surfaceCellLayout,
  maskCellsPresent,
  stitchSurfaceCells,
  reconcileZoneSurfaces,
  reconcileAllSurfaces,
  bucketLabel,
  bucketDir,
  seedDir,
  BUCKET_SIZE,
  OUTPUT_DIR,
};
