const Database = require("better-sqlite3");
const path = require("path");
const { seedScore } = require("./score");

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
      bucket TEXT,               -- e.g. "0x001" (hex-prefix label = output dir)
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

    -- Simple key/value settings (e.g. persisted worker limits).
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
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
    "ALTER TABLE universe_jobs ADD COLUMN retries INTEGER DEFAULT 0", // auto-retry counter
    "ALTER TABLE surface_jobs ADD COLUMN retries INTEGER DEFAULT 0",
    // 0 = only the Calidus system stored (bulk gen); 1 = full universe expanded
    // (all star systems + fields) via the seed-detail background job.
    "ALTER TABLE seeds ADD COLUMN expanded INTEGER DEFAULT 0",
    // Per-seed extremity metrics from seedgen (Calidus planets+moons; Δv to the
    // nearest naquium-primary field) — for best/worst sort + range filtering.
    "ALTER TABLE seeds ADD COLUMN npm INTEGER", // Calidus planets + moons (was `np`)
    "ALTER TABLE seeds ADD COLUMN npl INTEGER", // Calidus planets only (incl Nauvis)
    "ALTER TABLE seeds ADD COLUMN naqdv INTEGER",
    "ALTER TABLE seeds ADD COLUMN fdv INTEGER", // Δv to nearest ANY asteroid field
    // Proportional enemy danger: mean enemy level over Calidus planets+moons, 0..100%.
    "ALTER TABLE seeds ADD COLUMN ed INTEGER",
    // Share of Calidus planets+moons (excl. Nauvis) that have water / are
    // hostile, 0..100%. Normalised on purpose: the raw counts track system size
    // almost perfectly (corr(np, hostile count) = 0.94 over 50k seeds), so they
    // would just restate the planet-count tails instead of measuring character.
    //
    // `wf` was the same statistic INVERTED (share with NO water) and is dead:
    // "higher = drier" read backwards everywhere it was shown. `wp` replaces it
    // rather than redefining it, so rows ingested under the old meaning are not
    // silently reinterpreted. wf can be dropped once no old rows remain.
    "ALTER TABLE seeds ADD COLUMN wf INTEGER",
    "ALTER TABLE seeds ADD COLUMN wp INTEGER",
    "ALTER TABLE seeds ADD COLUMN ef INTEGER",
    // 1 = Calidus home-system member, 0 = another star system, NULL = ingested
    // before seedgen emitted the flag. Nothing else on a zone identifies its
    // star (the stellar coords are not stored), so this is the only way to tell.
    // NULL must read as "show": legacy rows would otherwise all look foreign.
    "ALTER TABLE zones ADD COLUMN in_calidus INTEGER",
    // Tail-filter config the bucket was generated with (0 = side disabled).
    "ALTER TABLE universe_jobs ADD COLUMN naq_lo INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN naq_hi INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN pl_lo INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN pl_hi INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN wp_lo INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN wp_hi INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN ef_lo INTEGER DEFAULT 0",
    "ALTER TABLE universe_jobs ADD COLUMN ef_hi INTEGER DEFAULT 0",
    // Stored 0-100 desirability score (see score.js). Backfilled below. The
    // index must come AFTER the column exists, so both live here (the schema
    // block above runs before migrations, and would throw on the missing column).
    "ALTER TABLE seeds ADD COLUMN score INTEGER",
    "CREATE INDEX IF NOT EXISTS idx_seeds_score ON seeds(score)",
    // Seeds list: the only index used to be the seed PK, so every bucket view /
    // range filter / metric sort full-scanned the (multi-GB) table. Index the
    // columns getSeeds filters and orders by. (bucket,k2) covers the common
    // bucket view; the single-column ones serve the all-seeds metric sorts.
    // These MUST live here, not in the schema block: they index columns the
    // ALTERs above add (and on a fresh DB the schema block used to run them
    // before CREATE TABLE seeds existed at all — first install crashed with
    // "no such table: main.seeds").
    "CREATE INDEX IF NOT EXISTS idx_seeds_bucket_k2 ON seeds(bucket, k2)",
    "CREATE INDEX IF NOT EXISTS idx_seeds_naqdv ON seeds(naqdv)",
    "CREATE INDEX IF NOT EXISTS idx_seeds_fdv ON seeds(fdv)",
    "CREATE INDEX IF NOT EXISTS idx_seeds_npl ON seeds(npl)",
    "CREATE INDEX IF NOT EXISTS idx_seeds_ef ON seeds(ef)",
    "CREATE INDEX IF NOT EXISTS idx_seeds_wp ON seeds(wp)",
  ];
  for (const m of migrations) {
    try { db.exec(m); } catch (_) { /* column exists */ }
  }
  // Rename np (planets+moons) → npm, keeping npl (planets). Guarded so it runs
  // exactly once: only when the old `np` column is present and `npm` is not, so
  // re-runs (and fresh DBs, which already get npm) skip it and it can't clobber.
  {
    const cols = db.prepare("PRAGMA table_info(seeds)").all().map(c => c.name);
    if (cols.includes("np") && !cols.includes("npm")) {
      // Legacy DB: rename the data-carrying np column.
      db.exec("ALTER TABLE seeds RENAME COLUMN np TO npm");
      try { db.exec("DROP INDEX IF EXISTS idx_seeds_np"); } catch (_) {}
    } else if (cols.includes("np") && cols.includes("npm")) {
      // A stray empty np (re-added by the old ADD COLUMN np migration after a
      // prior rename) — the data is in npm; drop the leftover.
      try { db.exec("ALTER TABLE seeds DROP COLUMN np"); } catch (_) {}
    }
    try { db.exec("CREATE INDEX IF NOT EXISTS idx_seeds_npm ON seeds(npm)"); } catch (_) {}
  }
  seedPresetFilters();
}

// Two EDITABLE starter presets mirroring the analyze script's --core and
// --pairs modes. Seeded as builtin=0 so they can be tweaked/deleted (the pair
// definitions aren't set in stone). Old read-only (builtin=1) presets from
// earlier versions are removed. Idempotent: INSERT OR IGNORE keeps edits, and
// re-adds a starter only if it's missing.
function seedPresetFilters() {
  db.prepare("DELETE FROM filter_defs WHERE builtin = 1").run();
  // Canonical rule shape: { primary: bool, res: [...] } — a body has all of
  // `res` present, and if `primary` its PRIMARY is res[0] (core fragments).
  const presets = [
    {
      // the core-mineable specials, each required as a primary (distinct body),
      // plus the nearest naquium-primary asteroid field (sorted by deltav).
      name: "core",
      rules: [
        { primary: true, res: ["se-naquium-ore"] },
        { primary: true, res: ["se-vulcanite"] },
        { primary: true, res: ["se-cryonite"] },
        { primary: true, res: ["se-holmium-ore"] },
        { primary: true, res: ["se-beryllium-ore"] },
        { primary: true, res: ["se-iridium-ore"] },
        { primary: true, res: ["se-vitamelange"] },
      ],
    },
    {
      name: "pairs",
      rules: [
        { primary: true, res: ["se-naquium-ore"] },
        { primary: false, res: ["se-vulcanite", "se-iridium-ore"] },
        { primary: false, res: ["se-cryonite", "se-beryllium-ore"] },
        { primary: false, res: ["se-vitamelange", "stone"] },
        { primary: false, res: ["se-holmium-ore"] },
      ],
    },
  ];
  // rules JSON of PRIOR auto-seeded defaults — safe to upgrade to the current
  // shape (the user hasn't customised them). Edited/already-current starters
  // are left untouched, so edits survive restarts.
  const upgradable = new Set([
    JSON.stringify([{ kind: "specials", n: 6 }]),  // oldest "core"
    JSON.stringify([{ kind: "pairs", n: 5 }]),     // oldest "pairs"
    // prior kind-based "core" (6 primaries) and "pairs" (both/present)
    JSON.stringify([
      { kind: "primary", res: "se-vulcanite" }, { kind: "primary", res: "se-cryonite" },
      { kind: "primary", res: "se-holmium-ore" }, { kind: "primary", res: "se-beryllium-ore" },
      { kind: "primary", res: "se-iridium-ore" }, { kind: "primary", res: "se-vitamelange" },
    ]),
    JSON.stringify([
      { kind: "both", res: "se-vulcanite", res2: "se-iridium-ore" },
      { kind: "both", res: "se-cryonite", res2: "se-beryllium-ore" },
      { kind: "both", res: "se-vitamelange", res2: "stone" },
      { kind: "present", res: "se-holmium-ore" },
    ]),
    // prior canonical core/pairs (pre-naquium) — upgrade to add the naq-primary rule.
    JSON.stringify([
      { primary: true, res: ["se-vulcanite"] }, { primary: true, res: ["se-cryonite"] },
      { primary: true, res: ["se-holmium-ore"] }, { primary: true, res: ["se-beryllium-ore"] },
      { primary: true, res: ["se-iridium-ore"] }, { primary: true, res: ["se-vitamelange"] },
    ]),
    JSON.stringify([
      { primary: false, res: ["se-vulcanite", "se-iridium-ore"] },
      { primary: false, res: ["se-cryonite", "se-beryllium-ore"] },
      { primary: false, res: ["se-vitamelange", "stone"] },
      { primary: false, res: ["se-holmium-ore"] },
    ]),
  ]);
  const get = db.prepare("SELECT id, rules FROM filter_defs WHERE name = ?");
  const ins = db.prepare("INSERT INTO filter_defs (name, rules, builtin) VALUES (?, ?, 0)");
  const upd = db.prepare("UPDATE filter_defs SET rules = ? WHERE id = ?");
  for (const p of presets) {
    const rj = JSON.stringify(p.rules);
    const cur = get.get(p.name);
    if (!cur) ins.run(p.name, rj);
    else if (upgradable.has(cur.rules)) upd.run(rj, cur.id);
  }
}

// ── Universe Jobs ──────────────────────────────────────────────────────

function createUniverseJob(seedStart, seedEnd, workers, k2Enabled = false, filter = {}) {
  const d = getDb();
  const stmt = d.prepare(
    "INSERT INTO universe_jobs (seed_start, seed_end, workers, k2_enabled, naq_lo, naq_hi, pl_lo, pl_hi, wp_lo, wp_hi, ef_lo, ef_hi) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  );
  const info = stmt.run(seedStart, seedEnd, workers || 1, k2Enabled ? 1 : 0,
    filter.naq_lo || 0, filter.naq_hi || 0, filter.pl_lo || 0, filter.pl_hi || 0,
    filter.wp_lo || 0, filter.wp_hi || 0, filter.ef_lo || 0, filter.ef_hi || 0);
  return info.lastInsertRowid;
}

function getUniverseJobs() {
  const d = getDb();
  // Show every bucket (no LIMIT) so the universe table lists all of them.
  return d.prepare(
    "SELECT * FROM universe_jobs ORDER BY created_at DESC"
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
       resource_scores, resource_yields, stellar_x, stellar_y, in_calidus)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  return stmt.run(
    zone.job_id, zone.seed, zone.name, zone.zone_type, zone.radius,
    zone.primary_resource, zone.temperature, zone.water, zone.moisture,
    zone.trees, zone.aux, zone.cliff, zone.enemy, zone.delta_v,
    zone.star_gravity_well, zone.planet_gravity_well,
    zone.resource_scores ? JSON.stringify(zone.resource_scores) : null,
    zone.resource_yields ? JSON.stringify(zone.resource_yields) : null,
    zone.stellar_x, zone.stellar_y, zone.in_calidus ?? null
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
function getSurfaceCells(seed, zoneName, gridN, kind = "surface") {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM surface_jobs WHERE seed = ? AND zone_name = ? AND kind = ? AND grid_n = ?"
  ).all(seed, zoneName, kind, gridN);
}

function getSurfaceJobs(limit = 30) {
  const d = getDb();
  return d.prepare(
    "SELECT * FROM surface_jobs ORDER BY created_at DESC LIMIT ?"
  ).all(limit);
}

function getAllSurfaceJobs() {
  return getDb().prepare("SELECT * FROM surface_jobs ORDER BY created_at DESC").all();
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

function deleteSurfaceJobs(ids) {
  if (!ids || !ids.length) return 0;
  const d = getDb();
  const stmt = d.prepare("DELETE FROM surface_jobs WHERE id = ?");
  d.transaction(list => { for (const id of list) stmt.run(id); })(ids);
  return ids.length;
}

// One representative row per (zone, folder) that has a completed generation —
// used to reconcile the DB against the output/ folder on startup.
function getDistinctSurfaceZones() {
  return getDb().prepare(
    "SELECT zone_id, seed, zone_name, MAX(bucket) AS bucket FROM surface_jobs " +
    "WHERE status='done' AND zone_id IS NOT NULL GROUP BY zone_id, seed, zone_name"
  ).all();
}

// ── Seeds ──────────────────────────────────────────────────────────────

function insertSeeds(rows) {
  const d = getDb();
  const stmt = d.prepare(`
    INSERT OR REPLACE INTO seeds (seed, job_id, bucket, loot, k2, zone_count, line, criteria, npm, npl, naqdv, fdv, ed, wp, ef, score)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const tx = d.transaction(() => {
    for (const r of rows) {
      stmt.run(r.seed, r.job_id, r.bucket, r.loot, r.k2 ? 1 : 0, r.zone_count, r.line, r.criteria || null,
        r.npm ?? null, r.npl ?? null, r.naqdv ?? null, r.fdv ?? null, r.ed ?? null, r.wp ?? null, r.ef ?? null,
        seedScore(r) ?? null);
    }
  });
  tx();
}

function getSeeds(filter = {}) {
  const d = getDb();
  // Explicit column list — NEVER SELECT *: the `line` (~7KB world JSON) and
  // `criteria` columns are huge and the seeds list never renders them, so pulling
  // them for up to 2000 rows dominated the query time on the multi-GB table.
  // `criteria` (the cached analyze result) is only needed when a rule filter is
  // active; it's large-ish, so keep it out of the plain list for speed.
  const cols = "seed, job_id, bucket, loot, k2, zone_count, created_at, expanded, npm, npl, naqdv, fdv, ed, wf, ef, wp, score" +
    (filter.withCriteria ? ", criteria" : "");
  let sql = `SELECT ${cols} FROM seeds WHERE 1=1`;
  const params = [];
  if (filter.bucket) { sql += " AND bucket = ?"; params.push(filter.bucket); }
  if (filter.job_id) { sql += " AND job_id = ?"; params.push(filter.job_id); }
  if (filter.loot) { sql += " AND loot LIKE ?"; params.push(`${filter.loot}%`); }
  if (filter.k2 !== undefined && filter.k2 !== null && filter.k2 !== "") {
    sql += " AND k2 = ?"; params.push(filter.k2 ? 1 : 0);
  }
  // Extremity range filters (Calidus planets+moons; nearest-naq Δv).
  const range = (col, min, max) => {
    if (min != null && min !== "") { sql += ` AND ${col} >= ?`; params.push(Number(min)); }
    if (max != null && max !== "") { sql += ` AND ${col} <= ?`; params.push(Number(max)); }
  };
  range("npm", filter.npm_min, filter.npm_max);
  range("naqdv", filter.naqdv_min, filter.naqdv_max);
  range("fdv", filter.fdv_min, filter.fdv_max);
  // `ed` (mean enemy INTENSITY) is still computed and stored, but no longer
  // surfaced: `ef` — the share of bodies carrying enemies — is the metric the
  // enemy tails filter on, so showing both invited confusing them.
  range("wp", filter.wp_min, filter.wp_max);
  range("ef", filter.ef_min, filter.ef_max);
  // Seed-number search. Matched server-side, not by filtering the rendered rows:
  // the result set is capped at 2000 below, so a client-side box would silently
  // fail to find any seed outside that window.
  // Substring match, always — a full seed number is a substring of itself, so
  // typing it whole still finds exactly it, while a partial number narrows as
  // you type. (Branching to `seed = ?` for all-digit input looked like an index
  // win but made partial search unreachable: every realistic query IS digits.)
  if (filter.seed != null && String(filter.seed).trim() !== "") {
    const digits = String(filter.seed).replace(/[^\d]/g, "");
    if (digits !== "") { sql += " AND CAST(seed AS TEXT) LIKE ?"; params.push(`%${digits}%`); }
  }
  // Sort by the stored, INDEXED score/metric columns so paging is a fast indexed
  // scan, never a full-table sort. Default = best score first.
  const orders = {
    score_desc: "score DESC", score_asc: "score ASC",
    seed: "seed", seed_desc: "seed DESC",
    npl_desc: "npl DESC", npl_asc: "npl ASC",
    npm_desc: "npm DESC", npm_asc: "npm ASC",
    naqdv_asc: "naqdv ASC", naqdv_desc: "naqdv DESC",
    fdv_asc: "fdv ASC", fdv_desc: "fdv DESC",
    wp_desc: "wp DESC", wp_asc: "wp ASC",
    ef_desc: "ef DESC", ef_asc: "ef ASC",
  };
  const ord = orders[filter.sort] || "score DESC";
  const col = ord.split(" ")[0];
  const pageSize = Math.min(Math.max(1, Number(filter.pageSize) || 200), 1000);
  const page = Math.max(0, Number(filter.page) || 0);
  // Order straight by the indexed column (+ seed as a STABLE tiebreak so paging
  // can't skip/repeat on ties). NOTE: no `(col IS NULL)` guard here — that
  // expression is not indexable and forced a full-table sort of every row on the
  // unfiltered list (2.8s). The metrics are backfilled for all rows, and the Δv
  // "none" sentinel is a large number that already sorts last, so NULLs are a
  // non-issue; keeping the ORDER BY on the bare column lets it use the index.
  sql += ` ORDER BY ${ord}, seed LIMIT ? OFFSET ?`;
  params.push(pageSize, page * pageSize);
  return d.prepare(sql).all(...params);
}

// Count of seeds matching a filter (for pagination), reusing getSeeds' WHERE.
// Cheap: hits the same indexes and never touches line/criteria.
function countSeeds(filter = {}) {
  const d = getDb();
  let sql = "SELECT COUNT(*) n FROM seeds WHERE 1=1";
  const params = [];
  if (filter.bucket) { sql += " AND bucket = ?"; params.push(filter.bucket); }
  if (filter.job_id) { sql += " AND job_id = ?"; params.push(filter.job_id); }
  if (filter.loot) { sql += " AND loot LIKE ?"; params.push(`${filter.loot}%`); }
  if (filter.k2 !== undefined && filter.k2 !== null && filter.k2 !== "") { sql += " AND k2 = ?"; params.push(filter.k2 ? 1 : 0); }
  const range = (c, min, max) => {
    if (min != null && min !== "") { sql += ` AND ${c} >= ?`; params.push(Number(min)); }
    if (max != null && max !== "") { sql += ` AND ${c} <= ?`; params.push(Number(max)); }
  };
  range("npm", filter.npm_min, filter.npm_max);
  range("naqdv", filter.naqdv_min, filter.naqdv_max);
  range("fdv", filter.fdv_min, filter.fdv_max);
  range("wp", filter.wp_min, filter.wp_max);
  range("ef", filter.ef_min, filter.ef_max);
  if (filter.seed != null && String(filter.seed).trim() !== "") {
    const digits = String(filter.seed).replace(/[^\d]/g, "");
    if (digits !== "") { sql += " AND CAST(seed AS TEXT) LIKE ?"; params.push(`%${digits}%`); }
  }
  return d.prepare(sql).get(...params).n;
}

// One-time (idempotent) backfill of the `score` column for rows inserted before
// it existed, or after the score.js constants change. Pages by `seed` so every
// row is visited exactly once (a WHERE score IS NULL loop would spin on rows
// whose score legitimately computes to NULL), and batches the writes so it never
// holds one giant transaction over the multi-GB table.
function backfillScores({ batch = 20000 } = {}) {
  const d = getDb();
  const sel = d.prepare("SELECT seed, npl, ef, wp, naqdv, fdv FROM seeds WHERE seed > ? ORDER BY seed LIMIT ?");
  const upd = d.prepare("UPDATE seeds SET score = ? WHERE seed = ?");
  let last = -1, total = 0;
  for (;;) {
    const rows = sel.all(last, batch);
    if (rows.length === 0) break;
    d.transaction(() => { for (const r of rows) upd.run(seedScore(r) ?? null, r.seed); })();
    last = rows[rows.length - 1].seed;
    total += rows.length;
  }
  return total;
}

function getSeed(seed) {
  const d = getDb();
  return d.prepare("SELECT * FROM seeds WHERE seed = ?").get(seed);
}

// Mark a seed as fully expanded (all zones ingested) + refresh its stored line
// and zone_count. Called by the seed-detail expand job after upserting zones.
function markSeedExpanded(seed, line, zoneCount, criteria, npm, naqdv, ed, npl, fdv) {
  getDb().prepare(`UPDATE seeds SET expanded = 1, line = ?, zone_count = ?,
      criteria = COALESCE(?, criteria),
      npm = COALESCE(?, npm), npl = COALESCE(?, npl), naqdv = COALESCE(?, naqdv),
      fdv = COALESCE(?, fdv), ed = COALESCE(?, ed) WHERE seed = ?`)
    .run(line, zoneCount, criteria || null, npm ?? null, npl ?? null, naqdv ?? null, fdv ?? null, ed ?? null, seed);
}

// { seed: number-of-distinct-zones-with-a-done-generation } across all seeds.
function getGeneratedZoneCounts() {
  const rows = getDb().prepare(
    "SELECT seed, COUNT(DISTINCT zone_name) AS n FROM surface_jobs WHERE status='done' GROUP BY seed"
  ).all();
  const m = {};
  for (const r of rows) m[r.seed] = r.n;
  return m;
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
function getSetting(key) {
  const row = getDb().prepare("SELECT value FROM settings WHERE key = ?").get(key);
  return row ? row.value : null;
}

function setSetting(key, value) {
  getDb().prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)").run(key, value);
}

function updateFilterDef(id, name, rules) {
  return getDb().prepare(
    "UPDATE filter_defs SET name = ?, rules = ? WHERE id = ? AND builtin = 0"
  ).run(name, JSON.stringify(rules), id).changes;
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
  getAllSurfaceJobs,
  getGeneratedZoneCounts,
  getSurfaceJob,
  getSurfaceJobsForZone,
  updateSurfaceJob,
  deleteSurfaceJobs,
  getDistinctSurfaceZones,
  addJobLog,
  insertSeeds,
  getSeeds,
  countSeeds,
  backfillScores,
  getSeed,
  markSeedExpanded,
  getSurfaceCells,
  getFilterDefs,
  getFilterDef,
  createFilterDef,
  updateFilterDef,
  deleteFilterDef,
  getSetting,
  setSetting,
  createSeedFilter,
  setFilterMembers,
  getSeedFilters,
  getSeedFilter,
  getFilterSeeds,
  deleteSeedFilter,
};
