-- Normalized "flat leaves + facts" schema for the seed-search store.
-- Target: PostgreSQL (Cloud SQL). See docs/storage-and-db.md.
--
-- Model: seeds (TRUNK) <- zone (FLAT LEAVES, one row per node incl. star, with
-- denormalized ancestry) <- zone_resource (FACTS: controls + provenance-tagged
-- quantities). Stringy fields are integer CODES resolved by the dictionary
-- tables (the same code space as the binary format's Dictionary).
--
-- Codes are assigned deterministically from data.zig by the generator, which
-- upserts the dictionary tables at startup:
--   resource.id      = index in gen.zig `resource_order` (0..17 for SE+K2)
--   enum_value(code) = the tag enum's integer value (data.zig) / kind index
--   zone_name.id     = index in the deduped union of the data.zig name pools

BEGIN;

-- ── Provenance / versioning ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);  -- e.g. ('schema_version','1'), ('mod_set','se+k2'), ('generator_version', <git sha>)

-- ── Dictionaries (shared code space) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS resource (
  id   SMALLINT PRIMARY KEY,   -- index in resource_order
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS zone_name (
  id   SMALLINT PRIMARY KEY,   -- index in the deduped name-pool union (758 entries, ≤1023)
  name TEXT UNIQUE NOT NULL
);

-- zone kind + the seven tag domains in one small reference table.
-- domain ∈ {kind, temperature, water, moisture, trees, aux, cliff, enemy}.
CREATE TABLE IF NOT EXISTS enum_value (
  domain TEXT     NOT NULL,
  code   SMALLINT NOT NULL,
  name   TEXT     NOT NULL,
  PRIMARY KEY (domain, code),
  UNIQUE (domain, name)
);

-- ── TRUNK: one row per universe ──────────────────────────────────────────
-- seed / zone_seed are u32 in the generator. Postgres has no unsigned int4, so
-- they are stored as INTEGER = (u32 − 2^31); add 2^31 back on read. The offset
-- preserves sort order (monotonic), so ORDER BY seed still works.
CREATE TABLE IF NOT EXISTS seeds (
  seed          INTEGER PRIMARY KEY,   -- u32 as (seed − 2^31)
  k2            BOOLEAN  NOT NULL,
  vault_loot    TEXT,
  -- header metrics (kept flat for join-free list/filter/sort)
  naquium_dv    INTEGER,   -- Δv to nearest naquium-primary field; 10_000_000 = none
  field_dv      INTEGER,   -- Δv to nearest any field; 10_000_000 = none
  planets       SMALLINT,  -- planets only
  bodies        SMALLINT,  -- planets + moons
  water_bodies  SMALLINT,  -- count of bodies with water
  enemy_bodies  SMALLINT,  -- count of bodies with enemies
  water_pct     SMALLINT,
  hostility_pct SMALLINT,
  enemy_danger  SMALLINT,  -- signed −100..100
  score         SMALLINT
);

-- ── FLAT LEAVES: every node (star/planet/moon/belt/field) is one row ─────
-- Column order mirrors docs/storage-column-analysis.md: u32 identifiers and the
-- 4-byte numerics first, then the 2-byte enum/dict columns, then the mask.
CREATE TABLE IF NOT EXISTS zone (
  seed            INTEGER  NOT NULL REFERENCES seeds(seed) ON DELETE CASCADE,  -- u32 as (seed − 2^31)
  zone_seed       INTEGER  NOT NULL,   -- u32 as (zone_seed − 2^31)
  delta_v         INTEGER,             -- Δv from Nauvis (field Δv reaches ~150k → 4B)
  radius          REAL,
  stellar_x       REAL,                -- set for kind=star / field (Δv stored → REAL precision ok)
  stellar_y       REAL,
  kind            SMALLINT NOT NULL,   -- enum_value domain='kind'
  star_name_id    SMALLINT,            -- owning system (self for a star); many in full universes
  parent_name_id  SMALLINT,            -- planet for a moon; star for planet/belt; null for star/field
  zone_name_id    SMALLINT NOT NULL REFERENCES zone_name(id),
  primary_id      SMALLINT REFERENCES resource(id),
  temperature_idx SMALLINT, water_idx SMALLINT, moisture_idx SMALLINT,
  trees_idx SMALLINT, aux_idx SMALLINT, cliff_idx SMALLINT, enemy_idx SMALLINT,
  resource_mask   INTEGER,             -- bitset of present resources (18 bits, SE+K2)
  PRIMARY KEY (seed, zone_name_id)
);

-- ── FACTS: resources on a leaf ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS zone_resource (
  seed           INTEGER  NOT NULL,   -- u32 as (seed − 2^31)
  zone_name_id   SMALLINT NOT NULL,
  resource_id    SMALLINT NOT NULL REFERENCES resource(id),
  present        BOOLEAN  NOT NULL,
  -- universe-gen CONTROLS (the driver + estimator input)
  frequency REAL, size REAL, richness REAL,
  -- derived quantity + provenance
  tiles          BIGINT,
  amount         DOUBLE PRECISION,
  source         SMALLINT,   -- 0=estimate, 1=measured; NULL = controls only
  source_version INTEGER,
  PRIMARY KEY (seed, zone_name_id, resource_id),
  FOREIGN KEY (seed, zone_name_id) REFERENCES zone(seed, zone_name_id) ON DELETE CASCADE
);

-- ── Indexes ──────────────────────────────────────────────────────────────
-- seed list / filter / sort (join-free hot path)
CREATE INDEX IF NOT EXISTS idx_seeds_score        ON seeds (score DESC);
CREATE INDEX IF NOT EXISTS idx_seeds_planets      ON seeds (planets);
CREATE INDEX IF NOT EXISTS idx_seeds_bodies       ON seeds (bodies);
CREATE INDEX IF NOT EXISTS idx_seeds_naquium_dv   ON seeds (naquium_dv);
CREATE INDEX IF NOT EXISTS idx_seeds_field_dv     ON seeds (field_dv);
CREATE INDEX IF NOT EXISTS idx_seeds_water_pct    ON seeds (water_pct);
CREATE INDEX IF NOT EXISTS idx_seeds_hostility    ON seeds (hostility_pct);
CREATE INDEX IF NOT EXISTS idx_seeds_enemy_danger ON seeds (enemy_danger);
CREATE INDEX IF NOT EXISTS idx_seeds_k2           ON seeds (k2);
-- (btree serves both ASC and DESC scans, so the DESC-default sorts reuse these)
-- drill one universe / per-body corpus stats (index both ways)
CREATE INDEX IF NOT EXISTS idx_zone_seed         ON zone (seed);
CREATE INDEX IF NOT EXISTS idx_zone_name         ON zone (zone_name_id);
CREATE INDEX IF NOT EXISTS idx_zone_primary      ON zone (primary_id);
-- resource relationship / heuristic queries
CREATE INDEX IF NOT EXISTS idx_zr_name_resource  ON zone_resource (zone_name_id, resource_id);
CREATE INDEX IF NOT EXISTS idx_zr_resource       ON zone_resource (resource_id);

COMMIT;
