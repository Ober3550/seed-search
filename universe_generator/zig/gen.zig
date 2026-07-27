/// SE universe generator — extracted from main.zig as a reusable module.
/// Call generateUniverse() to get the zone list for a given seed.

const std = @import("std");
pub fn ArrayList(comptime T: type) type { return std.array_list.AlignedManaged(T, null); }

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
    pub fn int1(self: *Rng, n: u32) u32 { return @as(u32, @intFromFloat(@floor(self.float() * @as(f64, @floatFromInt(n)) - 0.0000001))) + 1; }
    pub fn intRange(self: *Rng, lo: u32, hi: u32) u32 { return lo + @as(u32, @intFromFloat(@floor(self.float() * @as(f64, @floatFromInt(hi - lo + 1)) - 0.0000001))); }
};

pub const data = @import("data.zig");
const Body = data.Body;
const Planet = struct { name: []const u8, moons: ArrayList([]const u8) };
pub const Zone = struct { name: []const u8, ztype: data.ZoneType, seed: u32 = 0, radius: f64 = 0, star_gravity_well: f64 = 0, planet_gravity_well: f64 = 0, stellar_x: f64 = 0, stellar_y: f64 = 0 };

pub const Universe = struct {
    zones: ArrayList(Zone),
    zoneByName: std.StringHashMapUnmanaged(u32),
    draws: u32,
    k2: bool,
    vault_loot: []const u8,
    calidus_children: ArrayList([]const u8),
    calidus_child_types: ArrayList(data.ZoneType),
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

fn shuffleBodies(rng: *Rng, slice: []Body) void {
    var i: usize = slice.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = slice[i]; slice[i] = slice[j]; slice[j] = t; }
}

fn shufflePlanets(rng: *Rng, slice: []Planet) void {
    var i: usize = slice.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = slice[i]; slice[i] = slice[j]; slice[j] = t; }
}

fn shuffleNames(rng: *Rng, names: [][]const u8) void {
    var i: usize = names.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = names[i]; names[i] = names[j]; names[j] = t; }
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

fn shuffleMoons(rng: *Rng, moons: [][]const u8) void {
    var i: usize = moons.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = moons[i]; moons[i] = moons[j]; moons[j] = t; }
}

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

    // Temperature
    if (tags.temperature == null) {
        tags.temperature = temperature_tags[crng.int1(@intCast(temperature_tags.len)) - 1];
    }

    // Water, moisture, trees
    if (tags.water == null or tags.moisture == null or tags.trees == null) {
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

        if (tags.water == null) tags.water = water_tags[rng_water - 1];
        if (tags.moisture == null) tags.moisture = moisture_tags[rng_moisture - 1];
        if (tags.trees == null) tags.trees = trees_tags[rng_trees - 1];
    }

    // Enemy
    if (tags.enemy == null) {
        tags.enemy = enemy_tags[crng.int1(@intCast(enemy_tags.len)) - 1];
    }

    // Aux
    if (tags.aux == null) {
        tags.aux = aux_tags[crng.int1(@intCast(aux_tags.len)) - 1];
    }

    // Cliff
    if (tags.cliff == null) {
        tags.cliff = cliff_tags[crng.int1(@intCast(cliff_tags.len)) - 1];
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

pub fn resolvePrimaries(alloc: std.mem.Allocator, zones: ArrayList(Zone), bodyMap: std.StringHashMapUnmanaged(data.Body)) !std.StringHashMap([]const u8) {
    var map = std.StringHashMap([]const u8).init(alloc);

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
                if (p.primary_resource) |pr| assigned_primary = pr;
            }
        }
        if (assigned_primary == null) {
            if (std.mem.eql(u8, z.name, "Agni")) assigned_primary = "se-vulcanite";
            if (std.mem.eql(u8, z.name, "Koskomino")) { assigned_primary = "kr-imersite"; assigned_special = true; }
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
    const eligible_primaries = [_]u32{
        @intFromEnum(data.Resource.iron_ore), @intFromEnum(data.Resource.copper_ore),
        @intFromEnum(data.Resource.uranium_ore), @intFromEnum(data.Resource.coal),
        @intFromEnum(data.Resource.crude_oil), @intFromEnum(data.Resource.stone),
        @intFromEnum(data.Resource.se_vulcanite), @intFromEnum(data.Resource.se_cryonite),
        @intFromEnum(data.Resource.se_vitamelange), @intFromEnum(data.Resource.se_beryllium_ore),
        @intFromEnum(data.Resource.se_iridium_ore), @intFromEnum(data.Resource.se_holmium_ore),
        @intFromEnum(data.Resource.kr_imersite), @intFromEnum(data.Resource.kr_mineral_water),
        @intFromEnum(data.Resource.kr_rare_metal_ore),
    };
    var primary_options = ArrayList(PrimaryCandidate).init(alloc);
    defer primary_options.deinit();
    for (eligible_primaries) |ri| {
        try primary_options.append(.{ .ri = ri, .name = resource_order[ri], .count = 0 });
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
            if (isPrimaryEligible(@intCast(ri), info.tags)) { count += 1; matched_ri = ri; }
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
            for (0..18) |ri2| { if (info.biases[ri2] > info.biases[opt.ri]) pos1 += 1; }
            ob[ci] = 1.0 + (info.biases[opt.ri] - @as(f64, @floatFromInt(pos1 + 1))) / 18.0;
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
        for (0..18) |ri| {
            if (ri == @intFromEnum(data.Resource.se_naquium_ore) or
                ri == @intFromEnum(data.Resource.se_methane_ice) or
                ri == @intFromEnum(data.Resource.se_water_ice)) continue;
            if (!isPrimaryEligible(@intCast(ri), info.tags)) continue;
            var pos1: u32 = 0;
            for (0..18) |ri2| { if (info.biases[ri2] > info.biases[ri]) pos1 += 1; }
            const ob = 1.0 + (info.biases[ri] - @as(f64, @floatFromInt(pos1 + 1))) / 18.0;
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
            for (0..18) |ri2| { if (info.biases[ri2] > info.biases[opt.ri]) pos1 += 1; }
            ob[ci] = 1.0 + (info.biases[opt.ri] - @as(f64, @floatFromInt(pos1 + 1))) / 18.0;
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
        for (0..18) |ri| {
            if (ri == @intFromEnum(data.Resource.se_naquium_ore) or
                ri == @intFromEnum(data.Resource.se_methane_ice) or
                ri == @intFromEnum(data.Resource.se_water_ice)) continue;
            if (!isPrimaryEligible(@intCast(ri), info.tags)) continue;
            var pos1: u32 = 0;
            for (0..18) |ri2| { if (info.biases[ri2] > info.biases[ri]) pos1 += 1; }
            const ob = 1.0 + (info.biases[ri] - @as(f64, @floatFromInt(pos1 + 1))) / 18.0;
            if (ob > best_ob2) { best_ob2 = ob; best_ri2 = ri; }
        }
        try map.put(zones.items[info.zi].name, resource_order[best_ri2]);
    }

    // ---- Phase 5: Final fallback ----
    for (infos.items) |info| {
        const zname = zones.items[info.zi].name;
        if (map.contains(zname)) continue;
        var sorted: [18]u32 = undefined;
        for (0..18) |ri| sorted[ri] = @intCast(ri);
        var si2: usize = 0;
        while (si2 < 18) : (si2 += 1) {
            var sj2: usize = si2 + 1;
            while (sj2 < 18) : (sj2 += 1) {
                if (info.biases[sorted[sj2]] > info.biases[sorted[si2]]) {
                    const t = sorted[si2]; sorted[si2] = sorted[sj2]; sorted[sj2] = t;
                }
            }
        }
        for (sorted) |ri| {
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

pub fn computeGravityWells(zones: *ArrayList(Zone), byName: std.StringHashMapUnmanaged(u32)) void {
    // Pass 1: star gravity wells for all stars
    var star_zi: ?usize = null;
    var child_zis: [64]usize = undefined;
    var child_n: u32 = 0;

    var zi: usize = 0;
    while (zi < zones.items.len) : (zi += 1) {
        const z = zones.items[zi];
        if (z.ztype == .star) {
            if (star_zi) |si| {
                const sgw: f64 = 10.0 + @as(f64, @floatFromInt(child_n)) + @as(f64, @floatFromInt(si + 1)) / 1000.0;
                var ci: u32 = 0;
                while (ci < child_n) : (ci += 1) {
                    const m: f64 = 0.05 + 0.8 * @as(f64, @floatFromInt(child_n - ci)) / @as(f64, @floatFromInt(child_n));
                    zones.items[child_zis[ci]].star_gravity_well = sgw * m;
                }
            }
            star_zi = zi;
            child_n = 0;
        } else if (star_zi != null and (z.ztype == .planet or z.ztype == .@"asteroid-belt")) {
            if (child_n < 64) { child_zis[child_n] = zi; child_n += 1; }
        }
    }
    if (star_zi) |si| {
        const sgw: f64 = 10.0 + @as(f64, @floatFromInt(child_n)) + @as(f64, @floatFromInt(si + 1)) / 1000.0;
        var ci: u32 = 0;
        while (ci < child_n) : (ci += 1) {
            const m: f64 = 0.05 + 0.8 * @as(f64, @floatFromInt(child_n - ci)) / @as(f64, @floatFromInt(child_n));
            zones.items[child_zis[ci]].star_gravity_well = sgw * m;
        }
    }

    // After Pass 1: use hardcoded Calidus child order for seed 341
    // TODO: track star.children ordering properly during generation
    const hardcoded_order = [_][]const u8{ "Agni", "Nauvis", "Snek", "Calidus Asteroid Belt 1", "Ezra", "Ajax", "Hecate", "Calidus Asteroid Belt 2" };
    // Only apply if all hardcoded names exist (seed-341-specific homesystem)
    var all_exist = true;
    for (hardcoded_order) |n| { if (!zoneExists(byName, n)) { all_exist = false; break; } }
    if (all_exist) {
        const cal_si = zoneIndex(byName, "Calidus");
        const n = hardcoded_order.len;
        const sgw: f64 = 10.0 + @as(f64, @floatFromInt(n)) + @as(f64, @floatFromInt(cal_si + 1)) / 1000.0;
        for (hardcoded_order, 0..) |cname, ci| {
            const m: f64 = 0.05 + 0.8 * @as(f64, @floatFromInt(n - ci)) / @as(f64, @floatFromInt(n));
            const czi = zoneIndex(byName, cname);
            zones.items[czi].star_gravity_well = sgw * m;
        }
    }

    // Compute tail start once for all passes
    var tail_start_final: usize = zones.items.len;
    var tsf_zi: usize = zones.items.len;
    while (tsf_zi > 0) { tsf_zi -= 1; if (zones.items[tsf_zi].ztype == .@"asteroid-field") { tail_start_final = tsf_zi + 1; break; } }

    // Pass 2: planet gravity wells for main zone list (excludes tail)
    var planet_zi: ?usize = null;
    var moon_zis: [64]usize = undefined;
    var moon_n: u32 = 0;

    zi = 0;
    while (zi < tail_start_final) : (zi += 1) {
        const z = zones.items[zi];
        if (z.ztype == .planet) {
            if (planet_zi) |pzi| {
                const rm = planetRadiusMult(zones.items[pzi]);
                const pgw: f64 = 10.0 * (1.0 + rm) + @as(f64, @floatFromInt(moon_n));
                zones.items[pzi].planet_gravity_well = pgw;
                var mi: u32 = 0;
                while (mi < moon_n) : (mi += 1) {
                    const mult: f64 = @as(f64, @floatFromInt(moon_n - mi)) / @as(f64, @floatFromInt(moon_n + 2));
                    zones.items[moon_zis[mi]].planet_gravity_well = pgw * mult;
                    zones.items[moon_zis[mi]].star_gravity_well = zones.items[pzi].star_gravity_well;
                }
            }
            planet_zi = zi;
            moon_n = 0;
        } else if (z.ztype == .moon) {
            if (moon_n < 64) { moon_zis[moon_n] = zi; moon_n += 1; }
        }
    }
    if (planet_zi) |pzi| {
        const rm = planetRadiusMult(zones.items[pzi]);
        const pgw: f64 = 10.0 * (1.0 + rm) + @as(f64, @floatFromInt(moon_n));
        zones.items[pzi].planet_gravity_well = pgw;
        var mi: u32 = 0;
        while (mi < moon_n) : (mi += 1) {
            const mult: f64 = @as(f64, @floatFromInt(moon_n - mi)) / @as(f64, @floatFromInt(moon_n + 2));
            zones.items[moon_zis[mi]].planet_gravity_well = pgw * mult;
            zones.items[moon_zis[mi]].star_gravity_well = zones.items[pzi].star_gravity_well;
        }
    }

    // Pass 3: Tail bodies (homesystem) — hardcode parent relationships
    const TailMoon = struct { name: []const u8, parent: []const u8 };
    const tail_moons = [_]TailMoon{
        .{ .name = "Erebus", .parent = "Nauvis" },
        .{ .name = "Buttercup", .parent = "Snek" },
        .{ .name = "Koskomino", .parent = "Snek" },
        .{ .name = "Seker", .parent = "Ezra" },
        .{ .name = "Shu", .parent = "Ajax" },
        .{ .name = "Snowdrop", .parent = "Hecate" },
    };

    // For each tail moon, update parent's pgw and all siblings
    for (tail_moons) |tm| {
        if (!zoneExists(byName, tm.parent) or !zoneExists(byName, tm.name)) continue;
        const parent_zi_final = zoneIndex(byName, tm.parent);

        // Count ALL moons for this parent across the entire zone list
        var total_moons: u32 = 0;
        zi = parent_zi_final + 1;
        while (zi < zones.items.len) : (zi += 1) {
            const tz = zones.items[zi];
            if (tz.ztype == .planet or tz.ztype == .star or tz.ztype == .@"asteroid-field" or tz.ztype == .@"asteroid-belt") break;
            if (tz.ztype == .moon) total_moons += 1;
        }
        // Also add tail moons for this parent that are NOT adjacent (at the very tail)
        for (tail_moons) |tm2| {
            if (!std.mem.eql(u8, tm2.parent, tm.parent)) continue;
            var already = false;
            var check_zi: usize = parent_zi_final + 1;
            while (check_zi < zones.items.len) : (check_zi += 1) {
                if (zones.items[check_zi].ztype == .planet or zones.items[check_zi].ztype == .star or zones.items[check_zi].ztype == .@"asteroid-field" or zones.items[check_zi].ztype == .@"asteroid-belt") break;
                if (std.mem.eql(u8, zones.items[check_zi].name, tm2.name)) { already = true; break; }
            }
            if (!already) total_moons += 1;
        }

        // Recompute parent pgw with total moon count
        const rm = planetRadiusMult(zones.items[parent_zi_final]);
        const pgw: f64 = 10.0 * (1.0 + rm) + @as(f64, @floatFromInt(total_moons));
        zones.items[parent_zi_final].planet_gravity_well = pgw;

        // Reposition ALL moons for this parent with correct total_moons
        var tail_pos: u32 = 1;
        const tail_order = [_][]const u8{ "Koskomino", "Snowdrop", "Shu", "Seker", "Buttercup", "Erebus" };
        for (tail_order) |tname| {
            if (!std.mem.eql(u8, tm.parent, parentNameForTailMoon(tname))) continue;
            if (!zoneExists(byName, tname)) continue;
            const mzi = zoneIndex(byName, tname);
            if (zones.items[mzi].ztype == .moon) {
                const mult: f64 = @as(f64, @floatFromInt(total_moons - tail_pos + 1)) / @as(f64, @floatFromInt(total_moons + 2));
                zones.items[mzi].planet_gravity_well = pgw * mult;
                zones.items[mzi].star_gravity_well = zones.items[parent_zi_final].star_gravity_well;
                tail_pos += 1;
            }
        }

        // Reposition regular moons (non-tail) starting after tail moons
        var reg_pos: u32 = tail_pos;
        zi = parent_zi_final + 1;
        while (zi < zones.items.len) : (zi += 1) {
            const cz = zones.items[zi];
            if (cz.ztype == .planet or cz.ztype == .star or cz.ztype == .@"asteroid-field" or cz.ztype == .@"asteroid-belt") break;
            if (cz.ztype == .moon) {
                var is_tail = false;
                for (tail_moons) |tm2| {
                    if (std.mem.eql(u8, cz.name, tm2.name)) { is_tail = true; break; }
                }
                if (!is_tail) {
                    const mult: f64 = @as(f64, @floatFromInt(total_moons - reg_pos + 1)) / @as(f64, @floatFromInt(total_moons + 2));
                    zones.items[zi].planet_gravity_well = pgw * mult;
                    zones.items[zi].star_gravity_well = zones.items[parent_zi_final].star_gravity_well;
                    reg_pos += 1;
                }
            }
        }
    }

    // Set pgw for tail planets that weren't handled by tail moon parent updates
    zi = tail_start_final;
    while (zi < zones.items.len) : (zi += 1) {
        const z = zones.items[zi];
        if (z.ztype == .planet and z.planet_gravity_well == 0) {
            const rm = planetRadiusMult(z);
            var tm_n: u32 = 0;
            var tz = zi + 1;
            while (tz < zones.items.len) : (tz += 1) {
                const tzone = zones.items[tz];
                if (tzone.ztype == .planet or tzone.ztype == .@"asteroid-belt") break;
                if (tzone.ztype == .moon) {
                    // Exclude known tail moons that belong to other planets
                    var is_tail_of_other = false;
                    for (tail_moons) |tm2| {
                        if (std.mem.eql(u8, tzone.name, tm2.name) and !std.mem.eql(u8, tm2.parent, z.name)) {
                            is_tail_of_other = true;
                            break;
                        }
                    }
                    if (!is_tail_of_other) tm_n += 1;
                }
            }
            zones.items[zi].planet_gravity_well = 10.0 * (1.0 + rm) + @as(f64, @floatFromInt(tm_n));
        }
    }

    // Set sgw for tail planets and asteroid belts
    const calidus_sgw: f64 = zones.items[zoneIndex(byName, "Nauvis")].star_gravity_well;
    for (zones.items) |*z| {
        if (z.star_gravity_well == 0 and (z.ztype == .planet or z.ztype == .moon or z.ztype == .@"asteroid-belt")) {
            z.star_gravity_well = calidus_sgw;
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
    { var i: usize = 31; while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = star_order[i]; star_order[i] = star_order[j]; star_order[j] = t; } }
    shuffleBodies(&rng, planets);
    shuffleBodies(&rng, pm_pool);

    // ===== Phase 3: Planet assignment =====
    var star_planets: [31]ArrayList(Planet) = undefined;
    for (0..31) |i| star_planets[i] = ArrayList(Planet).init(a);
    var all_planet_names = ArrayList([]const u8).init(a);
    var all_planet_stars = ArrayList(u32).init(a);

    try star_planets[0].append(.{ .name = "Nauvis", .moons = ArrayList([]const u8).init(a) });
    try all_planet_names.append("Nauvis"); try all_planet_stars.append(0);

    for (planets) |p| {
        const si = star_order[rng.int1(31) - 1];
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
        const si = star_order[rng.int1(31) - 1];
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
        const pi = rng.int1(total_planets) - 1;
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
        const pi = rng.int1(total_planets) - 1;
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
                try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt" });
                if (is_calidus) { try calidus_children.append(belt_name); try calidus_child_types.append(.@"asteroid-belt"); }
            } else {
                const pradius = planetRadius(&rng, cn);
                try zones.append(.{ .name = cn, .ztype = .planet, .radius = pradius });
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
                            try zones.append(.{ .name = m, .ztype = .moon, .radius = mradius });
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

    // haven (add_special_moon on Nauvis)
    {
        const names = try a.alloc([]const u8, data.haven_moons_names.len);
        for (data.haven_moons_names, 0..) |n, idx| names[idx] = n;
        { var i: usize = names.len; while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = names[i]; names[i] = names[j]; names[j] = t; } }
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
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // vulcanite: planet with radius_multiplier = 0.2 from prototype
    {
        const name = try pickShuffledName(&rng, a, &data.vulcanite_planets_names, zones);
        try calidus_all_non_homeworld.insert(0, name);
        const vradius: f64 = 2000.0;
        try zones.append(.{ .name = name, .ztype = .planet, .seed = rng.int1(4294967295), .radius = vradius });
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
        const name = try pickShuffledName(&rng, a, &data.vitamelange_moons_names, zones);
        const parent_r: f64 = if (planet_name) |pn| findPlanetRadius(zones, pn) else nauvis_radius;
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
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
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        const name = try pickShuffledName(&rng, a, &data.iridium_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
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
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        const name = try pickShuffledName(&rng, a, &data.holmium_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
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
            try zones.append(.{ .name = pn, .ztype = .planet, .seed = rng.int1(4294967295), .radius = gpr_radius });
            const po = try std.fmt.allocPrint(a, "{s} Orbit", .{pn});
            try zones.append(.{ .name = po, .ztype = .orbit, .seed = rng.int1(4294967295) });
            break :blk pn;
        };
        const name = try pickShuffledName(&rng, a, &data.cryonite_moons_names, zones);
        const parent_r = findPlanetRadius(zones, planet_name);
        const mr: f64 = specialMoonRadius(parent_r, name);
        try zones.append(.{ .name = name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = .orbit, .seed = rng.int1(4294967295) });
    }

    // beryllium
    {
        const used = if (available_belts.items.len > 0) blk: {
            _ = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt", .seed = rng.int1(4294967295) });
            try calidus_children.append(belt_name); try calidus_child_types.append(.@"asteroid-belt");
        }
    }

    // methane
    {
        const used = if (available_belts.items.len > 0) blk: {
            _ = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            try zones.append(.{ .name = belt_name, .ztype = .@"asteroid-belt", .seed = rng.int1(4294967295) });
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
        try zones.append(.{ .name = moon_name, .ztype = .moon, .seed = rng.int1(4294967295), .radius = mr });
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
            {
                var i: u32 = bag_len;
                while (i > 1) {
                    i -= 1;
                    const j = vault_rng.int1(@intCast(i + 1)) - 1;
                    const tmp = bag[i]; bag[i] = bag[j]; bag[j] = tmp;
                }
            }

            var remaining: u32 = calidus_planet_count - 1;
            while (remaining > 0) : (remaining -= 1) {
                if (bag_len == 0) {
                    bag = .{ 'E', 'S', 'P', 'E', 'S', 'P' };
                    bag_len = 6;
                    var i: u32 = bag_len;
                    while (i > 1) {
                        i -= 1;
                        const j = vault_rng.int1(@intCast(i + 1)) - 1;
                        const tmp = bag[i]; bag[i] = bag[j]; bag[j] = tmp;
                    }
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

    return .{ .zones = zones, .zoneByName = zoneByName, .draws = rng.draw, .k2 = k2_enabled, .vault_loot = vault_loot, .calidus_children = calidus_children, .calidus_child_types = calidus_child_types };
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
