/// SE universe generator — extracted from main.zig as a reusable module.
/// Call generateUniverse() to get the zone list for a given seed.

const std = @import("std");
pub fn ArrayList(comptime T: type) type { return std.array_list.AlignedManaged(T, null); }

/// Count of degenerate draws (see Rng.int1) since the last reset. A universe
/// generated while this was incremented hit a draw where SE's own arithmetic
/// produces an out-of-range index, so it is only as well-defined as SE is at
/// that point — main.zig reports the seed so it can be excluded from
/// conformance-sensitive work. Process is single-threaded, so a plain global is
/// enough; computeTags builds a throwaway Rng per zone, so a per-instance
/// counter could not be aggregated.
pub var degen_draws: u32 = 0;

pub const Rng = struct {
    s1: u32, s2: u32, s3: u32, draw: u32 = 0,
    pub fn initFactorio(seed: u32) Rng {
        const s = if (seed < 341) @as(u32, 341) else seed;
        return .{ .s1 = s, .s2 = s, .s3 = s };
    }
    pub fn next(self: *Rng) u32 { self.draw += 1;
        self.s1 = ((self.s1 & 0xFFFFFFFE) << 12) ^ (((self.s1 << 13) ^ self.s1) >> 19);
        self.s2 = ((self.s2 & 0xFFFFFFF8) << 4) ^ (((self.s2 << 2) ^ self.s2) >> 25);
        self.s3 = ((self.s3 & 0xFFFFFFF0) << 17) ^ (((self.s3 << 3) ^ self.s3) >> 11);
        return self.s1 ^ self.s2 ^ self.s3;
    }
    pub fn float(self: *Rng) f64 { return @as(f64, @floatFromInt(self.next())) * 2.3283064365386963e-10; }

    /// Factorio's `crng(n)` — a 1-based index in [1, n].
    ///
    /// The Lua reference (universe_generator/lua/rng.lua:17, and Factorio's own
    /// generator) computes `math.floor(float * n - 0.0000001) + 1`. When the
    /// draw is small enough that `float * n < 1e-7`, that floors to -1 and the
    /// expression yields **0** — an out-of-range index. Lua returns 0 happily;
    /// Zig cannot convert a negative f64 to u32 at all (it is illegal, and in
    /// ReleaseFast produced a garbage index and an access violation).
    ///
    /// So return 0 exactly as Lua does. 0 means "no index" and every call site
    /// must handle it; see gen.zig's tag assignment for the semantics SE gives
    /// it (the tag is simply never set). The draw is consumed either way, which
    /// is what keeps the RNG stream aligned with the reference.
    pub fn int1(self: *Rng, n: u32) u32 {
        const v = @floor(self.float() * @as(f64, @floatFromInt(n)) - 0.0000001);
        if (v < 0) { degen_draws += 1; return 0; }
        return @as(u32, @intFromFloat(v)) + 1;
    }

    /// Factorio's `crng(lo, hi)` — an index in [lo, hi]. Same degenerate case as
    /// int1: Lua yields `lo - 1`. Both call sites pass lo >= 1 (80, and a
    /// planet count that is always >= 1), so the saturation below is
    /// unreachable in practice; it exists so this can never wrap.
    pub fn intRange(self: *Rng, lo: u32, hi: u32) u32 {
        const v = @floor(self.float() * @as(f64, @floatFromInt(hi - lo + 1)) - 0.0000001);
        if (v < 0) { degen_draws += 1; return lo -| 1; }
        return lo + @as(u32, @intFromFloat(v));
    }
};

pub const data = @import("data.zig");
const Body = data.Body;
const Planet = struct { name: []const u8, moons: ArrayList([]const u8) };
pub const Zone = struct { name: []const u8, ztype: data.ZoneType, seed: u32 = 0, radius: f64 = 0, star_gravity_well: f64 = 0, planet_gravity_well: f64 = 0, stellar_x: f64 = 0, stellar_y: f64 = 0, parent_index: i32 = -1, radius_multiplier: f64 = 0 };

pub const Universe = struct {
    zones: ArrayList(Zone),
    zoneByName: std.StringHashMapUnmanaged(u32),
    draws: u32,
    k2: bool,
    vault_loot: []const u8,
    calidus_children: ArrayList([]const u8),
    calidus_child_types: ArrayList(data.ZoneType),
    // Home-system (Calidus) special-body roles, captured during Phase 6. These
    // drive the Calidus star's child ORDER (SE universe-homesystem.lua rebuilds
    // star.children = vulcanite, homeworld, vitamelange.parent, beryllium,
    // iridium.parent, holmium.parent, remaining planets, cryonite.parent,
    // methane, remaining belts), which computeGravityWells needs to match the
    // game's gravity wells / delta-v. Empty string = not assigned.
    home_vulcanite: []const u8 = "",
    home_vitamelange_parent: []const u8 = "",
    home_iridium_parent: []const u8 = "",
    home_holmium_parent: []const u8 = "",
    home_cryonite_parent: []const u8 = "",
    home_beryllium_belt: []const u8 = "",
    home_methane_belt: []const u8 = "",
};

/// Build a name→Body hash map for O(1) lookups (replaces 4 linear scans).
pub fn buildBodyMap(alloc: std.mem.Allocator) !std.StringHashMapUnmanaged(data.Body) {
    var map: std.StringHashMapUnmanaged(data.Body) = .{};
    for (&data.unassigned_planets) |*b| { try map.put(alloc, b.name, b.*); }
    for (&data.unassigned_moons) |*b| { try map.put(alloc, b.name, b.*); }
    for (&data.unassigned_planets_or_moons) |*b| { try map.put(alloc, b.name, b.*); }
    for (&data.special_bodies) |*b| { try map.put(alloc, b.name, b.*); }
    return map;
}

/// Look up a body prototype by name (O(1) via hash map).
pub fn lookupBodyFast(bodyMap: std.StringHashMapUnmanaged(data.Body), name: []const u8) ?data.Body {
    return bodyMap.get(name);
}

/// Legacy: linear scan body lookup. Prefer lookupBodyFast with a pre-built map.
pub fn lookupBody(name: []const u8) ?data.Body {
    for (data.unassigned_planets) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.unassigned_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.unassigned_planets_or_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.special_bodies) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    return null;
}

/// Get a zone's index by name (O(1)). Panics if not found.
fn zoneIndex(byName: std.StringHashMapUnmanaged(u32), name: []const u8) u32 {
    return byName.get(name) orelse @panic("zone not found");
}
/// Check if a zone name exists (O(1)).
fn zoneExists(byName: std.StringHashMapUnmanaged(u32), name: []const u8) bool {
    return byName.contains(name);
}
/// Get a zone's radius by name (O(1)). Returns 0 if not found.
fn zoneRadius(zones: ArrayList(Zone), byName: std.StringHashMapUnmanaged(u32), name: []const u8) f64 {
    if (byName.get(name)) |zi| return zones.items[zi].radius;
    return 0;
}

/// Fisher–Yates, matching SE's util.shuffle_with_generator (scripts/util.lua:67):
///     for i = #tbl, 2, -1 do
///       local rand = random_generator(i)
///       tbl[i], tbl[rand] = tbl[rand], tbl[i]
///     end
///
/// On a degenerate draw (see Rng.int1) SE gets rand == 0 and evaluates
/// `tbl[i], tbl[0] = tbl[0], tbl[i]`. In a 1-based Lua table `tbl[0]` is nil, so
/// this ASSIGNS NIL TO tbl[i] — it destroys the element and parks the value at
/// index 0, leaving a hole that breaks `#tbl` and `ipairs`. That is upstream
/// corruption, not a behaviour worth reproducing, and a nil hole has no
/// representation in a Zig slice. We skip the swap instead and record it in
/// degen_draws, so affected seeds can be identified rather than silently trusted.
fn shuffleSlice(comptime T: type, rng: *Rng, slice: []T) void {
    var i: usize = slice.len;
    while (i > 1) {
        i -= 1;
        const j = rng.int1(@intCast(i + 1));
        if (j == 0) continue; // degenerate draw — see above
        const t = slice[i]; slice[i] = slice[j - 1]; slice[j - 1] = t;
    }
}

fn shuffleBodies(rng: *Rng, slice: []Body) void { shuffleSlice(Body, rng, slice); }

fn shufflePlanets(rng: *Rng, slice: []Planet) void { shuffleSlice(Planet, rng, slice); }

fn shuffleNames(rng: *Rng, names: [][]const u8) void { shuffleSlice([]const u8, rng, names); }

/// Linear zone-index lookup by name over the in-progress zone list (used during
/// Phase 6, before zoneByName is built). Returns -1 if not found.
fn zoneIndexInList(zones: ArrayList(Zone), name: []const u8) i32 {
    for (zones.items, 0..) |z, i| {
        if (std.mem.eql(u8, z.name, name)) return @intCast(i);
    }
    return -1;
}

fn pickShuffledName(rng: *Rng, alloc: std.mem.Allocator, const_names: []const []const u8, zones: ArrayList(Zone)) ![]const u8 {
    const names = try alloc.alloc([]const u8, const_names.len);
    @memcpy(names, const_names);
    shuffleNames(rng, names);
    var result: ?[]const u8 = null;
    for (names) |n| {
        var used = false;
        for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
        if (!used) result = n;
    }
    return result orelse @panic("No unused name in pool");
}

fn shuffleMoons(rng: *Rng, moons: [][]const u8) void { shuffleSlice([]const u8, rng, moons); }

fn sortByPriority(slice: []Body) void {
    var keys: [600]i32 = undefined;
    for (slice, 0..) |p, idx| {
        var pv: i32 = @intCast(idx + 1);
        if (p.patron != null) pv += 10000;
        if (p.has_biome_replacements) pv += 5000;
        if (p.tag_temperature != null or p.tag_water != null or p.tag_moisture != null or p.tag_trees != null or p.tag_aux != null or p.tag_cliff != null or p.tag_enemy != null) pv += 1000;
        if (p.primary_resource != null) pv += 500;
        keys[idx] = pv;
    }
    var i: usize = 0;
    while (i < slice.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < slice.len) : (j += 1) {
            if (keys[j] < keys[i]) {
                const tk = keys[i]; keys[i] = keys[j]; keys[j] = tk;
                const tb = slice[i]; slice[i] = slice[j]; slice[j] = tb;
            }
        }
    }
}

fn countBelts(zones: ArrayList(Zone), star_name: []const u8) u32 {
    var count: u32 = 0;
    const marker = " Asteroid Belt ";
    for (zones.items) |z| {
        if (z.name.len > star_name.len + marker.len and std.mem.startsWith(u8, z.name, star_name)) {
            const rest = z.name[star_name.len..];
            if (std.mem.startsWith(u8, rest, marker)) {
                const num_part = rest[marker.len..];
                var is_num = num_part.len > 0;
                for (num_part) |c| { if (c < '0' or c > '9') { is_num = false; break; } }
                if (is_num) count += 1;
            }
        }
    }
    return count;
}

// Helper: find a planet's raw radius (f64) by name from the zone list
fn findPlanetRadius(zones: ArrayList(Zone), name: []const u8) f64 {
    for (zones.items) |z| {
        if (std.mem.eql(u8, z.name, name) and z.ztype == .planet) return z.radius;
    }
    return 0;
}

// Look up a body's radius_multiplier from the raw data pools
fn lookupRadiusMultiplier(name: []const u8) ?f64 {
    for (&data.unassigned_planets) |b| { if (std.mem.eql(u8, b.name, name)) return b.radius_multiplier; }
    for (&data.unassigned_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b.radius_multiplier; }
    for (&data.unassigned_planets_or_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b.radius_multiplier; }
    for (&data.special_moon_multipliers) |s| { if (std.mem.eql(u8, s.name, name)) return s.radius_multiplier; }
    return null;
}

// Compute planet radius: consumes RNG, then checks prototype for override. Returns raw f64.
fn planetRadius(rng: *Rng, name: []const u8) f64 {
    const r = rng.float();
    const mult: f64 = lookupRadiusMultiplier(name) orelse (0.4 + 0.6 * r * r);
    return 10000.0 * mult;
}

// Compute moon radius: consumes RNG, then computes from parent radius. Returns raw f64.
fn moonRadius(rng: *Rng, parent_radius: f64, name: []const u8) f64 {
    const r = rng.float();
    const mult: f64 = lookupRadiusMultiplier(name) orelse (0.2 + 0.8 * r * r);
    return parent_radius / 2.0 * mult;
}

// Radius for special moons (add_special_moon): looks up prototype multiplier, defaults to 0.3
fn specialMoonRadius(parent_radius: f64, name: []const u8) f64 {
    const mult: f64 = lookupRadiusMultiplier(name) orelse 0.3;
    const cap: f64 = @min(parent_radius, 5000.0);
    return (0.5 * parent_radius + cap) / 2.0 * mult;
}

// Radius for K2 imersite moon (add_special_moon_from_unassigned): uses rng(80,120)/100 extra
// Radius for K2 imersite moon (add_special_moon_from_unassigned): uses rng(80,120)/100 extra
fn specialMoonRadiusRng(parent_radius: f64, name: []const u8, rng_mult: u32) f64 {
    const base_mult: f64 = lookupRadiusMultiplier(name) orelse 0.3;
    const mult: f64 = base_mult * @as(f64, @floatFromInt(rng_mult)) / 100.0;
    const cap: f64 = @min(parent_radius, 5000.0);
    return (0.5 * parent_radius + cap) / 2.0 * mult;
}

// ===== Tag computation =====
// Tag tables match Universe.temperature_tags etc. in universe.lua
const temperature_tags = [_]data.Temperature{ .bland, .temperate, .midrange, .balanced, .wild, .extreme, .cool, .cold, .vcold, .frozen, .warm, .hot, .vhot, .volcanic };
const water_tags = [_]data.Water{ .none, .low, .med, .high, .max };
const moisture_tags = [_]data.Moisture{ .none, .low, .med, .high, .max };
const trees_tags = [_]data.Trees{ .none, .low, .med, .high, .max };
const aux_tags = [_]data.Aux{ .very_low, .low, .med, .high, .very_high };
const cliff_tags = [_]data.Cliff{ .none, .low, .med, .high, .max };
const enemy_tags = [_]data.Enemy{ .none, .very_low, .low, .med, .high, .very_high, .max };

pub const Tags = struct {
    temperature: ?data.Temperature,
    water: ?data.Water,
    moisture: ?data.Moisture,
    trees: ?data.Trees,
    aux: ?data.Aux,
    cliff: ?data.Cliff,
    enemy: ?data.Enemy,
};

/// Index a tag table with a 1-based index from `Rng.int1`, Lua-style.
///
/// `idx == 0` is the degenerate draw described on `Rng.int1`: SE evaluates
/// `X_tags[0]`, which is nil in a 1-based Lua table, and assigning nil leaves
/// the tag unset. Returning null here reproduces that exactly — the JSONL
/// writer omits null tags, and the resource predicates (`hasStrongClaim`,
/// `isPrimaryEligible`, `computeZoneResourceControls`) all test `!= null` first,
/// which is the direct analogue of SE's `pairs()` skipping an absent key.
fn tagAt(comptime E: type, table: []const E, idx: u32) ?E {
    if (idx == 0 or idx > table.len) return null;
    return table[idx - 1];
}

pub fn parseTagEnum(comptime E: type, tag_str: ?[]const u8) ?E {
    if (tag_str) |s| {
        inline for (@typeInfo(E).@"enum".fields) |f| {
            if (std.mem.eql(u8, s, @field(E, f.name).tagStr())) return @enumFromInt(f.value);
        }
    }
    return null;
}

// Compute tags for a planet or moon. Pass bodyMap for O(1) prototype lookups.
pub fn computeTags(zone_seed: u32, name: []const u8, bodyMap: ?std.StringHashMapUnmanaged(data.Body)) Tags {
    var crng = Rng.initFactorio(zone_seed);
    const proto = if (bodyMap) |bm| bm.get(name) else lookupBody(name);

    // Start with prototype tags if available
    var tags = Tags{
        .temperature = parseTagEnum(data.Temperature, if (proto) |p| p.tag_temperature else null),
        .water = parseTagEnum(data.Water, if (proto) |p| p.tag_water else null),
        .moisture = parseTagEnum(data.Moisture, if (proto) |p| p.tag_moisture else null),
        .trees = parseTagEnum(data.Trees, if (proto) |p| p.tag_trees else null),
        .aux = parseTagEnum(data.Aux, if (proto) |p| p.tag_aux else null),
        .cliff = parseTagEnum(data.Cliff, if (proto) |p| p.tag_cliff else null),
        .enemy = parseTagEnum(data.Enemy, if (proto) |p| p.tag_enemy else null),
    };

    // ticks_per_day: skip (not used for summary)
    if (!std.mem.eql(u8, name, "Nauvis")) {
        if (crng.float() < 0.5) {
            _ = crng.int1(60 * 60 * 59);
        } else {
            _ = crng.int1(60 * 60 * 19);
        }
    }

    // Every assignment below mirrors SE's `zone.tags.X = X_tags[crng(#X_tags)]`
    // (space-exploration 0.7.57, scripts/universe.lua:1605-1645). A degenerate
    // draw makes crng return 0, SE indexes `X_tags[0]` = nil, and assigning nil
    // to a Lua table leaves the key ABSENT — the tag is simply never set, and
    // `Universe.apply_control_tags` (universe.lua:1507) iterates `pairs(tags)`
    // so it never sees the missing domain and never raises "Invalid tag".
    // `tagAt` reproduces that: index 0 leaves the tag null.

    // Temperature
    if (tags.temperature == null) {
        tags.temperature = tagAt(data.Temperature, &temperature_tags, crng.int1(@intCast(temperature_tags.len)));
    }

    // Water, moisture, trees
    if (tags.water == null or tags.moisture == null or tags.trees == null) {
        // SE uses crng(1, 5) here; int1(5) is the same expression, degenerate
        // case included (both yield 0). @min(x, 0) == 0 matches Lua's math.min.
        var rng_water: u32 = 1;
        var rng_moisture: u32 = 1;
        var rng_trees: u32 = 1;
        if (crng.float() < 0.75) {
            rng_water = crng.int1(5);
            rng_moisture = rng_water;
            if (crng.float() < 0.5) {
                rng_moisture = crng.int1(5);
            }
            rng_trees = rng_moisture;
            if (crng.float() < 0.5) {
                rng_trees = crng.int1(5);
            }
        }
        rng_trees = @min(rng_trees, crng.int1(5));

        if (tags.water == null) tags.water = tagAt(data.Water, &water_tags, rng_water);
        if (tags.moisture == null) tags.moisture = tagAt(data.Moisture, &moisture_tags, rng_moisture);
        if (tags.trees == null) tags.trees = tagAt(data.Trees, &trees_tags, rng_trees);
    }

    // Enemy
    if (tags.enemy == null) {
        tags.enemy = tagAt(data.Enemy, &enemy_tags, crng.int1(@intCast(enemy_tags.len)));
    }

    // Aux
    if (tags.aux == null) {
        tags.aux = tagAt(data.Aux, &aux_tags, crng.int1(@intCast(aux_tags.len)));
    }

    // Cliff
    if (tags.cliff == null) {
        tags.cliff = tagAt(data.Cliff, &cliff_tags, crng.int1(@intCast(cliff_tags.len)));
    }

    return tags;
}

// ===== Resource computation =====
// Matches Universe.generate_zone_resource_bias + apply_zone_resource_assignments

pub const resource_order = [_][]const u8{
    "iron-ore", "copper-ore", "uranium-ore", "coal", "crude-oil", "stone",
    "se-vulcanite", "se-cryonite", "se-vitamelange", "se-naquium-ore", "se-methane-ice", "se-water-ice",
    "se-beryllium-ore", "se-iridium-ore", "se-holmium-ore",
    "kr-imersite", "kr-mineral-water", "kr-rare-metal-ore",
};

/// Per-resource, per-zone autoplace controls (indexed by `resource_order`).
/// These are the raw map-gen control values SE feeds into the resource autoplace
/// expressions as `control:<name>:frequency/size/richness`. Downstream, SE raises
/// each to the power 0.8 (setting_scale) inside the noise expression, and
/// `Zone.apply_controls_to_mapgen` multiplies `frequency` by the zone-level
/// `Zone.get_frequency_multiplier(zone)` and clamps size/richness to >= 0.
pub const ResourceControl = struct {
    present: bool = false, // resource is placed on this zone
    frequency: f64 = 0,
    size: f64 = 0,
    richness: f64 = 0,
    fsr_score: f64 = 0, // normalized freq*size*richness (legacy computeZoneResources value)
};

const RESOURCE_PRIMARY_BOOST: f64 = 0.5;
const RESOURCE_SECONDARY_IRREGULARITY: f64 = 0.75;
const RESOURCE_POWER: f64 = 1.5;
const RESOURCE_NORM_PLANET: f64 = 22.02730826300005162466;
const RESOURCE_NORM_FIELD: f64 = 167.79554553234018499;

/// Approximate asteroid field effective radius (from SE data: ~10000 width).
const FIELD_EFFECTIVE_RADIUS: f64 = 5000.0;
/// Asteroid tile coverage fraction (estimated: similar to planet water_none).
const FIELD_LAND_FRACTION: f64 = 0.95;

/// Compute estimated yield in millions for a resource score on a zone.
/// Returns 0 if the yield is negligible.
pub fn computeYield(score: f64, is_field: bool, radius: f64, water: ?data.Water, resource_name: []const u8) f64 {
    const norm: f64 = if (is_field) RESOURCE_NORM_FIELD else RESOURCE_NORM_PLANET;
    const raw_fsr = score * norm;
    const scale = resourceAmountScale(resource_name);

    const area: f64 = if (is_field)
        std.math.pi * FIELD_EFFECTIVE_RADIUS * FIELD_EFFECTIVE_RADIUS
    else
        std.math.pi * radius * radius;

    const land_frac: f64 = if (is_field)
        FIELD_LAND_FRACTION
    else if (water) |w|
        w.landFraction()
    else
        0.5;

    return raw_fsr * area * land_frac * scale / 1_000_000.0;
}

/// Estimated per-resource base amount scaling (relative to iron=1.0).
/// Based on Factorio `normal` amounts in resource autoplace.
pub fn resourceAmountScale(resource_name: []const u8) f64 {
    // vanilla solid resources
    if (std.mem.eql(u8, resource_name, "iron-ore")) return 1.0;      // normal=500
    if (std.mem.eql(u8, resource_name, "copper-ore")) return 1.0;    // normal=500
    if (std.mem.eql(u8, resource_name, "coal")) return 0.8;          // normal=400
    if (std.mem.eql(u8, resource_name, "stone")) return 0.7;         // normal=350
    if (std.mem.eql(u8, resource_name, "uranium-ore")) return 0.6;   // normal=300
    if (std.mem.eql(u8, resource_name, "crude-oil")) return 0.012;   // fluid, scaled down 500x
    // SE special resources (use same scale as iron)
    if (std.mem.eql(u8, resource_name, "se-vulcanite")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-cryonite")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-holmium-ore")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-beryllium-ore")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-iridium-ore")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-vitamelange")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-naquium-ore")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-methane-ice")) return 1.0;
    if (std.mem.eql(u8, resource_name, "se-water-ice")) return 1.0;
    // K2 resources
    if (std.mem.eql(u8, resource_name, "kr-imersite")) return 1.0;
    if (std.mem.eql(u8, resource_name, "kr-rare-metal-ore")) return 1.0;
    if (std.mem.eql(u8, resource_name, "kr-mineral-water")) return 0.012;
    // default
    return 1.0;
}

/// Format yield as a human-readable string like "150M" or "2.3B".
pub fn formatYield(yield_m: f64, buf: []u8) []const u8 {
    if (yield_m < 0.5) return "0";
    if (yield_m >= 1000.0) {
        return std.fmt.bufPrint(buf, "{d:.1}B", .{yield_m / 1000.0}) catch "0";
    }
    if (yield_m >= 1.0) {
        return std.fmt.bufPrint(buf, "{d:.0}M", .{@floor(yield_m)}) catch "0";
    }
    return std.fmt.bufPrint(buf, "{d:.1}M", .{yield_m}) catch "0";
}

/// Compute resource scores for a single planet or moon.
/// primary_resource must be known (from prototype, special_type, or claiming).
/// Returns scores indexed by resource_order (0..17). Score = FSR / norm.
/// Full per-resource controls (freq/size/richness) for a zone. Same computation
/// as `computeZoneResources`, but returns the individual control values needed to
/// drive resource autoplace, not just the collapsed FSR score.
pub fn computeZoneResourceControls(zone_seed: u32, zone_type: data.ZoneType, primary_resource: ?[]const u8, tags: Tags) [18]ResourceControl {
    var controls: [18]ResourceControl = @splat(.{});

    // Per-zone RNG for bias generation
    var bias_rng = Rng.initFactorio(zone_seed);

    // Generate base biases for each resource
    var biases: [18]f64 = undefined;
    var bias_indices: [18]u32 = undefined;
    for (resource_order, 0..) |_, ri| {
        biases[ri] = bias_rng.float();
        bias_indices[ri] = @intCast(ri);
    }

    // Sort biases descending
    var i: usize = 0;
    while (i < 18) : (i += 1) {
        var j: usize = i + 1;
        while (j < 18) : (j += 1) {
            if (biases[bias_indices[j]] > biases[bias_indices[i]]) {
                const tmp = bias_indices[i];
                bias_indices[i] = bias_indices[j];
                bias_indices[j] = tmp;
            }
        }
    }

    // Rebuild ordered list with tag filtering, then sort by ordered_bias
    // Primary resource gets ordered_bias = base_bias + 1 to ensure it's first
    var ordered_ri: [18]u32 = undefined;
    var ordered_vals: [18]f64 = undefined;
    var ordered_n: u32 = 0;

    for (bias_indices) |ri| {
        var allowed = true;

        // Exclude space-only resources from planets and moons (they can only appear on asteroid fields)
        if (zone_type != .@"asteroid-field" and (ri == @intFromEnum(data.Resource.se_naquium_ore) or ri == @intFromEnum(data.Resource.se_methane_ice) or ri == @intFromEnum(data.Resource.se_water_ice))) {
            allowed = false;
        }
        // Exclude resources that can't spawn on asteroid fields (SE resource_word_rules
        // allowed_for_zone): not_space words coal/crude-oil/vulcanite/cryonite/
        // vitamelange/iridium/holmium, not_asteroid_field beryllium, and kr-mineral-water
        // (water). water-ice is re-allowed by SE override so it stays.
        if (zone_type == .@"asteroid-field" and (ri == @intFromEnum(data.Resource.coal) or
            ri == @intFromEnum(data.Resource.crude_oil) or
            ri == @intFromEnum(data.Resource.se_vulcanite) or
            ri == @intFromEnum(data.Resource.se_cryonite) or
            ri == @intFromEnum(data.Resource.se_vitamelange) or
            ri == @intFromEnum(data.Resource.se_beryllium_ore) or
            ri == @intFromEnum(data.Resource.se_iridium_ore) or
            ri == @intFromEnum(data.Resource.se_holmium_ore) or
            ri == @intFromEnum(data.Resource.kr_mineral_water)))
        {
            allowed = false;
        }
        if (allowed and (primary_resource == null or !std.mem.eql(u8, resource_order[ri], primary_resource.?))) {
            if (ri == @intFromEnum(data.Resource.se_cryonite)) {
                allowed = tags.temperature != null and
                    (tags.temperature.? == .extreme or tags.temperature.? == .cool or
                     tags.temperature.? == .cold or tags.temperature.? == .vcold or
                     tags.temperature.? == .frozen);
            } else if (ri == @intFromEnum(data.Resource.se_vitamelange)) {
                allowed = tags.moisture != null and
                    (tags.moisture.? == .med or tags.moisture.? == .high or tags.moisture.? == .max);
            } else if (ri == @intFromEnum(data.Resource.se_vulcanite)) {
                allowed = tags.temperature != null and
                    (tags.temperature.? == .extreme or tags.temperature.? == .warm or
                     tags.temperature.? == .hot or tags.temperature.? == .vhot or
                     tags.temperature.? == .volcanic);
            } else if (ri == @intFromEnum(data.Resource.kr_mineral_water)) {
                allowed = tags.water != null and
                    (tags.water.? == .low or tags.water.? == .med or
                     tags.water.? == .high or tags.water.? == .max);
            }
        }

        if (allowed) {
            const sort_key: f64 = if (primary_resource != null and std.mem.eql(u8, resource_order[ri], primary_resource.?))
                biases[ri] + 1.0
            else
                biases[ri];
            ordered_ri[ordered_n] = ri;
            ordered_vals[ordered_n] = sort_key;
            ordered_n += 1;
        }
    }

    // Sort by ordered_vals descending
    var si: usize = 0;
    while (si < ordered_n) : (si += 1) {
        var sj: usize = si + 1;
        while (sj < ordered_n) : (sj += 1) {
            if (ordered_vals[sj] > ordered_vals[si]) {
                const tmp_ri = ordered_ri[si]; ordered_ri[si] = ordered_ri[sj]; ordered_ri[sj] = tmp_ri;
                const tmp_v = ordered_vals[si]; ordered_vals[si] = ordered_vals[sj]; ordered_vals[sj] = tmp_v;
            }
        }
    }

    // Find primary position in sorted list
    var primary_pos: i32 = -1;
    for (ordered_ri[0..ordered_n], 0..) |ri, pi| {
        if (primary_resource != null and std.mem.eql(u8, resource_order[ri], primary_resource.?)) {
            primary_pos = @intCast(pi);
            break;
        }
    }

    // Apply incompatible resource exclusions (beryllium/iridium/holmium/vitamelange)
    // These four are mutually exclusive - only the highest-ranked survives
    var exclude_beryllium = false;
    var exclude_iridium = false;
    var exclude_holmium = false;
    var exclude_vitamelange = false;
    for (ordered_ri[0..ordered_n]) |ri| {
        const rn = resource_order[ri];
        if (!exclude_beryllium and !exclude_iridium and !exclude_holmium and !exclude_vitamelange) break; // all found, stop
        if (std.mem.eql(u8, rn, "se-beryllium-ore")) exclude_beryllium = true;
        if (std.mem.eql(u8, rn, "se-iridium-ore")) exclude_iridium = true;
        if (std.mem.eql(u8, rn, "se-holmium-ore")) exclude_holmium = true;
        if (std.mem.eql(u8, rn, "se-vitamelange")) exclude_vitamelange = true;
    }
    // Remove excluded ones from the ordered list (except the one that triggered the exclusion)
    var filtered_n: u32 = 0;
    var filtered_ri: [18]u32 = undefined;
    var found_excluder = false;
    for (ordered_ri[0..ordered_n]) |ri| {
        var keep = true;
        if (ri == @intFromEnum(data.Resource.se_beryllium_ore) or ri == @intFromEnum(data.Resource.se_iridium_ore) or
            ri == @intFromEnum(data.Resource.se_holmium_ore) or ri == @intFromEnum(data.Resource.se_vitamelange)) {
            if (!found_excluder) {
                found_excluder = true;
            } else {
                keep = false;
            }
        }
        if (keep) {
            filtered_ri[filtered_n] = ri;
            filtered_n += 1;
        }
    }

    // Category properties
    const is_field = zone_type == .@"asteroid-field";
    const freq_lo: f64 = if (is_field) 1 else 0.2;
    const freq_hi: f64 = if (is_field) 4 else 1;
    const size_lo: f64 = 0;
    const size_hi: f64 = if (is_field) 4 else 2;
    const rich_lo: f64 = 0.1;
    const rich_hi: f64 = if (is_field) 2 else 2;
    const norm: f64 = if (is_field) RESOURCE_NORM_FIELD else RESOURCE_NORM_PLANET;

    // Recompute primary position in filtered list
    primary_pos = -1;
    for (filtered_ri[0..filtered_n], 0..) |ri, pi| {
        if (primary_resource != null and std.mem.eql(u8, resource_order[ri], primary_resource.?)) {
            primary_pos = @intCast(pi);
            break;
        }
    }

    // Compute FSR using correct ordered_bias = (N - i) / N
    for (filtered_ri[0..filtered_n], 0..) |ri, pos| {
        const base_bias: f64 = if (pos == primary_pos) 1.0 else biases[ri];
        const ordered_bias: f64 = @as(f64, @floatFromInt(filtered_n - @as(u32, @intCast(pos)) - 1)) / @as(f64, @floatFromInt(filtered_n));

        var resource_value: f64 = RESOURCE_SECONDARY_IRREGULARITY * base_bias + (1.0 - RESOURCE_SECONDARY_IRREGULARITY) * ordered_bias;
        if (pos == primary_pos) {
            resource_value = 1.0 + RESOURCE_PRIMARY_BOOST;
        }
        resource_value = std.math.pow(f64, resource_value, RESOURCE_POWER);

        const freq = freq_lo + resource_value * (freq_hi - freq_lo);
        const size = size_lo + resource_value * (size_hi - size_lo);
        const richness = rich_lo + resource_value * (rich_hi - rich_lo);
        const fsr = freq * size * richness;
        controls[ri] = .{
            .present = true,
            .frequency = freq,
            .size = size,
            .richness = richness,
            .fsr_score = fsr / norm,
        };
    }

    return controls;
}

/// Zone.get_frequency_multiplier (SE scripts/zone.lua:544):
///   return zone.radius and 5000/zone.radius or 1
pub fn zoneFrequencyMultiplier(radius: f64) f64 {
    if (radius > 0) return 5000.0 / radius;
    return 1.0;
}

/// Port of Zone.apply_controls_to_mapgen (SE scripts/zone.lua:434), resource-
/// control branch only. This is the step between the zone's base controls
/// (`computeZoneResourceControls`, == zone.controls) and the surface's actual
/// `map_gen_settings.autoplace_controls`:
///   - on non-homeworld zones, multiply each resource's frequency by
///     Zone.get_frequency_multiplier (5000/radius). Resource controls are never
///     in `controls_without_frequency_multiplier` ({"trees","enemy-base"}), so
///     the multiplier always applies to them.
///   - clamp size and richness to >= 0 (set_autoplace_settings_for_space).
/// Mutates `controls` in place. Was the missing ~4.5x that starved spot count.
pub fn applyControlsToMapgen(controls: []ResourceControl, radius: f64, is_homeworld: bool) void {
    const fm = zoneFrequencyMultiplier(radius);
    for (controls) |*c| {
        if (!c.present) continue;
        if (!is_homeworld) c.frequency *= fm;
        c.size = @max(0.0, c.size);
        c.richness = @max(0.0, c.richness);
    }
}

/// Full pipeline: base zone controls -> surface map_gen_settings controls.
/// This is what a surface actually generates from; feed these to the ore engine.
pub fn computeZoneMapgenControls(
    zone_seed: u32,
    zone_type: data.ZoneType,
    primary_resource: ?[]const u8,
    tags: Tags,
    radius: f64,
    is_homeworld: bool,
) [18]ResourceControl {
    var controls = computeZoneResourceControls(zone_seed, zone_type, primary_resource, tags);
    applyControlsToMapgen(&controls, radius, is_homeworld);
    return controls;
}

/// Legacy: normalized FSR score per resource (indexed by `resource_order`).
/// Thin wrapper over `computeZoneResourceControls` for existing callers.
pub fn computeZoneResources(zone_seed: u32, zone_type: data.ZoneType, primary_resource: ?[]const u8, tags: Tags) [18]f64 {
    const controls = computeZoneResourceControls(zone_seed, zone_type, primary_resource, tags);
    var scores: [18]f64 = undefined;
    for (controls, 0..) |c, ri| scores[ri] = c.fsr_score;
    return scores;
}

const PrimaryCandidate = struct { ri: u32, name: []const u8, count: u32 };
const ZoneBiasInfo = struct {
    zi: usize,
    tags: Tags,
    biases: [18]f64,
    assigned_primary: ?[]const u8,
    assigned_special: bool,
};

/// Returns true if zone tags meet presence requirements for a special resource (strong claim).
fn hasStrongClaim(ri: u32, tags: Tags) bool {
    if (ri == @intFromEnum(data.Resource.se_cryonite)) {
        return tags.temperature != null and
            (tags.temperature.? == .extreme or tags.temperature.? == .cool or
             tags.temperature.? == .cold or tags.temperature.? == .vcold or
             tags.temperature.? == .frozen);
    }
    if (ri == @intFromEnum(data.Resource.se_vitamelange)) {
        return tags.moisture != null and
            (tags.moisture.? == .med or tags.moisture.? == .high or tags.moisture.? == .max);
    }
    if (ri == @intFromEnum(data.Resource.se_vulcanite)) {
        return tags.temperature != null and
            (tags.temperature.? == .extreme or tags.temperature.? == .warm or
             tags.temperature.? == .hot or tags.temperature.? == .vhot or
             tags.temperature.? == .volcanic);
    }
    if (ri == @intFromEnum(data.Resource.kr_mineral_water)) {
        return tags.water != null and
            (tags.water.? == .low or tags.water.? == .med or
             tags.water.? == .high or tags.water.? == .max);
    }
    return false;
}

/// Resolve primary resources for all planet/moon zones.
/// Returns a map from zone name to primary resource name.
/// Handles prototype primary, special types, and the claiming algorithm.
fn isPrimaryEligible(ri: u32, tags: Tags) bool {
    if (ri == @intFromEnum(data.Resource.se_cryonite)) {
        return tags.temperature != null and
            (tags.temperature.? == .vcold or tags.temperature.? == .frozen);
    }
    if (ri == @intFromEnum(data.Resource.se_vitamelange)) {
        return tags.moisture != null and
            (tags.moisture.? == .high or tags.moisture.? == .max);
    }
    if (ri == @intFromEnum(data.Resource.se_vulcanite)) {
        return tags.temperature != null and
            (tags.temperature.? == .vhot or tags.temperature.? == .volcanic);
    }
    if (ri == @intFromEnum(data.Resource.kr_mineral_water)) {
        return tags.water != null and
            (tags.water.? == .high or tags.water.? == .max);
    }
    return true;
}

/// Assign primary resources to ASTEROID FIELDS via SE's global quota (the
/// asteroid-field resource_balance_category). Fields carry no tags, so there are
/// no fixed/tag-gated primaries — every field is bias-ranked and each resource
/// gets a quota of ~N/K fields. Eligible field primaries (SE not_space +
/// not_asteroid_field rules): iron, copper, uranium, stone, naquium, methane-ice,
/// water-ice (coal/oil/vulcanite/cryonite/vitamelange/iridium/holmium excluded by
/// not_space; beryllium by not_asteroid_field; water-ice re-allowed). This
/// replaces the old null-primary bias ranking that over-labelled fields as
/// naquium-primary. Returns field name -> primary resource.
// SE universe-raw.lua space_zones: named asteroid fields with a HARDCODED
// primary_resource. build_resources (universe.lua:798-836) assigns these first —
// before the bias passes — so they fill quota and procedural fields spill to
// what's left. Without this, ~55% of field primaries are wrong (e.g. Galactic
// Graveyard resolves to naquium instead of the game's kr-rare-metal-ore, because
// the 6+ named naquium fields hadn't pre-filled naquium's quota). Verified 45/45
// against two live universes via an instrumented SE mod.
fn fieldFixedPrimary(name: []const u8) ?data.Resource {
    const eq = std.mem.eql;
    if (eq(u8, name, "Astral Snow") or eq(u8, name, "Hailstorm") or eq(u8, name, "Ice Field") or eq(u8, name, "Stardew")) return .se_water_ice;
    if (eq(u8, name, "Black Mirror") or eq(u8, name, "Dark Assemblage") or eq(u8, name, "Darkflare") or eq(u8, name, "Melancholia") or eq(u8, name, "Realm of Shadows") or eq(u8, name, "Sands of Time") or eq(u8, name, "Stardust")) return .se_naquium_ore;
    if (eq(u8, name, "Deadspace")) return .uranium_ore;
    if (eq(u8, name, "Ephemeral Expanse") or eq(u8, name, "Oblongglobulata") or eq(u8, name, "Solar Entrails")) return .se_methane_ice;
    if (eq(u8, name, "Razor Field")) return .iron_ore;
    return null;
}

pub fn resolveFieldPrimaries(alloc: std.mem.Allocator, zones: ArrayList(Zone), k2: bool) !std.StringHashMap([]const u8) {
    var map = std.StringHashMap([]const u8).init(alloc);
    // Field-eligible primaries in RESOURCE_ORDER order (SE not_space/not_asteroid_field
    // rules): iron,copper,uranium,stone,naquium,methane-ice,water-ice (+ kr-imersite,
    // kr-rare-metal-ore under K2). The remainder-quota distribution walks this order.
    var elig = ArrayList(u32).init(alloc);
    defer elig.deinit();
    const base_elig = [_]u32{
        @intFromEnum(data.Resource.iron_ore), @intFromEnum(data.Resource.copper_ore),
        @intFromEnum(data.Resource.uranium_ore), @intFromEnum(data.Resource.stone),
        @intFromEnum(data.Resource.se_naquium_ore), @intFromEnum(data.Resource.se_methane_ice),
        @intFromEnum(data.Resource.se_water_ice),
    };
    for (base_elig) |ri| try elig.append(ri);
    if (k2) {
        // kr-rare-metal-ore is a field-primary option; kr-imersite is NOT (verified
        // against the live game: 0 of 45 fields are imersite-primary, so K=8 not 9).
        // K2 excludes imersite from field primaries (no SE override — K2-side).
        try elig.append(@intFromEnum(data.Resource.kr_rare_metal_ore));
    }
    const K = elig.items.len;

    const FieldInfo = struct { zi: usize, ob: [18]f64, top: u32, fixed: ?u32 };
    var fields = ArrayList(FieldInfo).init(alloc);
    defer fields.deinit();
    for (zones.items, 0..) |z, zi| {
        if (z.ztype != .@"asteroid-field") continue;
        var rng = Rng.initFactorio(z.seed);
        var b: [18]f64 = undefined;
        for (0..18) |ri| b[ri] = rng.float();
        // ordered_bias per resource = 1 + (base_bias - rank1) / 18; global winner = argmax base_bias
        var ob: [18]f64 = undefined;
        var top: u32 = 0;
        for (0..18) |ri| {
            var pos1: u32 = 0;
            for (0..18) |r2| {
                if (b[r2] > b[ri]) pos1 += 1;
            }
            ob[ri] = 1.0 + (b[ri] - @as(f64, @floatFromInt(pos1 + 1))) / 18.0;
            if (b[ri] > b[top]) top = @intCast(ri);
        }
        // Hardcoded primary for named fields → its index into `elig` (k), else null.
        var fixed_k: ?u32 = null;
        if (fieldFixedPrimary(z.name)) |res| {
            const rri = @intFromEnum(res);
            for (elig.items, 0..) |eri, k| {
                if (eri == rri) {
                    fixed_k = @intCast(k);
                    break;
                }
            }
        }
        try fields.append(.{ .zi = zi, .ob = ob, .top = top, .fixed = fixed_k });
    }
    const N = fields.items.len;
    if (N == 0) return map;

    // quota per eligible resource (remainder → first `rem` eligibles in resource_order)
    var quota = try alloc.alloc(u32, K);
    defer alloc.free(quota);
    var used = try alloc.alloc(u32, K);
    defer alloc.free(used);
    @memset(used, 0);
    const per_min: u32 = @intCast(N / K);
    const rem: u32 = @intCast(N % K);
    for (0..K) |k| quota[k] = per_min + (if (k < rem) @as(u32, 1) else 0);

    var assigned = try alloc.alloc(bool, N);
    defer alloc.free(assigned);
    @memset(assigned, false);

    // Pre-pass (SE build_resources 798-836): assign the named fields' hardcoded
    // primaries first, filling quota.
    for (fields.items, 0..) |f, i| {
        if (f.fixed) |k| {
            assigned[i] = true;
            used[k] += 1;
            try map.put(zones.items[f.zi].name, resource_order[elig.items[k]]);
        }
    }
    // Quota-drop (SE 869-896): a resource pre-filled ABOVE quota (e.g. 7 named
    // naquium fields vs a quota of 6) sheds its lowest-ordered_bias fixed fields
    // back to the pool, where the bias passes reassign them.
    for (0..K) |k| {
        const ri = elig.items[k];
        while (used[k] > quota[k]) {
            var worst_i: ?usize = null;
            var worst_v: f64 = std.math.inf(f64);
            for (fields.items, 0..) |f, i| {
                if (assigned[i] and f.fixed != null and f.fixed.? == k and f.ob[ri] < worst_v) {
                    worst_v = f.ob[ri];
                    worst_i = i;
                }
            }
            if (worst_i) |i| {
                assigned[i] = false;
                used[k] -= 1;
                _ = map.remove(zones.items[fields.items[i].zi].name);
            } else break;
        }
    }

    // Phase 4 — bias winners: a field goes to resource R only if its GLOBAL #1
    // (over all resources) is R. Iterate eligible resources in resource_order,
    // sort winners by ordered_bias, assign up to quota.
    for (elig.items, 0..) |ri, k| {
        var members = ArrayList(usize).init(alloc);
        defer members.deinit();
        for (0..N) |i| {
            if (!assigned[i] and fields.items[i].top == ri) try members.append(i);
        }
        for (members.items, 0..) |_, a2| {
            var b2: usize = a2 + 1;
            while (b2 < members.items.len) : (b2 += 1) {
                if (fields.items[members.items[b2]].ob[ri] > fields.items[members.items[a2]].ob[ri]) {
                    const t = members.items[a2];
                    members.items[a2] = members.items[b2];
                    members.items[b2] = t;
                }
            }
        }
        for (members.items) |i| {
            if (used[k] >= quota[k]) break;
            assigned[i] = true;
            used[k] += 1;
            try map.put(zones.items[fields.items[i].zi].name, resource_order[ri]);
        }
    }

    // Phase 5 (SE universe.lua pass 5) — "assign resources in turns by highest
    // remaining bias". resources_lacking_zones = the eligible resources STILL
    // under quota after pass 4 (in resource_order), captured ONCE. Cycle the
    // pointer through THAT subset (not all K); each full cycle bumps max_zones.
    // Per turn: if the resource is still under quota and at/below max_zones, take
    // the unassigned field with the highest ordered_bias for it. Cycling all K
    // (the old bug) mis-times the max_zones bumps and changes every assignment.
    var lacking: ArrayList(u32) = ArrayList(u32).init(alloc); // indices into elig/used
    defer lacking.deinit();
    var max_zones: u32 = per_min + 1;
    for (0..K) |k| {
        if (used[k] < quota[k]) {
            try lacking.append(@intCast(k));
            if (used[k] < max_zones) max_zones = used[k];
        }
    }
    const L = lacking.items.len;
    if (L > 0) {
        var pointer: usize = 0;
        var remaining: usize = 0;
        for (0..N) |i| {
            if (!assigned[i]) remaining += 1;
        }
        var guard: usize = 0;
        while (remaining > 0 and max_zones <= per_min + 1 and guard < N * K + K + 4) : (guard += 1) {
            const k = lacking.items[pointer];
            const ri = elig.items[k];
            if (used[k] <= max_zones and used[k] < quota[k]) {
                var best_i: ?usize = null;
                var best_v: f64 = -1e30;
                for (0..N) |i| {
                    if (assigned[i]) continue;
                    if (best_i == null or fields.items[i].ob[ri] > best_v) {
                        best_v = fields.items[i].ob[ri];
                        best_i = i;
                    }
                }
                if (best_i) |i| {
                    assigned[i] = true;
                    used[k] += 1;
                    remaining -= 1;
                    try map.put(zones.items[fields.items[i].zi].name, resource_order[ri]);
                }
            }
            pointer += 1;
            if (pointer >= L) {
                pointer = 0;
                max_zones += 1;
            }
        }
    }
    return map;
}

pub fn resolvePrimaries(alloc: std.mem.Allocator, zones: ArrayList(Zone), bodyMap: std.StringHashMapUnmanaged(data.Body), k2: bool) !std.StringHashMap([]const u8) {
    var map = std.StringHashMap([]const u8).init(alloc);

    // Number of resource controls that EXIST. SE's ordered_bias
    // (universe.lua generate_zone_resource_bias) is `1 + (base_bias - i) / #res`,
    // where #res is the count of resources with autoplace controls. The three kr-*
    // resources are the LAST entries in `resource_order`, so vanilla (no K2) has
    // exactly the first 15; every bias-ranking, position count, and best-resource
    // selection below therefore iterates 0..N and divides by N — anything at index
    // >= N (the kr resources) is invisible in vanilla, matching the game.
    const N: usize = if (k2) resource_order.len else resource_order.len - 3;
    const Nf: f64 = @floatFromInt(N);

    // ---- Phase 0: Gather zone info ----
    var infos = ArrayList(ZoneBiasInfo).init(alloc);
    defer infos.deinit();

    for (zones.items, 0..) |z, zi| {
        if (z.ztype != .planet and z.ztype != .moon) continue;

        const tags = computeTags(z.seed, z.name, bodyMap);
        var bias_rng = Rng.initFactorio(z.seed);
        var biases: [18]f64 = undefined;
        for (0..18) |ri| { biases[ri] = bias_rng.float(); }

        var assigned_primary: ?[]const u8 = null;
        var assigned_special = false;

        if (std.mem.eql(u8, z.name, "Nauvis")) { assigned_primary = "stone"; }
        if (assigned_primary == null) {
            if (lookupBodyFast(bodyMap, z.name)) |p| {
                // A prototype primary that only exists under K2 (kr-*) is invalid in
                // vanilla; SE falls back to the normal assignment there (e.g. Xynariz
                // is kr-rare-metal-ore under K2 but a rolled resource in vanilla).
                if (p.primary_resource) |pr| {
                    if (k2 or !std.mem.startsWith(u8, pr, "kr-")) assigned_primary = pr;
                }
            }
        }
        if (assigned_primary == null) {
            if (std.mem.eql(u8, z.name, "Agni")) assigned_primary = "se-vulcanite";
            if (k2 and std.mem.eql(u8, z.name, "Koskomino")) { assigned_primary = "kr-imersite"; assigned_special = true; }
            if (std.mem.eql(u8, z.name, "Buttercup")) { assigned_primary = "se-vitamelange"; assigned_special = true; }
            if (std.mem.eql(u8, z.name, "Seker")) { assigned_primary = "se-iridium-ore"; assigned_special = true; }
            if (std.mem.eql(u8, z.name, "Shu")) { assigned_primary = "se-holmium-ore"; assigned_special = true; }
            if (std.mem.eql(u8, z.name, "Snowdrop")) { assigned_primary = "se-cryonite"; assigned_special = true; }
            if (std.mem.eql(u8, z.name, "Erebus")) assigned_primary = "crude-oil";
        }

        try infos.append(.{ .zi = zi, .tags = tags, .biases = biases,
            .assigned_primary = assigned_primary, .assigned_special = assigned_special });
    }

    // ---- Phase 1: Quotas ----
    // The eligible primary set = the resources that EXIST as autoplace controls.
    // The three kr-* resources only exist under Krastorio 2; in vanilla SE they
    // are absent, so they must NOT be options. Including them (opt_count 15 vs 12)
    // both mis-assigns kr resources AND shifts every quota (per_min = N/opt_count),
    // cascading wrong primaries across the whole universe.
    const base_primaries = [_]u32{
        @intFromEnum(data.Resource.iron_ore), @intFromEnum(data.Resource.copper_ore),
        @intFromEnum(data.Resource.uranium_ore), @intFromEnum(data.Resource.coal),
        @intFromEnum(data.Resource.crude_oil), @intFromEnum(data.Resource.stone),
        @intFromEnum(data.Resource.se_vulcanite), @intFromEnum(data.Resource.se_cryonite),
        @intFromEnum(data.Resource.se_vitamelange), @intFromEnum(data.Resource.se_beryllium_ore),
        @intFromEnum(data.Resource.se_iridium_ore), @intFromEnum(data.Resource.se_holmium_ore),
    };
    const kr_primaries = [_]u32{
        @intFromEnum(data.Resource.kr_imersite), @intFromEnum(data.Resource.kr_mineral_water),
        @intFromEnum(data.Resource.kr_rare_metal_ore),
    };
    var primary_options = ArrayList(PrimaryCandidate).init(alloc);
    defer primary_options.deinit();
    for (base_primaries) |ri| {
        try primary_options.append(.{ .ri = ri, .name = resource_order[ri], .count = 0 });
    }
    if (k2) {
        for (kr_primaries) |ri| {
            try primary_options.append(.{ .ri = ri, .name = resource_order[ri], .count = 0 });
        }
    }
    const normal_count = @as(u32, @intCast(infos.items.len));
    const opt_count = @as(u32, @intCast(primary_options.items.len));
    const per_min: u32 = if (opt_count > 0) normal_count / opt_count else 0;
    const rem: u32 = if (opt_count > 0) normal_count % opt_count else 0;
    for (primary_options.items, 0..) |*opt, oi| {
        opt.count = per_min + if (oi < rem) @as(u32, 1) else @as(u32, 0);
    }

    // ---- Phase 2: Fixed primaries ----
    var unassigned = ArrayList(usize).init(alloc);
    defer unassigned.deinit();
    for (infos.items, 0..) |*info, ii| {
        if (info.assigned_primary) |pr| {
            try map.put(zones.items[info.zi].name, pr);
            if (!info.assigned_special) {
                for (primary_options.items, 0..) |opt, opt_i| {
                    if (std.mem.eql(u8, opt.name, pr)) {
                        primary_options.items[opt_i].count -= 1;
                        break;
                    }
                }
            }
        } else { try unassigned.append(ii); }
    }

    // ---- Phase 3: Uncontested strong claims (ordered_bias sorted) ----
    var sc_per_resource = ArrayList(ArrayList(usize)).init(alloc);
    defer sc_per_resource.deinit();
    for (0..primary_options.items.len) |_| { try sc_per_resource.append(ArrayList(usize).init(alloc)); }
    var still_unassigned = ArrayList(usize).init(alloc);
    defer still_unassigned.deinit();

    for (unassigned.items) |ii| {
        const info = infos.items[ii];
        var count: u32 = 0;
        var matched_ri: ?u32 = null;
        inline for (.{ @intFromEnum(data.Resource.se_cryonite), @intFromEnum(data.Resource.se_vitamelange),
                       @intFromEnum(data.Resource.se_vulcanite), @intFromEnum(data.Resource.kr_mineral_water) }) |ri| {
            // kr-mineral-water is a strong-claim resource only under K2 (it doesn't
            // exist in vanilla), matching the eligible-set gate above.
            const kr_gate = k2 or ri != @intFromEnum(data.Resource.kr_mineral_water);
            if (kr_gate and isPrimaryEligible(@intCast(ri), info.tags)) { count += 1; matched_ri = ri; }
        }
        if (count == 1) {
            if (matched_ri) |ri| {
                for (primary_options.items, 0..) |opt, oi| {
                    if (opt.ri == ri) { try sc_per_resource.items[oi].append(ii); break; }
                }
            }
        } else { try still_unassigned.append(ii); }
    }

    // Sort per resource by ordered_bias, assign up to quota
    for (primary_options.items, 0..) |opt, oi| {
        var candidates = sc_per_resource.items[oi];
        if (candidates.items.len == 0) continue;
        const n: usize = candidates.items.len;
        var ob = try alloc.alloc(f64, n);
        defer alloc.free(ob);
        for (candidates.items, 0..) |ii, ci| {
            const info = infos.items[ii];
            var pos1: u32 = 0;
            for (0..N) |ri2| { if (info.biases[ri2] > info.biases[opt.ri]) pos1 += 1; }
            ob[ci] = 1.0 + (info.biases[opt.ri] - @as(f64, @floatFromInt(pos1 + 1))) / Nf;
        }
        var ci: usize = 0;
        while (ci < n) : (ci += 1) {
            var cj: usize = ci + 1;
            while (cj < n) : (cj += 1) {
                if (ob[cj] > ob[ci]) {
                    const t = candidates.items[ci]; candidates.items[ci] = candidates.items[cj]; candidates.items[cj] = t;
                    const tf = ob[ci]; ob[ci] = ob[cj]; ob[cj] = tf;
                }
            }
        }
        for (candidates.items) |ii| {
            if (primary_options.items[oi].count == 0) break;
            primary_options.items[oi].count -= 1;
            infos.items[ii].assigned_primary = opt.name;
            try map.put(zones.items[infos.items[ii].zi].name, opt.name);
        }
    }

    for (unassigned.items) |ii| {
        if (infos.items[ii].assigned_primary != null) continue;
        var was_sc = false;
        for (sc_per_resource.items) |scl| {
            for (scl.items) |si| { if (si == ii) { was_sc = true; break; } }
            if (was_sc) break;
        }
        if (was_sc) try still_unassigned.append(ii);
    }

    // ---- Phase 4: Bias winners using ordered_bias (SE formula) ----
    // ordered_bias = 1 + (base_bias - position_1indexed) / 18
    // This is what SE uses — coal at pos 4 beats stone at pos 5 even if stone has higher base_bias
    var bw_per_resource = ArrayList(ArrayList(usize)).init(alloc);
    defer bw_per_resource.deinit();
    for (0..primary_options.items.len) |_| {
        try bw_per_resource.append(ArrayList(usize).init(alloc));
    }

    for (still_unassigned.items) |ii| {
        const info = infos.items[ii];
        // Find resource with highest ordered_bias (SE: 1 + (base_bias - pos1) / 18)
        var best_ob: f64 = -999;
        var best_ri: usize = 0;
        for (0..N) |ri| {
            if (ri == @intFromEnum(data.Resource.se_naquium_ore) or
                ri == @intFromEnum(data.Resource.se_methane_ice) or
                ri == @intFromEnum(data.Resource.se_water_ice)) continue;
            if (!isPrimaryEligible(@intCast(ri), info.tags)) continue;
            var pos1: u32 = 0;
            for (0..N) |ri2| { if (info.biases[ri2] > info.biases[ri]) pos1 += 1; }
            const ob = 1.0 + (info.biases[ri] - @as(f64, @floatFromInt(pos1 + 1))) / Nf;
            if (ob > best_ob) { best_ob = ob; best_ri = ri; }
        }
        for (primary_options.items, 0..) |opt, oi| {
            if (opt.ri == best_ri) { try bw_per_resource.items[oi].append(ii); break; }
        }
    }

    // For each resource, sort zones by ordered_bias, assign up to quota
    for (primary_options.items, 0..) |opt, oi| {
        var candidates = bw_per_resource.items[oi];
        if (candidates.items.len == 0) continue;
        const n: usize = candidates.items.len;
        var ob = try alloc.alloc(f64, n);
        defer alloc.free(ob);
        for (candidates.items, 0..) |ii, ci| {
            const info = infos.items[ii];
            var pos1: u32 = 0;
            for (0..N) |ri2| { if (info.biases[ri2] > info.biases[opt.ri]) pos1 += 1; }
            ob[ci] = 1.0 + (info.biases[opt.ri] - @as(f64, @floatFromInt(pos1 + 1))) / Nf;
        }
        var ci: usize = 0;
        while (ci < n) : (ci += 1) {
            var cj: usize = ci + 1;
            while (cj < n) : (cj += 1) {
                if (ob[cj] > ob[ci]) {
                    const t = candidates.items[ci]; candidates.items[ci] = candidates.items[cj]; candidates.items[cj] = t;
                    const tf = ob[ci]; ob[ci] = ob[cj]; ob[cj] = tf;
                }
            }
        }
        for (candidates.items) |ii| {
            if (primary_options.items[oi].count == 0) break;
            primary_options.items[oi].count -= 1;
            infos.items[ii].assigned_primary = opt.name;
            try map.put(zones.items[infos.items[ii].zi].name, opt.name);
        }
    }

    // Remaining zones: greedy fallback by ordered_bias
    for (still_unassigned.items) |ii| {
        if (infos.items[ii].assigned_primary != null) continue;
        const info = infos.items[ii];
        var best_ob2: f64 = -999;
        var best_ri2: usize = 0;
        for (0..N) |ri| {
            if (ri == @intFromEnum(data.Resource.se_naquium_ore) or
                ri == @intFromEnum(data.Resource.se_methane_ice) or
                ri == @intFromEnum(data.Resource.se_water_ice)) continue;
            if (!isPrimaryEligible(@intCast(ri), info.tags)) continue;
            var pos1: u32 = 0;
            for (0..N) |ri2| { if (info.biases[ri2] > info.biases[ri]) pos1 += 1; }
            const ob = 1.0 + (info.biases[ri] - @as(f64, @floatFromInt(pos1 + 1))) / Nf;
            if (ob > best_ob2) { best_ob2 = ob; best_ri2 = ri; }
        }
        try map.put(zones.items[info.zi].name, resource_order[best_ri2]);
    }

    // ---- Phase 5: Final fallback ----
    for (infos.items) |info| {
        const zname = zones.items[info.zi].name;
        if (map.contains(zname)) continue;
        var sorted: [18]u32 = undefined;
        for (0..N) |ri| sorted[ri] = @intCast(ri);
        var si2: usize = 0;
        while (si2 < N) : (si2 += 1) {
            var sj2: usize = si2 + 1;
            while (sj2 < N) : (sj2 += 1) {
                if (info.biases[sorted[sj2]] > info.biases[sorted[si2]]) {
                    const t = sorted[si2]; sorted[si2] = sorted[sj2]; sorted[sj2] = t;
                }
            }
        }
        for (sorted[0..N]) |ri| {
            if (ri == @intFromEnum(data.Resource.se_naquium_ore) or
                ri == @intFromEnum(data.Resource.se_methane_ice) or
                ri == @intFromEnum(data.Resource.se_water_ice)) continue;
            if (!isPrimaryEligible(@intCast(ri), info.tags)) continue;
            try map.put(zname, resource_order[ri]);
            break;
        }
    }

    return map;
}

fn planetRadiusMult(z: Zone) f64 {
    if (std.mem.eql(u8, z.name, "Nauvis")) return 0.443462;
    if (z.radius == 2000.0) return 0.2;
    if (z.radius > 0) return z.radius / 10000.0;
    return 0.5;
}

fn parentNameForTailMoon(name: []const u8) []const u8 {
    if (std.mem.eql(u8, name, "Erebus")) return "Nauvis";
    if (std.mem.eql(u8, name, "Buttercup")) return "Snek";
    if (std.mem.eql(u8, name, "Koskomino")) return "Snek";
    if (std.mem.eql(u8, name, "Seker")) return "Ezra";
    if (std.mem.eql(u8, name, "Shu")) return "Ajax";
    if (std.mem.eql(u8, name, "Snowdrop")) return "Hecate";
    return "Nauvis";
}

/// Push a zone (by name) as the next ordered child, skipping empties, unknowns,
/// and duplicates. Used to assemble the Calidus star's child list in SE order.
fn calidusPush(out: *[128]usize, nk: *usize, byName: std.StringHashMapUnmanaged(u32), name: []const u8) void {
    if (name.len == 0) return;
    const zi = byName.get(name) orelse return;
    var j: usize = 0;
    while (j < nk.*) : (j += 1) {
        if (out[j] == zi) return;
    }
    if (nk.* < out.len) {
        out[nk.*] = zi;
        nk.* += 1;
    }
}

/// The Calidus star's children in SE's home-system order (universe-homesystem.lua
/// `star.children = {vulcanite, homeworld, vitamelange.parent, beryllium,
/// iridium.parent, holmium.parent, <remaining planets>, cryonite.parent, methane,
/// <remaining belts>}`). Returns the count written into `out`.
fn buildCalidusChildren(universe: *Universe, star_zi: usize, out: *[128]usize) usize {
    const zones = &universe.zones;
    const byName = universe.zoneByName;
    var nk: usize = 0;
    calidusPush(out, &nk, byName, universe.home_vulcanite);
    calidusPush(out, &nk, byName, "Nauvis");
    calidusPush(out, &nk, byName, universe.home_vitamelange_parent);
    calidusPush(out, &nk, byName, universe.home_beryllium_belt);
    calidusPush(out, &nk, byName, universe.home_iridium_parent);
    calidusPush(out, &nk, byName, universe.home_holmium_parent);
    // remaining planets (Calidus planet children not yet placed; cryonite.parent
    // is placed next, so hold it back here).
    for (zones.items) |z| {
        if (z.ztype != .planet or z.parent_index != @as(i32, @intCast(star_zi))) continue;
        if (std.mem.eql(u8, z.name, universe.home_cryonite_parent)) continue;
        calidusPush(out, &nk, byName, z.name);
    }
    calidusPush(out, &nk, byName, universe.home_cryonite_parent);
    calidusPush(out, &nk, byName, universe.home_methane_belt);
    // remaining belts (beryllium/methane already placed → deduped).
    for (zones.items) |z| {
        if (z.ztype != .@"asteroid-belt" or z.parent_index != @as(i32, @intCast(star_zi))) continue;
        calidusPush(out, &nk, byName, z.name);
    }
    return nk;
}

/// SE `planet_gravity_well_distribute`: planet.pgw = 10*(1+radius_multiplier) +
/// #children; each moon (1-based position m) gets pgw*(#children - m + 1)/(#children + 2)
/// and inherits the planet's star_gravity_well. Moon ORDER = special (Phase-6
/// tail) moons first — reversed, matching add_special_moon's insert-at-front —
/// then the Phase-5 moons in construction order.
fn distributePlanet(zones: *ArrayList(Zone), planet_zi: usize, tail_start: usize) void {
    var moons: [128]usize = undefined;
    var nm: usize = 0;
    const pidx: i32 = @intCast(planet_zi);
    var i: usize = zones.items.len;
    while (i > tail_start) {
        i -= 1;
        if (zones.items[i].ztype == .moon and zones.items[i].parent_index == pidx) {
            if (nm < moons.len) {
                moons[nm] = i;
                nm += 1;
            }
        }
    }
    for (0..tail_start) |zi| {
        if (zones.items[zi].ztype == .moon and zones.items[zi].parent_index == pidx) {
            if (nm < moons.len) {
                moons[nm] = zi;
                nm += 1;
            }
        }
    }
    const rm = zones.items[planet_zi].radius_multiplier;
    const pgw: f64 = 10.0 * (1.0 + rm) + @as(f64, @floatFromInt(nm));
    zones.items[planet_zi].planet_gravity_well = pgw;
    const nmf: f64 = @floatFromInt(nm);
    for (moons[0..nm], 0..) |moon_zi, mi| {
        const m1: f64 = @floatFromInt(mi + 1);
        const mult = (nmf - m1 + 1.0) / (nmf + 2.0);
        zones.items[moon_zi].planet_gravity_well = pgw * mult;
        zones.items[moon_zi].star_gravity_well = zones.items[planet_zi].star_gravity_well;
    }
}

/// Gravity wells over the ACTUAL body tree (SE universe.lua star_gravity_well_
/// distribute / planet_gravity_well_distribute). Each body's well depends on its
/// star's / planet's ordered child list — so we walk star → children → moons
/// using zone.parent_index and the Calidus home-system child ordering, rather
/// than any hard-coded per-seed layout. Delta-v is a pure function of these.
pub fn computeGravityWells(universe: *Universe) void {
    const zones = &universe.zones;
    const n = zones.items.len;

    // Phase-6 home-system special moons (add_special_moon = insert at front) sit
    // at/after the last asteroid-field; everything before is Phase-5.
    var tail_start: usize = n;
    {
        var ti = n;
        while (ti > 0) {
            ti -= 1;
            if (zones.items[ti].ztype == .@"asteroid-field") {
                tail_start = ti + 1;
                break;
            }
        }
    }
    const calidus_zi: i32 = if (universe.zoneByName.get("Calidus")) |v| @intCast(v) else -1;

    var star_zi: usize = 0;
    while (star_zi < n) : (star_zi += 1) {
        if (zones.items[star_zi].ztype != .star) continue;
        var kids: [128]usize = undefined;
        var nk: usize = 0;
        if (@as(i32, @intCast(star_zi)) == calidus_zi) {
            nk = buildCalidusChildren(universe, star_zi, &kids);
        } else {
            const sidx: i32 = @intCast(star_zi);
            for (zones.items, 0..) |z, zi| {
                if ((z.ztype == .planet or z.ztype == .@"asteroid-belt") and z.parent_index == sidx) {
                    if (nk < kids.len) {
                        kids[nk] = zi;
                        nk += 1;
                    }
                }
            }
        }
        // SE: star.sgw = 10 + #children + star.index/1000 (index is the 1-based
        // zone index). child.sgw = star.sgw * (0.05 + 0.8*(#children - c)/#children).
        const sgw: f64 = 10.0 + @as(f64, @floatFromInt(nk)) + @as(f64, @floatFromInt(star_zi + 1)) / 1000.0;
        zones.items[star_zi].star_gravity_well = sgw;
        const nkf: f64 = @floatFromInt(nk);
        for (kids[0..nk], 0..) |child_zi, ci| {
            const c1: f64 = @floatFromInt(ci + 1);
            const mult = 0.05 + 0.8 * (nkf - c1) / nkf;
            zones.items[child_zi].star_gravity_well = sgw * mult;
            if (zones.items[child_zi].ztype == .planet) {
                distributePlanet(zones, child_zi, tail_start);
            }
        }
    }
}

pub fn generateUniverse(alloc: std.mem.Allocator, seed: u32, k2_enabled: bool) !Universe {
    const a = alloc;
    var rng = Rng.initFactorio(seed);

    // ===== Phase 1: Constants =====
    const n_stars: f64 = @floatFromInt(data.stars.len);
    const total_bodies: f64 = @floatFromInt(data.unassigned_planets.len + data.unassigned_moons.len + data.unassigned_planets_or_moons.len);
    const app = total_bodies / (data.average_moons_per_planet + 1.0) / n_stars;
    const req_planets = rng.intRange(@intFromFloat(@floor(app * 0.9 * n_stars)), @intFromFloat(@ceil(app * 1.1 * n_stars)));
    const requested_moons: u32 = @as(u32, @intCast(data.unassigned_moons.len + data.unassigned_planets_or_moons.len)) - req_planets;
    const min_pps: u32 = @max(2, @as(u32, @intFromFloat(@floor(app / 2.0))));
    const high_pps: f64 = app * 1.5;
    const high_mpp: f64 = data.average_moons_per_planet * 1.5;

    // ===== Phase 2: Shuffles =====
    const moons = try a.dupe(Body, &data.unassigned_moons);
    const planets = try a.dupe(Body, &data.unassigned_planets);
    const pm_pool = try a.dupe(Body, &data.unassigned_planets_or_moons);

    shuffleBodies(&rng, moons);
    var star_order: [31]u32 = undefined; for (0..31) |i| star_order[i] = @intCast(i);
    shuffleSlice(u32, &rng, &star_order);
    shuffleBodies(&rng, planets);
    shuffleBodies(&rng, pm_pool);

    // ===== Phase 3: Planet assignment =====
    var star_planets: [31]ArrayList(Planet) = undefined;
    for (0..31) |i| star_planets[i] = ArrayList(Planet).init(a);
    var all_planet_names = ArrayList([]const u8).init(a);
    var all_planet_stars = ArrayList(u32).init(a);

    try star_planets[0].append(.{ .name = "Nauvis", .moons = ArrayList([]const u8).init(a) });
    try all_planet_names.append("Nauvis"); try all_planet_stars.append(0);

    // The `if (x == 0) continue` guards below are the degenerate draw from
    // Rng.int1. SE indexes `stars[0]` / `planets[0]` here, gets nil, and then
    // raises a Lua error when it dereferences it — unlike the tag case there is
    // no defined SE outcome to reproduce, so we skip the assignment and let
    // degen_draws flag the universe. See `degen_draws` above Rng.
    for (planets) |p| {
        const so = rng.int1(31);
        if (so == 0) continue;
        const si = star_order[so - 1];
        try star_planets[si].append(.{ .name = p.name, .moons = ArrayList([]const u8).init(a) });
        try all_planet_names.append(p.name); try all_planet_stars.append(si);
    }

    var pm_end: u32 = @intCast(pm_pool.len);
    for (star_order) |si| {
        while (star_planets[si].items.len < min_pps and pm_end > 0) {
            pm_end -= 1; const name = pm_pool[pm_end].name;
            try star_planets[si].append(.{ .name = name, .moons = ArrayList([]const u8).init(a) });
            try all_planet_names.append(name); try all_planet_stars.append(si);
        }
    }
    var pc: u32 = @intCast(all_planet_names.items.len);
    while (pc < req_planets and pm_end > 0) {
        const so = rng.int1(31);
        if (so == 0) continue;
        const si = star_order[so - 1];
        if (@as(f64, @floatFromInt(star_planets[si].items.len)) < high_pps or rng.float() < 0.25) {
            pm_end -= 1; const name = pm_pool[pm_end].name;
            try star_planets[si].append(.{ .name = name, .moons = ArrayList([]const u8).init(a) });
            try all_planet_names.append(name); try all_planet_stars.append(si);
            pc += 1;
        }
    }
    const total_planets: u32 = @intCast(all_planet_names.items.len);

    // ===== Phase 4: Moon assignment =====
    for (moons) |m| {
        const p1 = rng.int1(total_planets);
        if (p1 == 0) continue;
        const pi = p1 - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) { try p.moons.append(m.name); break; }
        }
    }

    var pm2_end: u32 = pm_end;
    for (all_planet_names.items, all_planet_stars.items) |pname, si| {
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) {
                if (@as(f64, @floatFromInt(p.moons.items.len)) < high_mpp and pm2_end > 0) {
                    pm2_end -= 1; try p.moons.append(pm_pool[pm2_end].name);
                }
                break;
            }
        }
    }
    sortByPriority(pm_pool[0..pm2_end]);
    var moon_total: u32 = 0;
    for (star_planets) |sp| { for (sp.items) |p| { moon_total += @intCast(p.moons.items.len); } }
    while (moon_total < requested_moons and pm2_end > 0) {
        const p1 = rng.int1(total_planets);
        if (p1 == 0) continue;
        const pi = p1 - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) {
                if (@as(f64, @floatFromInt(p.moons.items.len)) < high_mpp or rng.float() < 0.25) {
                    pm2_end -= 1; try p.moons.append(pm_pool[pm2_end].name); moon_total += 1;
                }
                break;
            }
        }
    }

    // ===== Phase 5: Zone construction =====
    var zones = ArrayList(Zone).init(a);
    var calidus_children = ArrayList([]const u8).init(a);
    var calidus_child_types = ArrayList(data.ZoneType).init(a);
    try zones.append(.{ .name = "Foenestra", .ztype = .anomaly });
    const scale = @sqrt(@as(f64, @floatFromInt(data.stars.len + data.space_zones.len))) * 50.0;

    for (star_order) |si| {
        const sname = data.stars[si];
        const is_calidus = std.mem.eql(u8, sname, "Calidus");

        const orientation = rng.float();
        const distance = rng.float() * scale * (if (is_calidus) @as(f64, 0.1) else 1.0);
        const sx: f64 = @cos(orientation * 2.0 * std.math.pi) * distance;
        const sy: f64 = @sin(orientation * 2.0 * std.math.pi) * distance;

        const star_zi: i32 = @intCast(zones.items.len);
        try zones.append(.{ .name = sname, .ztype = .star, .stellar_x = sx, .stellar_y = sy });
        const sorbit = try std.fmt.allocPrint(a, "{s} Orbit", .{sname});
        try zones.append(.{ .name = sorbit, .ztype = .orbit });

        const belts = rng.int1(data.max_asteroid_belts);
        const n_planets = star_planets[si].items.len;
        if (n_planets > 1) {
            shufflePlanets(&rng, star_planets[si].items);
        }

        var child_names = ArrayList([]const u8).init(a);
        var child_types = ArrayList(data.ZoneType).init(a);
        for (star_planets[si].items) |p| {
            try child_names.append(p.name);
            try child_types.append(.planet);
        }

        for (0..belts) |bi| {
            const belt_rng = rng.float();
            const lua_pos = @as(usize, @intFromFloat(@floor(0.4 + belt_rng + @as(f64, @floatFromInt(child_names.items.len)) * @as(f64, @floatFromInt(bi + 1)) / @as(f64, @floatFromInt(belts)))));
            const bn = try std.fmt.allocPrint(a, "{s} Asteroid Belt {d}", .{ sname, bi + 1 });
            try child_names.insert(lua_pos - 1, bn);
            try child_types.insert(lua_pos - 1, .@"asteroid-belt");
        }

        for (child_names.items, 0..) |cn, ci| {
            if (std.mem.eql(u8, cn, "Nauvis") and ci > 0) {
                const tn = child_names.items[0]; child_names.items[0] = child_names.items[ci]; child_names.items[ci] = tn;
                const tt = child_types.items[0]; child_types.items[0] = child_types.items[ci]; child_types.items[ci] = tt;
                break;
            }
        }

        var asteroid_belts: u32 = 0;
        for (child_names.items, child_types.items) |cn, ct| {
            if (ct == .@"asteroid-belt") {
                asteroid_belts += 1;
                const belt_name = try std.fmt.allocPrint(a, "{s} Asteroid Belt {d}", .{ sname, asteroid_belts });
                try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt", .parent_index = star_zi });
                if (is_calidus) { try calidus_children.append(belt_name); try calidus_child_types.append(.@"asteroid-belt"); }
            } else {
                const pradius = planetRadius(&rng, cn);
                const planet_zi: i32 = @intCast(zones.items.len);
                // radius_multiplier is the ROLLED value (radius/10000); Nauvis keeps
                // its rolled multiplier even though its radius is overwritten below.
                try zones.append(.{ .name = cn, .ztype = .planet, .radius = pradius, .parent_index = star_zi, .radius_multiplier = pradius / 10000.0 });
                if (is_calidus) { try calidus_children.append(cn); try calidus_child_types.append(.planet); }
                // Nauvis radius is overwritten with a constant in Lua, but AFTER moon radii use the RNG value
                const parent_r = pradius;
                if (std.mem.eql(u8, cn, "Nauvis")) zones.items[zones.items.len - 1].radius = 5691.73;
                const porbit = try std.fmt.allocPrint(a, "{s} Orbit", .{cn});
                try zones.append(.{ .name = porbit, .ztype = .orbit });
                for (star_planets[si].items) |p| {
                    if (std.mem.eql(u8, p.name, cn)) {
                        if (p.moons.items.len > 1) {
                            shuffleMoons(&rng, p.moons.items);
                        }
                        for (p.moons.items) |m| {
                            const mradius = moonRadius(&rng, parent_r, m);
                            try zones.append(.{ .name = m, .ztype = .moon, .radius = mradius, .parent_index = planet_zi });
                            const morbit = try std.fmt.allocPrint(a, "{s} Orbit", .{m});
                            try zones.append(.{ .name = morbit, .ztype = .orbit });
                        }
                        break;
                    }
                }
            }
        }
    }

    // Space zones
    const sz = try a.dupe([]const u8, &data.space_zones);
    if (sz.len > 1) { shuffleNames(&rng, sz); }
    const fields_start = zones.items.len;
    for (sz) |name| { try zones.append(.{ .name = name, .ztype = .@"asteroid-field" }); }
    // Record positions (same RNG calls as before, just capturing values)
    {
        var fi: usize = fields_start;
        while (fi < zones.items.len) : (fi += 1) {
            const forient = rng.float();
            const fdist = rng.float() * scale;
            zones.items[fi].stellar_x = @cos(forient * 2.0 * std.math.pi) * fdist;
            zones.items[fi].stellar_y = @sin(forient * 2.0 * std.math.pi) * fdist;
        }
    }

    // ===== Phase 5b: Assign seeds to all zones =====
    for (zones.items) |*z| {
        z.seed = rng.int1(4294967295);
    }

    // ===== Phase 6: Homesystem validation =====
    var available_planets = ArrayList([]const u8).init(a);
    var available_belts = ArrayList([]const u8).init(a);
    var calidus_all_non_homeworld = ArrayList([]const u8).init(a);
    const calidus_si = for (star_order) |s| {
        if (std.mem.eql(u8, data.stars[s], "Calidus")) break s;
    } else @as(u32, 0);
    for (star_planets[calidus_si].items) |p| {
        if (!std.mem.eql(u8, p.name, "Nauvis")) {
            try available_planets.append(p.name);
            try calidus_all_non_homeworld.append(p.name);
        }
    }
    const pre_belts = countBelts(zones, "Calidus");
    for (0..pre_belts) |i| {
        const bn = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{i + 1});
        try available_belts.append(bn);
    }
    const nauvis_radius: f64 = 5691.73; // constant in Lua

    // Home-system special-body roles + the Calidus star index (for the gravity-
    // well child ordering, see the Universe struct doc).
    const calidus_star_zi: i32 = zoneIndexInList(zones, "Calidus");
    const nauvis_zi_h: i32 = zoneIndexInList(zones, "Nauvis");
    var home_vulcanite: []const u8 = "";
    var home_vitamelange_parent: []const u8 = "";
    var home_iridium_parent: []const u8 = "";
    var home_holmium_parent: []const u8 = "";
    var home_cryonite_parent: []const u8 = "";
    var home_beryllium_belt: []const u8 = "";
    var home_methane_belt: []const u8 = "";

    // haven (add_special_moon on Nauvis)
    {
        const names = try a.alloc([]const u8, data.haven_moons_names.len);
        for (data.haven_moons_names, 0..) |n, idx| names[idx] = n;
        shuffleSlice([]const u8, &rng, names);
        const name = blk: {
            var result: ?[]const u8 = null;
            for (names) |n| {
                var used = false;
                for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
                if (!used) result = n;
            }
            break :blk result orelse @panic("no unused");
        };
        const mr: f64 = specialMoonRadius(nauvis_radius, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = nauvis_zi_h });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // vulcanite: planet with radius_multiplier = 0.2 from prototype
    {
        const name = try pickShuffledName(&rng, a, &data.vulcanite_planets_names, zones);
        home_vulcanite = name;
        try calidus_all_non_homeworld.insert(0, name);
        const vradius: f64 = 2000.0;
        try zones.append(.{ .name = name, .ztype = .planet, .seed = rng.int1(4294967295), .radius = vradius, .parent_index = calidus_star_zi, .radius_multiplier = 0.2 });
        try calidus_children.insert(0, name);
        try calidus_child_types.insert(0, .planet);
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // vitamelange: consume first available planet, add special moon to it
    {
        const planet_name = if (available_planets.items.len > 0) blk: {
            break :blk available_planets.orderedRemove(0);
        } else null;
        home_vitamelange_parent = planet_name orelse "Nauvis";
        const name = try pickShuffledName(&rng, a, &data.vitamelange_moons_names, zones);
        const parent_r: f64 = if (planet_name) |pn| findPlanetRadius(zones, pn) else nauvis_radius;
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = zoneIndexInList(zones, home_vitamelange_parent) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // iridium: use existing planet or make generic, then add special moon
    {
        const planet_name = if (available_planets.items.len > 0) blk: {
            break :blk available_planets.orderedRemove(0);
        } else blk: {
            const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
            for (data.unassigned_planets_or_moons, 0..) |b, i| pm_names[i] = b.name;
            shuffleNames(&rng, pm_names);
            const pn = blk2: {
                var result: ?[]const u8 = null;
                for (pm_names) |n| {
                    var u = false;
                    for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { u = true; break; } }
                    if (!u) result = n;
                }
                break :blk2 result orelse @panic("no unused");
            };
            const gpr = rng.float(); // radius
            const mult: f64 = lookupRadiusMultiplier(pn) orelse (0.4 + 0.6 * gpr * gpr);
            const gpr_radius: f64 = 10000.0 * mult;
            try calidus_all_non_homeworld.append(pn);
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius, .parent_index = calidus_star_zi, .radius_multiplier = mult });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        home_iridium_parent = planet_name;
        const name = try pickShuffledName(&rng, a, &data.iridium_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = zoneIndexInList(zones, planet_name) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // holmium
    {
        const planet_name = if (available_planets.items.len > 0) blk: {
            break :blk available_planets.orderedRemove(0);
        } else blk: {
            const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
            for (data.unassigned_planets_or_moons, 0..) |b, i| pm_names[i] = b.name;
            shuffleNames(&rng, pm_names);
            const pn = blk2: {
                var result: ?[]const u8 = null;
                for (pm_names) |n| {
                    var u = false;
                    for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { u = true; break; } }
                    if (!u) result = n;
                }
                break :blk2 result orelse @panic("no unused");
            };
            const gpr = rng.float(); // radius
            const mult: f64 = lookupRadiusMultiplier(pn) orelse (0.4 + 0.6 * gpr * gpr);
            const gpr_radius: f64 = 10000.0 * mult;
            try calidus_all_non_homeworld.append(pn);
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius, .parent_index = calidus_star_zi, .radius_multiplier = mult });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        home_holmium_parent = planet_name;
        const name = try pickShuffledName(&rng, a, &data.holmium_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = zoneIndexInList(zones, planet_name) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // cryonite
    {
        const planet_name = if (available_planets.items.len > 0) blk: {
            break :blk available_planets.orderedRemove(0);
        } else blk: {
            const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
            for (data.unassigned_planets_or_moons, 0..) |b, i| pm_names[i] = b.name;
            shuffleNames(&rng, pm_names);
            const pn = blk2: {
                var result: ?[]const u8 = null;
                for (pm_names) |n| {
                    var u = false;
                    for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { u = true; break; } }
                    if (!u) result = n;
                }
                break :blk2 result orelse @panic("no unused");
            };
            const gpr = rng.float(); // radius
            const mult: f64 = lookupRadiusMultiplier(pn) orelse (0.4 + 0.6 * gpr * gpr);
            const gpr_radius: f64 = 10000.0 * mult;
            try calidus_all_non_homeworld.append(pn);
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius, .parent_index = calidus_star_zi, .radius_multiplier = mult });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        home_cryonite_parent = planet_name;
        const name = try pickShuffledName(&rng, a, &data.cryonite_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = zoneIndexInList(zones, planet_name) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // beryllium
    {
        const used = if (available_belts.items.len > 0) blk: {
            home_beryllium_belt = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            home_beryllium_belt = belt_name;
            try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt", .seed = rng.int1(4294967295), .parent_index = calidus_star_zi });
            try calidus_children.append(belt_name); try calidus_child_types.append(.@"asteroid-belt");
        }
    }

    // methane
    {
        const used = if (available_belts.items.len > 0) blk: {
            home_methane_belt = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            home_methane_belt = belt_name;
            try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt", .seed = rng.int1(4294967295), .parent_index = calidus_star_zi });
            try calidus_children.append(belt_name); try calidus_child_types.append(.@"asteroid-belt");
        }
    }

    // kr-imersite (K2 only): add_special_moon_from_unassigned
    if (k2_enabled) {
        var imersite_parent: ?[]const u8 = null;
        if (available_planets.items.len > 0) {
            imersite_parent = available_planets.orderedRemove(0);
        } else {
            if (calidus_all_non_homeworld.items.len > 1) {
                shuffleNames(&rng, calidus_all_non_homeworld.items);
            }
            // Parent is the first Calidus non-homeworld planet after shuffle
            if (calidus_all_non_homeworld.items.len > 0) imersite_parent = calidus_all_non_homeworld.items[0];
        }

        const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
        for (data.unassigned_planets_or_moons, 0..) |b, idx| pm_names[idx] = b.name;
        shuffleNames(&rng, pm_names);
        const moon_name = blk: {
            for (pm_names) |n| {
                var used = false;
                for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
                if (!used) {
                    for (data.unassigned_planets_or_moons) |b| {
                        if (std.mem.eql(u8, b.name, n)) {
                            if (b.primary_resource == null) break :blk n;
                            break;
                        }
                    }
                }
            }
            @panic("no unused unassigned body without primary_resource");
        };
        const rng_mult: u32 = rng.intRange(80, 120);
        const parent_r: f64 = if (imersite_parent) |pn| findPlanetRadius(zones, pn) else nauvis_radius;
        const mr: f64 = specialMoonRadiusRng(parent_r, moon_name, rng_mult);
        try zones.append(.{ .name = moon_name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr, .parent_index = zoneIndexInList(zones, imersite_parent orelse "Nauvis") });
        const moon_orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{moon_name});
        try zones.append(.{ .name = moon_orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // ===== Phase 7: Vault loot =====
    var vault_rng = Rng.initFactorio(seed);

    // Count Calidus planets (non-Nauvis) — homesystem planets are tracked in calidus_all_non_homeworld
    const calidus_planet_count: u32 = @intCast(calidus_all_non_homeworld.items.len);

    // Vault loot bag logic from Ancient.get_next_vault_loot:
    // First loot: always P.  Bag starts as [E, S, P, E, S, P], P removed, then shuffled.
    // After 5 pulls, refill with [E, S, P, E, S, P] and shuffle.
    var loot_buf: [64]u8 = undefined;
    var loot_pos: usize = 0;

    if (calidus_planet_count > 0) {
        loot_buf[loot_pos] = 'P';
        loot_pos += 1;

        if (calidus_planet_count > 1) {
            // Initial bag: [E, S, P, E, S, P] minus last P = [E, S, P, E, S]
            var bag: [6]u8 = .{ 'E', 'S', 'P', 'E', 'S', 'P' };
            var bag_len: u32 = 5; // last P removed for first vault

            // Shuffle initial bag
            shuffleSlice(u8, &vault_rng, bag[0..bag_len]);

            var remaining: u32 = calidus_planet_count - 1;
            while (remaining > 0) : (remaining -= 1) {
                if (bag_len == 0) {
                    bag = .{ 'E', 'S', 'P', 'E', 'S', 'P' };
                    bag_len = 6;
                    shuffleSlice(u8, &vault_rng, bag[0..bag_len]);
                }
                bag_len -= 1;
                loot_buf[loot_pos] = bag[bag_len];
                loot_pos += 1;
            }
        }
    }

    const vault_loot = try a.dupe(u8, loot_buf[0..loot_pos]);

    // Build name→index map for O(1) zone lookups
    var zoneByName: std.StringHashMapUnmanaged(u32) = .{};
    for (zones.items, 0..) |_, zi| {
        try zoneByName.put(a, zones.items[zi].name, @intCast(zi));
    }

    return .{ .zones = zones, .zoneByName = zoneByName, .draws = rng.draw, .k2 = k2_enabled, .vault_loot = vault_loot, .calidus_children = calidus_children, .calidus_child_types = calidus_child_types, .home_vulcanite = home_vulcanite, .home_vitamelange_parent = home_vitamelange_parent, .home_iridium_parent = home_iridium_parent, .home_holmium_parent = home_holmium_parent, .home_cryonite_parent = home_cryonite_parent, .home_beryllium_belt = home_beryllium_belt, .home_methane_belt = home_methane_belt };
}

test "apply_controls_to_mapgen: Horaerratum controls match live game (hval)" {
    const std_t = @import("std");
    // Horaerratum: world 57374 moon, zone_seed 2035207183, radius 1041,
    // primary se-vitamelange. Tags from output/target-horaerratum.json.
    const tags = Tags{
        .temperature = .extreme,
        .water = .low,
        .moisture = .max,
        .trees = null,
        .aux = null,
        .cliff = null,
        .enemy = null,
    };
    const controls = computeZoneMapgenControls(2035207183, .moon, "se-vitamelange", tags, 1041.0, false);

    // Multiplier = 5000/1041 = 4.8031. Compare post-transform freq to the values
    // dumped from the live hval surface (calibration/mod-dump/hval-controls.json).
    const idx_vita = 8; // resource_order index of se-vitamelange
    const idx_iron = 0;
    std_t.debug.print("\n[controls] vitamelange freq={d:.4} (game 8.0234)  iron freq={d:.4} (game 3.7260)\n", .{ controls[idx_vita].frequency, controls[idx_iron].frequency });

    // Primary resource frequency is the well-established one; assert it matches.
    try std_t.testing.expect(@abs(controls[idx_vita].frequency - 8.0234) < 0.1);
}
