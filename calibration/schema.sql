-- seed-search.db schema
-- Stores Zig estimates + real calibration data for comparison

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- Universe seeds from JSONL
CREATE TABLE IF NOT EXISTS universe_seeds (
    universe_seed INTEGER PRIMARY KEY,
    loot TEXT NOT NULL,
    draws INTEGER,
    k2_enabled INTEGER DEFAULT 1
);

-- Zones (planets, moons, asteroid fields) within universes
CREATE TABLE IF NOT EXISTS zones (
    universe_seed INTEGER NOT NULL,
    zone_name TEXT NOT NULL,
    zone_index INTEGER,
    zone_type TEXT NOT NULL CHECK(zone_type IN ('planet','moon','asteroid-field','star','orbit')),
    surface_seed INTEGER NOT NULL,
    radius REAL NOT NULL DEFAULT 0,
    water TEXT,
    temperature TEXT,
    moisture TEXT,
    trees TEXT,
    aux TEXT,
    cliff TEXT,
    enemy TEXT,
    primary_resource TEXT,
    delta_v REAL,
    PRIMARY KEY (universe_seed, zone_name),
    FOREIGN KEY (universe_seed) REFERENCES universe_seeds(universe_seed)
);
CREATE INDEX IF NOT EXISTS idx_zones_radius ON zones(radius);
CREATE INDEX IF NOT EXISTS idx_zones_surface_seed ON zones(surface_seed);
CREATE INDEX IF NOT EXISTS idx_zones_type ON zones(zone_type);

-- Zig yield estimates ("y" field) and normalized scores ("rs" field)
CREATE TABLE IF NOT EXISTS zig_estimates (
    universe_seed INTEGER NOT NULL,
    zone_name TEXT NOT NULL,
    resource_name TEXT NOT NULL,
    score REAL,           -- normalized score from "rs" field
    yield_millions REAL,  -- yield in millions (parsed from "y" field)
    PRIMARY KEY (universe_seed, zone_name, resource_name),
    FOREIGN KEY (universe_seed, zone_name) REFERENCES zones(universe_seed, zone_name)
);
CREATE INDEX IF NOT EXISTS idx_zig_resource ON zig_estimates(resource_name);

-- Calibration runs (real Factorio ore counts)
CREATE TABLE IF NOT EXISTS calibrations (
    surface_seed INTEGER NOT NULL,
    radius INTEGER NOT NULL,
    water TEXT NOT NULL,
    freq REAL NOT NULL DEFAULT 1.0,
    size REAL NOT NULL DEFAULT 1.0,
    rich REAL NOT NULL DEFAULT 1.0,
    total_tiles INTEGER,
    water_tiles INTEGER,
    land_tiles INTEGER,
    created_at TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (surface_seed, radius, freq, size, rich)
);
CREATE INDEX IF NOT EXISTS idx_calib_surface_seed ON calibrations(surface_seed);

-- Per-resource ore counts from calibration runs
CREATE TABLE IF NOT EXISTS calibration_resources (
    surface_seed INTEGER NOT NULL,
    radius INTEGER NOT NULL,
    freq REAL NOT NULL DEFAULT 1.0,
    size REAL NOT NULL DEFAULT 1.0,
    rich REAL NOT NULL DEFAULT 1.0,
    resource_name TEXT NOT NULL,
    total INTEGER NOT NULL,
    patches INTEGER DEFAULT 0,
    PRIMARY KEY (surface_seed, radius, freq, size, rich, resource_name),
    FOREIGN KEY (surface_seed, radius, freq, size, rich) 
        REFERENCES calibrations(surface_seed, radius, freq, size, rich)
);

-- Convenience view: join Zig estimates with calibration data (FSR=1)
CREATE VIEW IF NOT EXISTS comparison AS
SELECT 
    z.universe_seed,
    z.zone_name,
    z.zone_type,
    z.surface_seed,
    z.radius,
    z.water,
    z.primary_resource,
    ze.resource_name,
    ze.score,
    ze.yield_millions as zig_yield_m,
    ROUND(ze.yield_millions * 1000000) as zig_items,
    cr.total as actual_items,
    cr.patches as actual_patches,
    c.total_tiles,
    c.land_tiles,
    c.water_tiles,
    ROUND(CAST(ze.yield_millions * 1000000 AS REAL) / NULLIF(cr.total, 0), 4) as zig_actual_ratio,
    -- ore per FSR unit: actual_items / (freq*size*rich) / land_tiles
    ROUND(CAST(cr.total AS REAL) / NULLIF(c.land_tiles, 0) / NULLIF(c.freq * c.size * c.rich, 0), 6) as ore_per_tile_per_fsr
FROM zig_estimates ze
JOIN zones z ON ze.universe_seed = z.universe_seed AND ze.zone_name = z.zone_name
JOIN calibrations c ON z.surface_seed = c.surface_seed
JOIN calibration_resources cr ON c.surface_seed = cr.surface_seed 
    AND c.radius = cr.radius 
    AND c.freq = cr.freq AND c.size = cr.size AND c.rich = cr.rich
    AND ze.resource_name = cr.resource_name
WHERE c.freq = 1.0 AND c.size = 1.0 AND c.rich = 1.0
  AND z.zone_name != 'Nauvis';  -- Nauvis uses map-gen UI, not universe gen
