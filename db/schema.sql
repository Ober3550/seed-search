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
  id   INTEGER PRIMARY KEY,    -- index in the deduped name-pool union (~757 entries)
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
-- seed / zone_seed are u32 in the generator → BIGINT here (u32 max > int4 max).
CREATE TABLE IF NOT EXISTS seeds (
  seed       BIGINT PRIMARY KEY,
  k2         BOOLEAN  NOT NULL,
  draws      INTEGER,
  vault_loot TEXT,
  -- header metrics (kept flat for join-free list/filter/sort)
  npl   SMALLINT,
  npm   SMALLINT,
  nw    SMALLINT,
  ne    SMALLINT,
  wp    SMALLINT,
  ef    SMALLINT,
  naqdv INTEGER,   -- 10_000_000 = none
  fdv   INTEGER,
  ed    SMALLINT,
  score INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── FLAT LEAVES: every node (star/planet/moon/belt/field) is one row ─────
CREATE TABLE IF NOT EXISTS zone (
  seed           BIGINT   NOT NULL REFERENCES seeds(seed) ON DELETE CASCADE,
  zone_name_id   INTEGER  NOT NULL REFERENCES zone_name(id),
  kind           SMALLINT NOT NULL,   -- enum_value domain='kind'
  star_name_id   INTEGER,             -- denormalized system (self for a star)
  parent_name_id INTEGER,             -- planet for a moon; star for planet/belt; null for star/field
  zone_seed      BIGINT   NOT NULL,
  radius         REAL,                -- f32 sufficient (see binary-format packing)
  primary_id     SMALLINT REFERENCES resource(id),
  dv             INTEGER,
  temperature SMALLINT, water SMALLINT, moisture SMALLINT,
  trees SMALLINT, aux SMALLINT, cliff SMALLINT, enemy SMALLINT,
  stellar_x  DOUBLE PRECISION,        -- set for kind=star / field
  stellar_y  DOUBLE PRECISION,
  present_mask BIGINT,                -- bitset of present resources (≤63; SE+K2 uses 18)
  PRIMARY KEY (seed, zone_name_id)
);

-- ── FACTS: resources on a leaf ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS zone_resource (
  seed           BIGINT   NOT NULL,
  zone_name_id   INTEGER  NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_seeds_score ON seeds (score DESC);
CREATE INDEX IF NOT EXISTS idx_seeds_npl   ON seeds (npl);
CREATE INDEX IF NOT EXISTS idx_seeds_naqdv ON seeds (naqdv);
CREATE INDEX IF NOT EXISTS idx_seeds_fdv   ON seeds (fdv);
CREATE INDEX IF NOT EXISTS idx_seeds_k2    ON seeds (k2);
-- drill one universe / per-body corpus stats (index both ways)
CREATE INDEX IF NOT EXISTS idx_zone_seed         ON zone (seed);
CREATE INDEX IF NOT EXISTS idx_zone_name         ON zone (zone_name_id);
CREATE INDEX IF NOT EXISTS idx_zone_primary      ON zone (primary_id);
-- resource relationship / heuristic queries
CREATE INDEX IF NOT EXISTS idx_zr_name_resource  ON zone_resource (zone_name_id, resource_id);
CREATE INDEX IF NOT EXISTS idx_zr_resource       ON zone_resource (resource_id);

COMMIT;
