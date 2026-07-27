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
const OUTPUT_DIR = path.join(PROJECT_ROOT, "output");
if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

// Every universe job is exactly one fixed-size bucket.
const BUCKET_SIZE = 100_000;

// Bucket label from the job's upper bound: 100k, 200k, ..., 1M, 1.1M, ...
function bucketLabel(seedEnd) {
  if (seedEnd >= 1_000_000) {
    const m = seedEnd / 1_000_000;
    return `${Number.isInteger(m) ? m : m.toFixed(1)}M`;
  }
  return `${seedEnd / 1000}k`;
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
  const row = d.prepare("SELECT MAX(seed_end) AS m FROM universe_jobs").get();
  const base = row && row.m ? row.m : 0;
  const ids = [];
  for (let i = 0; i < units; i++) {
    const start = base + i * BUCKET_SIZE;
    const end = start + BUCKET_SIZE;
    const label = bucketLabel(end);
    const id = db.createUniverseJob(start, end, 1, k2Enabled);
    db.updateUniverseJob(id, { bucket: label });
    ids.push(id);
  }
  return ids;
}

// ── Job processing loop ───────────────────────────────────────────────

// Number of bucket jobs run concurrently (each is a single seedgen process).
let universeConcurrency = parseInt(process.env.UNIVERSE_CONCURRENCY || "4");
const runningUniverse = new Set();
// Surface CELL jobs run concurrently (each renders one tile of one zone); this
// is what parallelizes a large surface across cores/jobs.
let surfaceConcurrency = parseInt(process.env.SURFACE_CONCURRENCY || "4");
const runningSurface = new Set();

function setUniverseConcurrency(n) {
  universeConcurrency = Math.max(1, Math.min(16, n | 0));
}
function setSurfaceConcurrency(n) {
  surfaceConcurrency = Math.max(1, Math.min(16, n | 0));
}

async function processQueue() {
  const d = db.getDb();

  // universe buckets: keep up to `universeConcurrency` running
  while (runningUniverse.size < universeConcurrency) {
    const job = d.prepare(
      "SELECT * FROM universe_jobs WHERE status = 'queued' AND id NOT IN " +
      `(${[...runningUniverse, -1].join(",")}) ORDER BY seed_start LIMIT 1`
    ).get();
    if (!job) break;
    db.updateUniverseJob(job.id, { status: "running", started_at: new Date().toISOString() });
    runningUniverse.add(job.id);
    runUniverseBucket(job)
      .catch(e => {
        db.updateUniverseJob(job.id, { status: "failed", error: String(e).slice(0, 500), finished_at: new Date().toISOString() });
      })
      .finally(() => runningUniverse.delete(job.id));
  }

  // surface/ore jobs: up to surfaceConcurrency at once (tiled surface cells
  // parallelize this way; ore jobs are fast).
  while (runningSurface.size < surfaceConcurrency) {
    const sjob = d.prepare(
      "SELECT * FROM surface_jobs WHERE status = 'queued' AND id NOT IN " +
      `(${[...runningSurface, -1].join(",")}) ORDER BY created_at LIMIT 1`
    ).get();
    if (!sjob) break;
    db.updateSurfaceJob(sjob.id, { status: "running", started_at: new Date().toISOString() });
    runningSurface.add(sjob.id);
    runSurfaceJob(sjob)
      .catch(e => {
        db.updateSurfaceJob(sjob.id, { status: "failed", error: String(e).slice(0, 500), finished_at: new Date().toISOString() });
      })
      .finally(() => runningSurface.delete(sjob.id));
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

    const label = job.bucket || bucketLabel(job.seed_end);
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
      outStream.end();
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

// Grid size for a zone: cells of ~1024 tiles, at least 1 (whole) up to a cap.
function surfaceGridFor(radius) {
  return Math.max(1, Math.min(8, Math.ceil((radius * 2) / 1024)));
}

// Cell indices (row-major, gx=i%n) of an n×n grid over [-r,r]² that intersect
// the disk of `radius`. Cells fully outside are skipped (never queued).
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
    if (nx * nx + ny * ny <= radius * radius) cells.push(i);
  }
  return cells;
}

// How many cells the group SHOULD have (used to detect group completion).
function expectedCells(n, radius) {
  return planSurfaceCells(radius, n).length;
}

function stitchSurface(zoneDir, gridN, radius) {
  return new Promise((resolve) => {
    const child = spawn("python3", [STITCH, zoneDir, String(gridN), String(radius)],
      { stdio: ["ignore", "ignore", "pipe"] });
    let err = "";
    child.stderr.on("data", d => err += d);
    child.on("close", code => {
      const png = path.join(zoneDir, "surface.png");
      if (code === 0 && fs.existsSync(png)) resolve(png);
      else { console.log("[job-manager] stitch failed:", err.slice(0, 200)); resolve(null); }
    });
    child.on("error", () => resolve(null));
  });
}

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

    const isSurface = job.kind === "surface";
    const isCell = isSurface && job.grid_cell >= 0 && job.grid_n > 1;
    // ore jobs = amounts only (no image, fast even for huge planets); surface
    // jobs render the biome+water map (whole, or one grid cell for parallelism).
    const args = [
      "--zones", zonesFile,
      "--world-seed", String(job.seed),
      "--zone", job.zone_name,
      "--out", bucketDir(label),
      "--ores-only",
    ];
    if (isSurface) {
      if (isCell) args.push("--surface-grid", String(job.grid_n), "--surface-cell", String(job.grid_cell));
      else args.push("--render-surface");
    }

    console.log(`[surface ${job.id}] segen ${args.join(" ")}`);
    const child = spawn(binPath, args, { cwd: SURFACE_GEN_DIR, stdio: ["ignore", "pipe", "pipe"] });

    let stderr = "";
    child.stderr.on("data", d => stderr += d);
    child.stdout.on("data", () => {});

    child.on("close", async code => {
      const zDir = path.join(sDir, job.zone_name);
      const summaryFile = path.join(zDir, "summary.json");
      if (code !== 0 || !fs.existsSync(summaryFile)) {
        const errMsg = (stderr.slice(-500)) || `exit ${code}`;
        db.updateSurfaceJob(job.id, { status: "failed", error: errMsg, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Failed: ${errMsg.slice(0, 200)}`);
        return resolve();
      }
      let summary = null, oreCount = 0;
      try {
        summary = fs.readFileSync(summaryFile, "utf8");
        for (const r of Object.values(JSON.parse(summary).resources || {})) oreCount += r.tiles || 0;
      } catch (_) {}

      let pngRel = null;
      if (isCell) {
        // A cell finished. When ALL cells of this (seed,zone,grid) group are
        // done, stitch them into surface.png.
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, finished_at: new Date().toISOString() });
        const siblings = db.getSurfaceCells(job.seed, job.zone_name, job.grid_n);
        const allDone = siblings.length >= expectedCells(job.grid_n, job.radius) &&
                        siblings.every(s => s.status === "done" || s.status === "failed");
        if (allDone) {
          const png = await stitchSurface(zDir, job.grid_n, job.radius);
          if (png) {
            pngRel = path.relative(OUTPUT_DIR, png);
            // point every sibling's png at the stitched result
            for (const s of siblings) db.updateSurfaceJob(s.id, { png_file: pngRel });
            db.addJobLog("surface", job.id, `Stitched ${job.zone_name} surface (grid ${job.grid_n})`);
          }
        }
      } else {
        // whole-surface job (grid 1): convert surface.bmp
        if (isSurface) {
          const bmpFile = path.join(zDir, "surface.bmp");
          if (fs.existsSync(bmpFile)) {
            const png = await convertBmpToPng(bmpFile);
            if (png && png.endsWith(".png")) pngRel = path.relative(OUTPUT_DIR, png);
          }
        }
        db.updateSurfaceJob(job.id, { status: "done", ore_count: oreCount, bucket: label, summary, png_file: pngRel, finished_at: new Date().toISOString() });
        db.addJobLog("surface", job.id, `Done: ${job.zone_name} (${oreCount} ore tiles)`);
      }
      resolve();
    });

    child.on("error", err => {
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
  startPolling,
  stopPolling,
  findSegenBinary,
  findSeedgenBinary,
  requireSegen,
  requireSeedgen,
  createUniverseBuckets,
  setUniverseConcurrency,
  setSurfaceConcurrency,
  createFilteredSet,
  writeSeedZonesFile,
  surfaceGridFor,
  planSurfaceCells,
  bucketLabel,
  bucketDir,
  seedDir,
  BUCKET_SIZE,
  OUTPUT_DIR,
};
