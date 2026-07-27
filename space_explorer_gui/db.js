const Database = require("better-sqlite3");
const path = require("path");

const DB_PATH = process.env.SE_GUI_DB || path.join(__dirname, "data.sqlite");

let db;

function getDb() {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    initSchema();
  }
  return db;
}

function initSchema() {
  db.exec(`
    -- Universe generation jobs
    CREATE TABLE IF NOT EXISTS universe_jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seed_start INTEGER NOT NULL,
      seed_end INTEGER NOT NULL,
      workers INTEGER DEFAULT 1,
      k2_enabled INTEGER DEFAULT 0,
      status TEXT DEFAULT 'queued',  -- queued, running, done, failed
      error TEXT,
      total_zones INTEGER DEFAULT 0,
      passed_seeds INTEGER DEFAULT 0,
      output_file TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      started_at TEXT,
      finished_at TEXT
    );

    -- Zones (planets, moons, asteroid fields) from universe generation
    CREATE TABLE IF NOT EXISTS zones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      job_id INTEGER REFERENCES universe_jobs(id),
      seed INTEGER NOT NULL,
      name TEXT NOT NULL,
      zone_type TEXT NOT NULL,  -- planet, moon, asteroid-field, asteroid-belt
      radius REAL,
      primary_resource TEXT,
      temperature TEXT,
      water TEXT,
      moisture TEXT,
      trees TEXT,
      aux TEXT,
      cliff TEXT,
      enemy TEXT,
      delta_v REAL,
      star_gravity_well REAL,
      planet_gravity_well REAL,
      resource_scores TEXT,     -- JSON: {iron-ore: 0.5, copper-ore: 0.3, ...}
      resource_yields TEXT,     -- JSON: {iron-ore: "150M", copper-ore: "80M", ...}
      stellar_x REAL,
      stellar_y REAL,
      UNIQUE(seed, name)
    );

    -- Surface generation jobs
    CREATE TABLE IF NOT EXISTS surface_jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      zone_id INTEGER REFERENCES zones(id),
      seed INTEGER NOT NULL,
      zone_name TEXT NOT NULL,
      radius INTEGER NOT NULL,
      sample_step INTEGER DEFAULT 1,
      chunk_x INTEGER,          -- chunk coordinate (for chunked generation)
      chunk_y INTEGER,
      chunk_w INTEGER,
      status TEXT DEFAULT 'queued',  -- queued, running, done, failed
      error TEXT,
      ore_count INTEGER DEFAULT 0,
      png_file TEXT,            -- relative path to generated PNG
      png_width INTEGER,
      png_height INTEGER,
      created_at TEXT DEFAULT (datetime('now')),
      started_at TEXT,
      finished_at TEXT
    );

    -- Indexes
    CREATE INDEX IF NOT EXISTS idx_zones_job ON zones(job_id);
    CREATE INDEX IF NOT EXISTS idx_zones_type ON zones(zone_type);
    CREATE INDEX IF NOT EXISTS idx_zones_name ON zones(name);
    CREATE INDEX IF NOT EXISTS idx_surface_jobs_zone ON surface_jobs(zone_id);
    CREATE INDEX IF NOT EXISTS idx_surface_jobs_status ON surface_jobs(status);

    -- Jobs queue table for FIFO processing
    CREATE TABLE IF NOT EXISTS job_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      job_type TEXT NOT NULL,
      job_id INTEGER NOT NULL,
      message TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS seeds (
      seed INTEGER PRIMARY KEY,
      job_id INTEGER REFERENCES universe_jobs(id),
      bucket TEXT,               -- e.g. "100k" (job upper bound label = output dir)
      loot TEXT,
      k2 INTEGER DEFAULT 0,
      zone_count INTEGER DEFAULT 0,
      line TEXT,                 -- raw universe-format jsonl line for this world
      criteria TEXT,             -- cached analyze.evaluateWorld() result (JSON)
      created_at TEXT DEFAULT (datetime('now'))
    );

    -- A saved second-layer filter over a bucket's rough-passed seeds.
    -- The membership file lives at output/<bucket>/<name>.jsonl (universe
    -- format, zones trimmed to the criteria-relevant ones) alongside seeds.jsonl.
    CREATE TABLE IF NOT EXISTS seed_filters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bucket TEXT NOT NULL,
      name TEXT NOT NULL,        -- filter label (also the output file basename)
      min_specials INTEGER DEFAULT 0,
      min_pairs INTEGER DEFAULT 0,
      loot TEXT DEFAULT '',
      matched INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(bucket, name)
    );

    CREATE TABLE IF NOT EXISTS seed_filter_members (
      filter_id INTEGER REFERENCES seed_filters(id) ON DELETE CASCADE,
      seed INTEGER,
      PRIMARY KEY (filter_id, seed)
    );

    -- Reusable named filter definitions (rulesets). Presets are seeded on init.
    CREATE TABLE IF NOT EXISTS filter_defs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL,
      rules TEXT NOT NULL,       -- JSON array of rules (see analyze.matchFilter)
      builtin INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now'))
    );
  `);

  // additive migrations for pre-existing databases
  const migrations = [
    "ALTER TABLE universe_jobs ADD COLUMN bucket TEXT",
    "ALTER TABLE surface_jobs ADD COLUMN bucket TEXT",
    "ALTER TABLE surface_jobs ADD COLUMN summary TEXT",
    "ALTER TABLE surface_jobs ADD COLUMN kind TEXT DEFAULT 'ore'",  // 'ore' | 'surface'
    "ALTER TABLE surface_jobs ADD COLUMN grid_n INTEGER DEFAULT 1", // surface tiling: grid size
    "ALTER TABLE surface_jobs ADD COLUMN grid_cell INTEGER DEFAULT -1", // which cell (-1 = whole/ore)
    "ALTER TABLE surface_jobs ADD COLUMN depends_on INTEGER", // prerequisite job id (cell → its ore-prep)
    "ALTER TABLE surface_jobs ADD COLUMN load_ore INTEGER DEFAULT 0", // 1 = render from cached ore.jsonl
    "ALTER TABLE seed_filters ADD COLUMN rules TEXT", // JSON ruleset (replaces min_specials/min_pairs)
  ];
  for (const m of migrations) {
    try { db.exec(m); } catch (_) { /* column exists */ }
  }
  seedPresetFilters();
}

// Built-in filter presets that mirror the analyze script's modes, plus a few
// resource-tag examples. Idempotent (INSERT OR IGNORE by unique name).
function seedPresetFilters() {
  const presets = [
    { name: "core (6 specials)", rules: [{ kind: "specials", n: 6 }] },
    { name: "core (≥4 specials)", rules: [{ kind: "specials", n: 4 }] },
    { name: "all production pairs", rules: [{ kind: "pairs", n: 5 }] },
    { name: "vulcanite primary", rules: [{ kind: "primary", res: "se-vulcanite" }] },
    { name: "vitamelange primary", rules: [{ kind: "primary", res: "se-vitamelange" }] },
    { name: "vulcanite primary + iridium secondary",
      rules: [{ kind: "combo", res: "se-vulcanite", res2: "se-iridium-ore" }] },
  ];
  const stmt = db.prepare("INSERT OR IGNORE INTO filter_defs (name, rules, builtin) VALUES (?, ?, 1)");
  for (const p of presets) stmt.run(p.name, JSON.stringify(p.rules));
}

// ── Universe Jobs ──────────────────────────────────────────────────────

function createUniverseJob(seedStart, seedEnd, workers, k2Enabled = false) {
  const d = getDb();
  const stmt = d.prepare(
    "INSERT INTO universe_jobs (seed_start, seed_end, workers, k2_enabled) VALUES (?, ?, ?, ?)"
  );
  const info = stmt.run(seedStart, seedEnd, workers || 1, k2Enabled ? 1 : 0);
  return info.lastInsertRowid;
}

function getUniverseJobs() {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM universe_jobs ORDER BY created_at DESC LIMIT 50"
  ).all();
}

function getUniverseJob(id) {
  const d = getDb();
  return d.prepare("SELECT * FROM universe_jobs WHERE id = ?").get(id);
}

function updateUniverseJob(id, fields) {
  const d = getDb();
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(", ");
  const values = Object.values(fields);
  d.prepare(`UPDATE universe_jobs SET ${sets} WHERE id = ?`).run(...values, id);
}

// ── Zones ──────────────────────────────────────────────────────────────

function insertZone(zone) {
  const d = getDb();
  const stmt = d.prepare(`
    INSERT OR REPLACE INTO zones
      (job_id, seed, name, zone_type, radius, primary_resource,
       temperature, water, moisture, trees, aux, cliff, enemy,
       delta_v, star_gravity_well, planet_gravity_well,
       resource_scores, resource_yields, stellar_x, stellar_y)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    zone.job_id, zone.seed, zone.name, zone.zone_type, zone.radius,
    zone.primary_resource, zone.temperature, zone.water, zone.moisture,
    zone.trees, zone.aux, zone.cliff, zone.enemy, zone.delta_v,
    zone.star_gravity_well, zone.planet_gravity_well,
    zone.resource_scores ? JSON.stringify(zone.resource_scores) : null,
    zone.resource_yields ? JSON.stringify(zone.resource_yields) : null,
    zone.stellar_x, zone.stellar_y
  );
}

function getZones(filter = {}) {
  const d = getDb();
  let sql = "SELECT * FROM zones WHERE 1=1";
  const params = [];
  if (filter.zone_type && filter.zone_type.length > 0) {
    const placeholders = filter.zone_type.map(() => "?").join(",");
    sql += ` AND zone_type IN (${placeholders})`;
    params.push(...filter.zone_type);
  }
  if (filter.name) { sql += " AND name LIKE ?"; params.push(`%${filter.name}%`); }
  if (filter.seed) { sql += " AND seed = ?"; params.push(filter.seed); }
  if (filter.job_id) { sql += " AND job_id = ?"; params.push(filter.job_id); }
  if (filter.primary_resource) { sql += " AND primary_resource = ?"; params.push(filter.primary_resource); }

  // Sort — whitelist allowed columns to prevent injection
  const allowedSorts = {
    name: "name", type: "zone_type", radius: "radius",
    primary: "primary_resource", dv: "delta_v",
    temp: "temperature", water: "water", seed: "seed",
  };
  const sortCol = allowedSorts[filter.sort] || "name";
  const sortDir = filter.order === "DESC" ? "DESC" : "ASC";
  sql += ` ORDER BY ${sortCol} ${sortDir} NULLS LAST LIMIT 200`;
  return d.prepare(sql).all(...params);
}

function getZone(id) {
  const d = getDb();
  return d.prepare("SELECT * FROM zones WHERE id = ?").get(id);
}

function getZonesForSeed(seed) {
  const d = getDb();
  return d.prepare("SELECT * FROM zones WHERE seed = ? ORDER BY zone_type, name").all(seed);
}

function getDistinctSeeds() {
  const d = getDb();
  return d.prepare(
    "SELECT DISTINCT seed FROM zones ORDER BY seed"
  ).all().map(r => r.seed);
}

// ── Surface Jobs ───────────────────────────────────────────────────────

function createSurfaceJob(job) {
  const d = getDb();
  const stmt = d.prepare(`
    INSERT INTO surface_jobs
      (zone_id, seed, zone_name, radius, sample_step, chunk_x, chunk_y, chunk_w, kind, grid_n, grid_cell, depends_on, load_ore)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const info = stmt.run(
    job.zone_id, job.seed, job.zone_name, job.radius,
    job.sample_step || 1, job.chunk_x || null, job.chunk_y || null,
    job.chunk_w || null, job.kind || "ore",
    job.grid_n || 1, job.grid_cell === undefined ? -1 : job.grid_cell,
    job.depends_on || null, job.load_ore ? 1 : 0
  );
  return info.lastInsertRowid;
}

// Sibling cells of a tiled surface (same seed/zone/grid), to know when a group
// is complete and ready to stitch.
function getSurfaceCells(seed, zoneName, gridN) {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM surface_jobs WHERE seed = ? AND zone_name = ? AND kind = 'surface' AND grid_n = ?"
  ).all(seed, zoneName, gridN);
}

function getSurfaceJobs(limit = 30) {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM surface_jobs ORDER BY created_at DESC LIMIT ?"
  ).all(limit);
}

function getSurfaceJob(id) {
  const d = getDb();
  return d.prepare("SELECT * FROM surface_jobs WHERE id = ?").get(id);
}

function getSurfaceJobsForZone(zoneId) {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM surface_jobs WHERE zone_id = ? ORDER BY created_at DESC"
  ).all(zoneId);
}

function updateSurfaceJob(id, fields) {
  const d = getDb();
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(", ");
  const values = Object.values(fields);
  d.prepare(`UPDATE surface_jobs SET ${sets} WHERE id = ?`).run(...values, id);
}

// ── Seeds ──────────────────────────────────────────────────────────────

function insertSeeds(rows) {
  const d = getDb();
  const stmt = d.prepare(`
    INSERT OR REPLACE INTO seeds (seed, job_id, bucket, loot, k2, zone_count, line, criteria)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const tx = d.transaction(() => {
    for (const r of rows) {
      stmt.run(r.seed, r.job_id, r.bucket, r.loot, r.k2 ? 1 : 0, r.zone_count, r.line, r.criteria || null);
    }
  });
  tx();
}

function getSeeds(filter = {}) {
  const d = getDb();
  let sql = "SELECT * FROM seeds WHERE 1=1";
  const params = [];
  if (filter.bucket) { sql += " AND bucket = ?"; params.push(filter.bucket); }
  if (filter.job_id) { sql += " AND job_id = ?"; params.push(filter.job_id); }
  if (filter.loot) { sql += " AND loot LIKE ?"; params.push(`${filter.loot}%`); }
  sql += " ORDER BY seed LIMIT 2000";
  return d.prepare(sql).all(...params);
}

function getSeed(seed) {
  const d = getDb();
  return d.prepare("SELECT * FROM seeds WHERE seed = ?").get(seed);
}

// ── Seed Filters (second-layer, persisted) ─────────────────────────────

function createSeedFilter(f) {
  const d = getDb();
  const info = d.prepare(`
    INSERT OR REPLACE INTO seed_filters (bucket, name, rules, loot, matched)
    VALUES (?, ?, ?, ?, ?)
  `).run(f.bucket, f.name, f.rules ? JSON.stringify(f.rules) : null, f.loot || "", f.matched || 0);
  return info.lastInsertRowid;
}

// ── Filter definitions (reusable named rulesets) ───────────────────────

function getFilterDefs() {
  return getDb().prepare("SELECT * FROM filter_defs ORDER BY builtin DESC, name").all();
}
function getFilterDef(id) {
  return getDb().prepare("SELECT * FROM filter_defs WHERE id = ?").get(id);
}
function createFilterDef(name, rules) {
  const info = getDb().prepare(
    "INSERT OR REPLACE INTO filter_defs (name, rules, builtin) VALUES (?, ?, 0)"
  ).run(name, JSON.stringify(rules));
  return info.lastInsertRowid;
}
function deleteFilterDef(id) {
  getDb().prepare("DELETE FROM filter_defs WHERE id = ? AND builtin = 0").run(id);
}

function setFilterMembers(filterId, seeds) {
  const d = getDb();
  const del = d.prepare("DELETE FROM seed_filter_members WHERE filter_id = ?");
  const ins = d.prepare("INSERT OR IGNORE INTO seed_filter_members (filter_id, seed) VALUES (?, ?)");
  const tx = d.transaction(() => {
    del.run(filterId);
    for (const s of seeds) ins.run(filterId, s);
  });
  tx();
  d.prepare("UPDATE seed_filters SET matched = ? WHERE id = ?").run(seeds.length, filterId);
}

function getSeedFilters(bucket) {
  const d = getDb();
  if (bucket) return d.prepare("SELECT * FROM seed_filters WHERE bucket = ? ORDER BY created_at DESC").all(bucket);
  return d.prepare("SELECT * FROM seed_filters ORDER BY created_at DESC").all();
}

function getSeedFilter(id) {
  const d = getDb();
  return d.prepare("SELECT * FROM seed_filters WHERE id = ?").get(id);
}

function getFilterSeeds(filterId) {
  const d = getDb();
  return d.prepare(`
    SELECT s.* FROM seeds s
    JOIN seed_filter_members m ON m.seed = s.seed
    WHERE m.filter_id = ? ORDER BY s.seed
  `).all(filterId);
}

function deleteSeedFilter(id) {
  const d = getDb();
  d.prepare("DELETE FROM seed_filter_members WHERE filter_id = ?").run(id);
  d.prepare("DELETE FROM seed_filters WHERE id = ?").run(id);
}

function addJobLog(jobType, jobId, message) {
  const d = getDb();
  d.prepare("INSERT INTO job_log (job_type, job_id, message) VALUES (?, ?, ?)").run(jobType, jobId, message);
}

module.exports = {
  getDb,
  createUniverseJob,
  getUniverseJobs,
  getUniverseJob,
  updateUniverseJob,
  insertZone,
  getZones,
  getZone,
  getZonesForSeed,
  getDistinctSeeds,
  createSurfaceJob,
  getSurfaceJobs,
  getSurfaceJob,
  getSurfaceJobsForZone,
  updateSurfaceJob,
  addJobLog,
  insertSeeds,
  getSeeds,
  getSeed,
  getSurfaceCells,
  getFilterDefs,
  getFilterDef,
  createFilterDef,
  deleteFilterDef,
  createSeedFilter,
  setFilterMembers,
  getSeedFilters,
  getSeedFilter,
  getFilterSeeds,
  deleteSeedFilter,
};
