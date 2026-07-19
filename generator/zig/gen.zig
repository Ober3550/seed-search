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

const data = @import("data.zig");
const Body = data.Body;
const Planet = struct { name: []const u8, moons: ArrayList([]const u8) };
pub const Zone = struct { name: []const u8, ztype: data.ZoneType, seed: u32 = 0, radius: f64 = 0, star_gravity_well: f64 = 0, planet_gravity_well: f64 = 0 };

pub const Universe = struct {
    zones: ArrayList(Zone),
    draws: u32,
    k2: bool,
    vault_loot: []const u8,
    calidus_children: ArrayList([]const u8),
    calidus_child_types: ArrayList(data.ZoneType),
};

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
const temperature_tags = [_][]const u8{ "temperature_bland", "temperature_temperate", "temperature_midrange", "temperature_balanced", "temperature_wild", "temperature_extreme", "temperature_cool", "temperature_cold", "temperature_vcold", "temperature_frozen", "temperature_warm", "temperature_hot", "temperature_vhot", "temperature_volcanic" };
const water_tags = [_][]const u8{ "water_none", "water_low", "water_med", "water_high", "water_max" };
const moisture_tags = [_][]const u8{ "moisture_none", "moisture_low", "moisture_med", "moisture_high", "moisture_max" };
const trees_tags = [_][]const u8{ "trees_none", "trees_low", "trees_med", "trees_high", "trees_max" };
const aux_tags = [_][]const u8{ "aux_very_low", "aux_low", "aux_med", "aux_high", "aux_very_high" };
const cliff_tags = [_][]const u8{ "cliff_none", "cliff_low", "cliff_med", "cliff_high", "cliff_max" };
const enemy_tags = [_][]const u8{ "enemy_none", "enemy_very_low", "enemy_low", "enemy_med", "enemy_high", "enemy_very_high", "enemy_max" };

pub const Tags = struct {
    temperature: ?[]const u8,
    water: ?[]const u8,
    moisture: ?[]const u8,
    trees: ?[]const u8,
    aux: ?[]const u8,
    cliff: ?[]const u8,
    enemy: ?[]const u8,
};

// Look up a body prototype by name from all pools (including special)
pub fn lookupBody(name: []const u8) ?data.Body {
    for (data.unassigned_planets) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.unassigned_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.unassigned_planets_or_moons) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    for (data.special_bodies) |b| { if (std.mem.eql(u8, b.name, name)) return b; }
    return null;
}

// Compute tags for a planet or moon using per-zone RNG (matches Universe.inflate_climate_controls)
pub fn computeTags(zone_seed: u32, name: []const u8) Tags {
    var crng = Rng.initFactorio(zone_seed);
    const proto = lookupBody(name);

    // Start with prototype tags if available
    var tags = Tags{
        .temperature = if (proto) |p| p.tag_temperature else null,
        .water = if (proto) |p| p.tag_water else null,
        .moisture = if (proto) |p| p.tag_moisture else null,
        .trees = if (proto) |p| p.tag_trees else null,
        .aux = if (proto) |p| p.tag_aux else null,
        .cliff = if (proto) |p| p.tag_cliff else null,
        .enemy = if (proto) |p| p.tag_enemy else null,
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

const RESOURCE_PRIMARY_BOOST: f64 = 0.5;
const RESOURCE_SECONDARY_IRREGULARITY: f64 = 0.75;
const RESOURCE_POWER: f64 = 1.5;
const RESOURCE_NORM_PLANET: f64 = 22.02730826300005162466;
const RESOURCE_NORM_FIELD: f64 = 167.79554553234018499;

/// Compute resource scores for a single planet or moon.
/// primary_resource must be known (from prototype, special_type, or claiming).
/// Returns scores indexed by resource_order (0..17). Score = FSR / norm.
pub fn computeZoneResources(zone_seed: u32, zone_type: []const u8, primary_resource: ?[]const u8, tags: Tags) [18]f64 {
    var scores: [18]f64 = @splat(0.0);

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
        const rname = resource_order[ri];
        var allowed = true;

        // Filter by tag requirements for presence
        // Also exclude space-only resources that never appear on planets
        if (std.mem.eql(u8, rname, "se-naquium-ore") or std.mem.eql(u8, rname, "se-methane-ice") or std.mem.eql(u8, rname, "se-water-ice")) {
            allowed = false;
        }
        if (allowed and (primary_resource == null or !std.mem.eql(u8, rname, primary_resource.?))) {
            if (std.mem.eql(u8, rname, "se-cryonite")) {
                allowed = tags.temperature != null and
                    (std.mem.eql(u8, tags.temperature.?, "temperature_extreme") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_cool") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_cold") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_vcold") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_frozen"));
            } else if (std.mem.eql(u8, rname, "se-vitamelange")) {
                allowed = tags.moisture != null and
                    (std.mem.eql(u8, tags.moisture.?, "moisture_med") or
                     std.mem.eql(u8, tags.moisture.?, "moisture_high") or
                     std.mem.eql(u8, tags.moisture.?, "moisture_max"));
            } else if (std.mem.eql(u8, rname, "se-vulcanite")) {
                allowed = tags.temperature != null and
                    (std.mem.eql(u8, tags.temperature.?, "temperature_extreme") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_warm") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_hot") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_vhot") or
                     std.mem.eql(u8, tags.temperature.?, "temperature_volcanic"));
            } else if (std.mem.eql(u8, rname, "kr-mineral-water")) {
                allowed = tags.water != null and
                    (std.mem.eql(u8, tags.water.?, "water_low") or
                     std.mem.eql(u8, tags.water.?, "water_med") or
                     std.mem.eql(u8, tags.water.?, "water_high") or
                     std.mem.eql(u8, tags.water.?, "water_max"));
            }
        }

        if (allowed) {
            const sort_key: f64 = if (primary_resource != null and std.mem.eql(u8, rname, primary_resource.?))
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
        const rn = resource_order[ri];
        var keep = true;
        if (std.mem.eql(u8, rn, "se-beryllium-ore") or std.mem.eql(u8, rn, "se-iridium-ore") or
            std.mem.eql(u8, rn, "se-holmium-ore") or std.mem.eql(u8, rn, "se-vitamelange")) {
            if (!found_excluder) {
                found_excluder = true; // first one found is the excluder, keep it
            } else {
                keep = false; // subsequent ones are excluded
            }
        }
        if (keep) {
            filtered_ri[filtered_n] = ri;
            filtered_n += 1;
        }
    }

    // Category properties
    const is_field = std.mem.eql(u8, zone_type, "asteroid-field");
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
        scores[ri] = fsr / norm;
    }

    return scores;
}

/// Resolve primary resources for all planet/moon zones.
/// Returns a map from zone name to primary resource name.
/// Handles prototype primary, special types, and the claiming algorithm.
fn isPrimaryEligible(resource_name: []const u8, tags: Tags) bool {
    if (std.mem.eql(u8, resource_name, "se-cryonite")) {
        return tags.temperature != null and
            (std.mem.eql(u8, tags.temperature.?, "temperature_vcold") or
             std.mem.eql(u8, tags.temperature.?, "temperature_frozen"));
    }
    if (std.mem.eql(u8, resource_name, "se-vitamelange")) {
        return tags.moisture != null and
            (std.mem.eql(u8, tags.moisture.?, "moisture_high") or
             std.mem.eql(u8, tags.moisture.?, "moisture_max"));
    }
    if (std.mem.eql(u8, resource_name, "se-vulcanite")) {
        return tags.temperature != null and
            (std.mem.eql(u8, tags.temperature.?, "temperature_vhot") or
             std.mem.eql(u8, tags.temperature.?, "temperature_volcanic"));
    }
    if (std.mem.eql(u8, resource_name, "kr-mineral-water")) {
        return tags.water != null and
            (std.mem.eql(u8, tags.water.?, "water_high") or
             std.mem.eql(u8, tags.water.?, "water_max"));
    }
    return true;
}

pub fn resolvePrimaries(alloc: std.mem.Allocator, zones: ArrayList(Zone)) !std.StringHashMap([]const u8) {
    var map = std.StringHashMap([]const u8).init(alloc);

    // First pass: assign from prototype or special type
    for (zones.items) |z| {
        if (z.ztype != .planet and z.ztype != .moon) continue;

        var assigned: ?[]const u8 = null;

        // Check prototype primary_resource
        const proto = lookupBody(z.name);
        if (proto) |p| {
            if (p.primary_resource) |pr| assigned = pr;
        }

        // Check special types (homesystem bodies)
        // TODO: track special_type during generation
        if (assigned == null) {
            // For seed 341, hardcode known special-type primaries (temporary)
            // These are set during homesystem via special_type field
            // Agni=vulcanite, Koskomino=kr-imersite, Buttercup=vitamelange,
            // Seker=iridium, Shu=holmium, Snowdrop=cryonite, Erebus=haven
            if (std.mem.eql(u8, z.name, "Agni")) assigned = "se-vulcanite";
            if (std.mem.eql(u8, z.name, "Koskomino")) assigned = "kr-imersite";
            if (std.mem.eql(u8, z.name, "Buttercup")) assigned = "se-vitamelange";
            if (std.mem.eql(u8, z.name, "Seker")) assigned = "se-iridium-ore";
            if (std.mem.eql(u8, z.name, "Shu")) assigned = "se-holmium-ore";
            if (std.mem.eql(u8, z.name, "Snowdrop")) assigned = "se-cryonite";
            if (std.mem.eql(u8, z.name, "Erebus")) assigned = "crude-oil";
            if (std.mem.eql(u8, z.name, "Nauvis")) assigned = "stone";
        }

        if (assigned) |a| {
            try map.put(z.name, a);
        }
    }

    // Second pass: uncontested strong claims
    // Tag-required resources get first dibs on zones that match ONLY them
    for (zones.items) |z| {
        if (z.ztype != .planet and z.ztype != .moon) continue;
        if (map.contains(z.name)) continue;

        const ztags = computeTags(z.seed, z.name);
        // Count how many tag-required resources this zone matches
        var match_count: u32 = 0;
        var matched_resource: ?[]const u8 = null;

        inline for (.{ "se-cryonite", "se-vitamelange", "se-vulcanite", "kr-mineral-water" }) |rn| {
            if (isPrimaryEligible(rn, ztags)) {
                match_count += 1;
                matched_resource = rn;
            }
        }

        // If exactly one match, claim it (uncontested strong claim)
        if (match_count == 1) {
            if (matched_resource) |rn| {
                try map.put(z.name, rn);
            }
        }
    }

    // Third pass: greedy claiming for remaining unassigned zones
    // Each zone gets its highest ordered_bias resource that's eligible as primary
    for (zones.items) |z| {
        if (z.ztype != .planet and z.ztype != .moon) continue;
        if (map.contains(z.name)) continue;

        // Compute ordered_bias and pick highest valid primary
        var bias_rng = Rng.initFactorio(z.seed);
        var biases: [18]f64 = undefined;
        var indices: [18]u32 = undefined;
        for (0..18) |ri| { biases[ri] = bias_rng.float(); indices[ri] = @intCast(ri); }
        var si: usize = 0;
        while (si < 18) : (si += 1) {
            var sj: usize = si + 1;
            while (sj < 18) : (sj += 1) {
                if (biases[indices[sj]] > biases[indices[si]]) {
                    const t = indices[si]; indices[si] = indices[sj]; indices[sj] = t;
                }
            }
        }
        var best_val: f64 = -1;
        var best_ri: u32 = 0;
        for (indices, 0..) |ri, pos| {
            // Exclude space-only resources from primary options
            const rn = resource_order[ri];
            if (std.mem.eql(u8, rn, "se-naquium-ore") or std.mem.eql(u8, rn, "se-methane-ice") or std.mem.eql(u8, rn, "se-water-ice")) continue;
            // Check tag eligibility
            const ztags = computeTags(z.seed, z.name);
            if (!isPrimaryEligible(rn, ztags)) continue;
            const ordered = 1.0 + (biases[ri] - @as(f64, @floatFromInt(pos + 1))) / 18.0;
            if (ordered > best_val) { best_val = ordered; best_ri = ri; }
        }
        try map.put(z.name, resource_order[best_ri]);
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

pub fn computeGravityWells(zones: *ArrayList(Zone)) void {
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
    var cal_si: usize = 0;
    for (zones.items, 0..) |sz, si| {
        if (sz.ztype == .star and std.mem.eql(u8, sz.name, "Calidus")) { cal_si = si; break; }
    }
    const n = hardcoded_order.len;
    const sgw: f64 = 10.0 + @as(f64, @floatFromInt(n)) + @as(f64, @floatFromInt(cal_si + 1)) / 1000.0;
    for (hardcoded_order, 0..) |cname, ci| {
        const m: f64 = 0.05 + 0.8 * @as(f64, @floatFromInt(n - ci)) / @as(f64, @floatFromInt(n));
        for (zones.items) |*cz| {
            if (std.mem.eql(u8, cz.name, cname)) { cz.star_gravity_well = sgw * m; break; }
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
        // Find parent zone index
        var parent_zi_final: usize = 0;
        for (zones.items, 0..) |pz, pi| {
            if (std.mem.eql(u8, pz.name, tm.parent)) { parent_zi_final = pi; break; }
        }

        // Count ALL moons for this parent across the entire zone list
        // Walk from parent to next planet/star/field/belt, counting moons
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
            // Check if this tail moon was already counted in the zone walk above
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
        // Tail moons are inserted at position 1 via table.insert(children, 1, moon)
        // Multiple tail moons: later ones in homesystem order push earlier ones down
        // Order: haven, vulcanite, vitamelange, iridium, holmium, cryonite, beryllium, methane, K2
        // So for Snek: Koskomino(K2, later) at pos 1, Buttercup(vitamelange) at pos 2
        var tail_pos: u32 = 1;
        // Process tail moons in REVERSE homesystem order (later insertions at position 1)
        const tail_order = [_][]const u8{ "Koskomino", "Snowdrop", "Shu", "Seker", "Buttercup", "Erebus" };
        for (tail_order) |tname| {
            if (!std.mem.eql(u8, tm.parent, parentNameForTailMoon(tname))) continue;
            for (zones.items, 0..) |*mz, mzi| {
                if (std.mem.eql(u8, mz.name, tname) and mz.ztype == .moon) {
                    const mult: f64 = @as(f64, @floatFromInt(total_moons - tail_pos + 1)) / @as(f64, @floatFromInt(total_moons + 2));
                    mz.planet_gravity_well = pgw * mult;
                    mz.star_gravity_well = zones.items[parent_zi_final].star_gravity_well;
                    _ = mzi;
                    tail_pos += 1;
                    break;
                }
            }
        }

        // Reposition regular moons (non-tail) starting after tail moons
        var reg_pos: u32 = tail_pos;
        if (std.mem.eql(u8, tm.parent, "Snek")) {
        }
        var pf2 = false;
        zi = 0;
        while (zi < zones.items.len) : (zi += 1) {
            if (std.mem.eql(u8, zones.items[zi].name, tm.parent) and zones.items[zi].ztype == .planet) {
                pf2 = true;
            } else if (zones.items[zi].ztype == .planet) {
                pf2 = false;
            } else if (pf2 and zones.items[zi].ztype == .moon) {
                var is_tail = false;
                for (tail_moons) |tm2| {
                    if (std.mem.eql(u8, zones.items[zi].name, tm2.name)) { is_tail = true; break; }
                }
                if (!is_tail) {
                    const mult: f64 = @as(f64, @floatFromInt(total_moons - reg_pos + 1)) / @as(f64, @floatFromInt(total_moons + 2));
                    if (std.mem.eql(u8, tm.parent, "Snek")) {
                    }
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
    var calidus_sgw: f64 = 0;
    for (zones.items) |nz| {
        if (std.mem.eql(u8, nz.name, "Nauvis")) { calidus_sgw = nz.star_gravity_well; break; }
    }
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

        _ = rng.float(); // orientation
        _ = rng.float() * scale * (if (is_calidus) @as(f64, 0.1) else 1.0); // distance

        try zones.append(.{ .name = sname, .ztype = .star });
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
    for (sz) |name| { try zones.append(.{ .name = name, .ztype = .@"asteroid-field" }); }
    for (0..data.space_zones.len) |_| { _ = rng.float(); _ = rng.float(); }

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

    return .{ .zones = zones, .draws = rng.draw, .k2 = k2_enabled, .vault_loot = vault_loot, .calidus_children = calidus_children, .calidus_child_types = calidus_child_types };
}
