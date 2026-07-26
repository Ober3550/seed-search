//! Factorio resource autoplace — faithful port of the data-stage algorithm.
//!
//! Mirrors, expression-for-expression:
//!   - core/lualib/resource-autoplace.lua        (resource_autoplace_settings)
//!   - core/prototypes/noise-functions.lua       (resource_autoplace_all_patches)
//!   - base/prototypes/entity/resources.lua      (per-resource parameters)
//!
//! Everything OUTSIDE the two C++ noise ops is exact. The two ops still to be
//! extracted from the binary (Ghidra) are clearly marked:
//!   1. spot_noise  — per-region RNG seeding, skip_span/skip_offset striding,
//!                    target-quantity selection, spot contribution + basement.
//!   2. basis_noise — the actual gradient/interpolation (noise.basisNoise stub).
//!
//! Final field per resource (noise-functions.lua:192):
//!   value = if has_starting == 1 then max(starting_patches, regular_patches)
//!                                else regular_patches
//! regular_patches = spot_noise{...}
//!                 + (blobs0 + basis_noise{1/64, 1.5} - 1/3) * regular_blob_amplitude_at(distance)

const std = @import("std");
const noise = @import("noise.zig");
const rng = @import("rng.zig");

/// Per-tile placement roll. Factorio places a resource only if a per-tile uniform
/// draw < probability_expression = clamp(all_patches,0,1) [* random_penalty for
/// random_probability<1]. This thins fluid patches (crude-oil rp=1/48) to sparse
/// individual wells. `salt` makes the draw independent per resource.
fn placementRoll(x: i32, y: i32, salt: u32) f64 {
    const ix: u32 = @bitCast(x);
    const iy: u32 = @bitCast(y);
    var rr = rng.Rng.init((ix *% 73856093) ^ (iy *% 19349663) ^ salt);
    _ = rr.next();
    return rr.float();
}

const pi = std.math.pi;

// ---- constants from resource_autoplace_all_patches local_expressions ----
const DOUBLE_DENSITY_DISTANCE: f64 = 1300.0;
const REGULAR_PATCH_FADE_IN_DISTANCE: f64 = 300.0;
const STARTING_RESOURCE_PLACEMENT_RADIUS: f64 = 120.0;
const STARTING_PATCHES_SPLIT: f64 = 0.5;
const MAXIMUM_SPOT_BASEMENT_RADIUS: f64 = 128.0;
const REGULAR_REGION_SIZE: f64 = 1024.0;
// suggested_minimum_candidate_point_spacing for regular patches (noise-functions.lua:246).
const REGULAR_MIN_CANDIDATE_SPACING: f64 = 45.254833995939045;

// Patch-set indexes are assigned in resources.lua initialize_patch_set order:
//   iron=0 copper=1 coal=2 stone=3 crude-oil=4 uranium=5   (regular set)
//   iron=0 copper=1 coal=2 stone=3                          (starting set)
const REGULAR_PATCH_SET_COUNT: u32 = 6;
const STARTING_PATCH_SET_COUNT: u32 = 4;

pub const HasStarting = enum(i8) { none = -1, no = 0, yes = 1 };

pub const AutoplaceControls = struct {
    frequency: f64 = 1.0,
    size: f64 = 1.0,
    richness: f64 = 1.0,
};

pub const ResourceAutoplaceConfig = struct {
    base_density: f64,
    base_spots_per_km2: f64 = 2.5,
    candidate_spot_count: u32 = 21,
    regular_rq_factor_multiplier: f64 = 1.0,
    starting_rq_factor_multiplier: f64 = 1.0,
    regular_blob_amplitude_multiplier: f64 = 1.0,
    starting_blob_amplitude_multiplier: f64 = 1.0,
    random_spot_size_minimum: f64 = 0.25,
    random_spot_size_maximum: f64 = 2.0,
    seed1: u32 = 100,
    has_starting_area_placement: HasStarting = .yes,
    regular_patch_set_index: u32 = 0,
    random_probability: f64 = 1.0,
    additional_richness: f64 = 0.0,
    minimum_richness: f64 = 0.0,
    richness_post_multiplier: f64 = 1.0,
};

pub const iron_ore_default = ResourceAutoplaceConfig{
    .base_density = 10.0, .regular_rq_factor_multiplier = 1.10,
    .candidate_spot_count = 22, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 0,
};
pub const copper_ore_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .regular_rq_factor_multiplier = 1.10,
    .candidate_spot_count = 22, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 1,
};
pub const coal_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .regular_rq_factor_multiplier = 1.0,
    .candidate_spot_count = 21, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 2,
};
pub const stone_default = ResourceAutoplaceConfig{
    .base_density = 4.0, .regular_rq_factor_multiplier = 1.0,
    .candidate_spot_count = 21, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 3,
};
pub const uranium_ore_default = ResourceAutoplaceConfig{
    .base_density = 0.9, .base_spots_per_km2 = 1.25,
    .candidate_spot_count = 21, .regular_rq_factor_multiplier = 1.0,
    .has_starting_area_placement = .no, .regular_patch_set_index = 5,
};

// Base-game crude-oil (base/prototypes/entity/resources.lua). A fluid resource:
// random_probability 1/48 thins each spot's cone to sparse individual oil wells
// (not a solid patch); random_spot_size fixed at 1; additional_richness 220000
// makes each well a large deposit. No starting-area placement.
pub const crude_oil_default = ResourceAutoplaceConfig{
    .base_density = 8.2, .base_spots_per_km2 = 1.8,
    .candidate_spot_count = 21, .regular_rq_factor_multiplier = 1.0,
    .has_starting_area_placement = .no, .regular_patch_set_index = 4,
    .random_probability = 1.0 / 48.0,
    .random_spot_size_minimum = 1.0, .random_spot_size_maximum = 1.0,
    .additional_richness = 220000.0,
};

fn clamp01(v: f64) f64 {
    return std.math.clamp(v, 0.0, 1.0);
}
fn cbrt(v: f64) f64 {
    return std.math.pow(f64, v, 1.0 / 3.0);
}
fn distanceFromOrigin(x: f64, y: f64) f64 {
    return @sqrt(x * x + y * y);
}

/// Bundles a resource config + controls and exposes the local_functions and
/// local_expressions of resource_autoplace_all_patches, evaluated on demand.
/// Passed into noise.spotNoise as the per-candidate expression evaluator.
pub const Field = struct {
    config: ResourceAutoplaceConfig,
    controls: AutoplaceControls,
    map_seed: u32,

    fn freq(self: Field) f64 {
        return self.controls.frequency;
    }
    fn sizeMul(self: Field) f64 {
        return self.controls.size;
    }
    fn has(self: Field) i8 {
        return @intFromEnum(self.config.has_starting_area_placement);
    }
    fn regularRqFactor(self: Field) f64 {
        return self.config.regular_rq_factor_multiplier / 10.0;
    }
    fn startingRqFactor(self: Field) f64 {
        return self.config.starting_rq_factor_multiplier / 7.0;
    }
    fn regularBlobAmpMult(self: Field) f64 {
        return self.config.regular_blob_amplitude_multiplier / 8.0;
    }
    fn startingBlobAmpMult(self: Field) f64 {
        return self.config.starting_blob_amplitude_multiplier / 8.0;
    }

    // ---- local_functions ----
    fn sizeEffectiveDistanceAt(self: Field, d: f64) f64 {
        return if (self.has() == -1) d else d - REGULAR_PATCH_FADE_IN_DISTANCE;
    }
    fn regularDensityAt(self: Field, d: f64) f64 {
        const fade = if (self.has() == -1)
            1.0
        else
            clamp01((d - STARTING_RESOURCE_PLACEMENT_RADIUS) / REGULAR_PATCH_FADE_IN_DISTANCE);
        return self.config.base_density * self.freq() * self.sizeMul() * fade *
            (1.0 + clamp01(self.sizeEffectiveDistanceAt(d) / DOUBLE_DENSITY_DISTANCE));
    }
    fn regularSpotQuantityBaseAt(self: Field, d: f64) f64 {
        return 1_000_000.0 / self.config.base_spots_per_km2 / self.freq() * self.regularDensityAt(d);
    }
    fn regularSpotHeightTypicalAt(self: Field, d: f64) f64 {
        const avg = (self.config.random_spot_size_minimum + self.config.random_spot_size_maximum) / 2.0;
        const rq = self.regularRqFactor();
        return cbrt(avg * self.regularSpotQuantityBaseAt(d)) / (pi / 3.0 * rq * rq);
    }
    fn regularBlobAmplitudeMaximumDistance(self: Field) f64 {
        return if (self.has() == -1)
            DOUBLE_DENSITY_DISTANCE
        else
            DOUBLE_DENSITY_DISTANCE + REGULAR_PATCH_FADE_IN_DISTANCE;
    }
    fn regularBlobAmplitudeAt(self: Field, d: f64) f64 {
        return self.regularBlobAmpMult() *
            @min(self.regularSpotHeightTypicalAt(self.regularBlobAmplitudeMaximumDistance()),
                self.regularSpotHeightTypicalAt(d));
    }

    // ---- starting-patch local_expressions (used by basement_value even when
    //      starting patches themselves are not placed) ----
    fn startingAmount(self: Field) f64 {
        return 20000.0 * self.config.base_density * (self.freq() + 1.0) * self.sizeMul();
    }
    fn startingAreaSpotQuantity(self: Field) f64 {
        return self.startingAmount() / STARTING_PATCHES_SPLIT / self.freq();
    }
    fn startingBlobAmplitude(self: Field) f64 {
        const rq = self.startingRqFactor();
        return self.startingBlobAmpMult() / (pi / 3.0 * rq * rq) *
            cbrt(self.startingAreaSpotQuantity());
    }

    // basement_value = -6 * max(regular_blob_amplitude_at(max_dist), starting_blob_amplitude)
    fn basementValue(self: Field) f64 {
        return -6.0 * @max(
            self.regularBlobAmplitudeAt(self.regularBlobAmplitudeMaximumDistance()),
            self.startingBlobAmplitude(),
        );
    }

    // ---- spot_noise evaluator hooks (called by noise.spotNoise per candidate) ----
    /// density_expression = regular_density_at(distance), evaluated at the spot.
    pub fn spotDensityAt(self: Field, sx: f64, sy: f64) f64 {
        return self.regularDensityAt(distanceFromOrigin(sx, sy));
    }
    /// Deterministic part of spot_quantity_expression.
    pub fn spotQuantityBaseAt(self: Field, sx: f64, sy: f64) f64 {
        return self.regularSpotQuantityBaseAt(distanceFromOrigin(sx, sy));
    }
    /// spot_quantity_expression = random_penalty_between(min,max,1) * base.
    /// TODO: the per-spot random_penalty_between op (per-point RNG) isn't yet
    /// ported; use its mean (min+max)/2 = 1.125, which is unbiased for counts
    /// but drops per-spot size variation.
    pub fn spotQuantityAt(self: Field, sx: f64, sy: f64) f64 {
        const mean = (self.config.random_spot_size_minimum + self.config.random_spot_size_maximum) / 2.0;
        return mean * self.regularSpotQuantityBaseAt(distanceFromOrigin(sx, sy));
    }
    /// spot_radius_expression = min(32, regular_rq_factor * quantity^(1/3)).
    pub fn spotRadius(self: Field, quantity: f64) f64 {
        return @min(32.0, self.regularRqFactor() * cbrt(quantity));
    }
    /// spot_favorability_expression = 1 for regular patches (noise-functions.lua:241).
    pub fn favorability(self: Field, sx: f64, sy: f64) f64 {
        _ = self;
        _ = sx;
        _ = sy;
        return 1.0;
    }
    pub fn randomSpotSizeMinimum(self: Field) f64 {
        return self.config.random_spot_size_minimum;
    }
    pub fn randomSpotSizeMaximum(self: Field) f64 {
        return self.config.random_spot_size_maximum;
    }
};

/// blobs0 = basis_noise{1/8,1} + basis_noise{1/24,1}   (noise-functions.lua:203)
fn blobs0(basis: *const noise.BasisNoiseGen, x: f64, y: f64) f64 {
    return basis.eval(x, y, 1.0 / 8.0, 1.0) + basis.eval(x, y, 1.0 / 24.0, 1.0);
}

/// The cached SpotNoiseField specialized for our Field evaluator.
const RegularSpotField = noise.SpotNoiseField(Field);

/// Build the regular-patch spot field for a resource (noise-functions.lua:236).
fn makeRegularSpotField(alloc: std.mem.Allocator, field: Field) RegularSpotField {
    return .{
        .alloc = alloc,
        .field = field,
        .seed0 = field.map_seed,
        .seed1 = field.config.seed1,
        .region_size = REGULAR_REGION_SIZE,
        .candidate_spot_count = field.config.candidate_spot_count,
        .skip_span = REGULAR_PATCH_SET_COUNT,
        .skip_offset = field.config.regular_patch_set_index,
        .hard_region_target_quantity = false,
        .basement_value = field.basementValue(),
        .maximum_spot_basement_radius = MAXIMUM_SPOT_BASEMENT_RADIUS,
        .min_candidate_spacing = REGULAR_MIN_CANDIDATE_SPACING,
    };
}

/// regular_patches = spot_noise + (blobs0 + basis_noise{1/64,1.5} - 1/3) * amp.
/// `spot_value` is the cached SpotNoiseField.evalAt(x, y) result.
fn regularPatches(field: Field, basis: *const noise.BasisNoiseGen, x: f64, y: f64, spot_value: f64) f64 {
    const distance = distanceFromOrigin(x, y);
    const blob = blobs0(basis, x, y) + basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0;
    return spot_value + blob * field.regularBlobAmplitudeAt(distance);
}

/// starting_patches expression (noise-functions.lua:211-229).
///
/// GHIDRA/TERRAIN-PENDING: the favorability term uses elevation_lakes, which
/// requires terrain generation not yet implemented, and it uses a *hard*
/// target-quantity spot_noise. Until both exist, this returns a value that can
/// never win the max() below, so near-spawn output is "regular only" (which is
/// wrong inside ~r=120..420 — the guaranteed spawn patches are missing).
fn startingPatches(field: Field, x: f64, y: f64) f64 {
    _ = x;
    _ = y;
    return field.basementValue(); // sentinel: max(starting, regular) == regular for now
}

/// Full per-resource field value at (x, y): the pre-clamp "all patches" value.
fn allPatchesValue(field: Field, basis: *const noise.BasisNoiseGen, x: f64, y: f64, spot_value: f64) f64 {
    const regular = regularPatches(field, basis, x, y, spot_value);
    if (field.has() == 1) {
        return @max(startingPatches(field, x, y), regular);
    }
    return regular;
}

/// Richness at (x, y), following resource_autoplace_settings richness_expression.
fn richnessAt(field: Field, x: f64, y: f64, value: f64) f64 {
    var richness = value; // var(all_patches)
    const cfg = field.config;
    if (cfg.random_probability < 1.0) richness /= cfg.random_probability;
    if (cfg.additional_richness > 0.0) richness += cfg.additional_richness;
    if (cfg.minimum_richness > 0.0) richness = @max(richness, cfg.minimum_richness);

    // richness_distance = max((double_density_distance - (has~=nil ? fade_in : 0) + distance)
    //                         / (double_density_distance*2), 1)
    const sub: f64 = if (field.has() == -1) 0.0 else REGULAR_PATCH_FADE_IN_DISTANCE;
    const distance = distanceFromOrigin(x, y);
    const richness_distance = @max(
        (DOUBLE_DENSITY_DISTANCE - sub + distance) / (DOUBLE_DENSITY_DISTANCE * 2.0),
        1.0,
    );
    return cfg.richness_post_multiplier * field.controls.richness * richness * richness_distance;
}

/// Compute ore richness at a tile given the resource's field + its cached spot
/// field. Returns 0 if the tile is not part of a patch (probability <= 0).
///
/// NOTE: the game additionally does a per-tile RNG roll comparing a uniform draw
/// to clamp(value,0,1); tiles with 0<probability<1 are placed probabilistically.
/// That placement-layer roll is not yet modelled — we place wherever
/// probability > 0, which over-fills soft patch edges.
fn computeOreAt(field: Field, spot: *RegularSpotField, basis: *const noise.BasisNoiseGen, x: f64, y: f64, salt: u32) !f64 {
    if (field.controls.size <= 0.0) return 0.0; // (var('control:X:size') > 0) gate

    const spot_value = try spot.evalAt(x, y);
    const value = allPatchesValue(field, basis, x, y, spot_value);

    var probability = clamp01(value);
    if (probability <= 0.0) return 0.0;
    // Fluid resources (random_probability<1, e.g. crude-oil 1/48): multiply the
    // probability by a per-tile random_penalty, then roll. random_penalty{source=1,
    // amplitude=1/rp} is <0 on ~(1-rp) of tiles, so the cone becomes sparse wells.
    if (field.config.random_probability < 1.0) {
        probability *= noise.randomPenalty(x, y, 1.0, 1.0 / field.config.random_probability);
        if (probability <= 0.0) return 0.0;
    }
    const ix: i32 = @intFromFloat(x);
    const iy: i32 = @intFromFloat(y);
    if (placementRoll(ix, iy, salt) >= probability) return 0.0;

    return richnessAt(field, x, y, value);
}

/// The probability_expression value at a tile: clamp(all_patches, 0, 1) *
/// (random_probability<1 ? random_penalty : 1). No placement roll — that is the
/// per-chunk RNG in computeOresInRect. Returns 0 if not part of any patch.
fn probabilityAt(field: Field, spot: *RegularSpotField, basis: *const noise.BasisNoiseGen, x: f64, y: f64) !f64 {
    if (field.controls.size <= 0.0) return 0.0;
    const spot_value = try spot.evalAt(x, y);
    const value = allPatchesValue(field, basis, x, y, spot_value);
    var probability = clamp01(value);
    if (probability <= 0.0) return 0.0;
    if (field.config.random_probability < 1.0) {
        probability *= noise.randomPenalty(x, y, 1.0, 1.0 / field.config.random_probability);
        if (probability < 0.0) probability = 0.0;
    }
    return probability;
}

pub const OreEntity = struct {
    x: i32, y: i32,
    resource_name: []const u8,
    amount: u32,
};

pub fn computeOresInRect(
    alloc: std.mem.Allocator,
    map_seed: u32,
    x0: i32, y0: i32,
    x1: i32, y1: i32,
    resources: []const ResourceAutoplaceConfig,
    resource_names: []const []const u8,
    controls: AutoplaceControls,
) !std.ArrayList(OreEntity) {
    var results: std.ArrayList(OreEntity) = .empty;

    // Per-resource state (spot cache + basis gen), built once.
    const RState = struct { field: Field, spot: RegularSpotField, basis: noise.BasisNoiseGen, name: []const u8 };
    const rstates = try alloc.alloc(RState, resources.len);
    defer alloc.free(rstates);
    for (resources, resource_names, 0..) |config, name, i| {
        const field = Field{ .config = config, .controls = controls, .map_seed = map_seed };
        rstates[i] = .{ .field = field, .spot = makeRegularSpotField(alloc, field), .basis = noise.BasisNoiseGen.init(map_seed, config.seed1), .name = name };
    }
    defer for (rstates) |*rs| rs.spot.deinit();

    // Per-chunk two-pass placement (EntityMapGenerationTask::generateEntities,
    // ghidra/export/entity_placement.c). PASS 1: pick the winning resource per
    // tile (max probability). PASS 2: reverse tile order, roll the shared
    // per-chunk RNG once per winning tile, place if rng*2^-32 < probability.
    const CHUNK: i32 = 32;
    const cx0 = @divFloor(x0, CHUNK);
    const cx1 = @divFloor(x1 - 1, CHUNK);
    const cy0 = @divFloor(y0, CHUNK);
    const cy1 = @divFloor(y1 - 1, CHUNK);

    var win_prob: [CHUNK * CHUNK]f64 = undefined;
    var win_res: [CHUNK * CHUNK]i32 = undefined; // index into rstates, -1 = none
    var win_rich: [CHUNK * CHUNK]f64 = undefined;

    var cy: i32 = cy0;
    while (cy <= cy1) : (cy += 1) {
        var cx: i32 = cx0;
        while (cx <= cx1) : (cx += 1) {
            // PASS 1: winner per tile (row-major i = ly*32 + lx).
            var i: usize = 0;
            while (i < CHUNK * CHUNK) : (i += 1) {
                win_res[i] = -1;
                win_prob[i] = 0.0;
            }
            for (rstates, 0..) |*rs, ri| {
                var ly: i32 = 0;
                while (ly < CHUNK) : (ly += 1) {
                    var lx: i32 = 0;
                    while (lx < CHUNK) : (lx += 1) {
                        const tx = cx * CHUNK + lx;
                        const ty = cy * CHUNK + ly;
                        if (tx < x0 or tx >= x1 or ty < y0 or ty >= y1) continue;
                        const p = try probabilityAt(rs.field, &rs.spot, &rs.basis, @floatFromInt(tx), @floatFromInt(ty));
                        if (p <= 0.0) continue;
                        const idx: usize = @intCast(ly * CHUNK + lx);
                        // Higher probability wins; ties keep the earlier resource
                        // (order matters — oil is low priority, order "c").
                        if (p > win_prob[idx]) {
                            win_prob[idx] = p;
                            win_res[idx] = @intCast(ri);
                            win_rich[idx] = richnessAt(rs.field, @floatFromInt(tx), @floatFromInt(ty), allPatchesValue(rs.field, &rs.basis, @floatFromInt(tx), @floatFromInt(ty), try rs.spot.evalAt(@floatFromInt(tx), @floatFromInt(ty))));
                        }
                    }
                }
            }
            // PASS 2: per-chunk RNG, reverse tile order.
            var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
            if (seed < 342) seed = 341;
            var prng = rng.Rng.init(seed);
            var ii: i32 = CHUNK * CHUNK - 1;
            while (ii >= 0) : (ii -= 1) {
                const idx: usize = @intCast(ii);
                if (win_res[idx] < 0) continue;
                const draw = @as(f64, @floatFromInt(prng.next())) * 2.3283064365386963e-10;
                if (draw < win_prob[idx]) {
                    const amount: u32 = @intFromFloat(@floor(win_rich[idx]));
                    if (amount > 0) {
                        const lx = @mod(ii, CHUNK);
                        const ly = @divFloor(ii, CHUNK);
                        try results.append(alloc, .{ .x = cx * CHUNK + lx, .y = cy * CHUNK + ly, .resource_name = rstates[@intCast(win_res[idx])].name, .amount = amount });
                    }
                }
            }
        }
    }
    return results;
}

test "regular density fades in near spawn and is zero inside starting radius" {
    const cfg = iron_ore_default;
    const ctrl = AutoplaceControls{};
    const field = Field{ .config = cfg, .controls = ctrl, .map_seed = 341 };
    // Inside the starting radius (120) the fade factor is 0 -> regular density 0.
    try std.testing.expectEqual(@as(f64, 0.0), field.regularDensityAt(100.0));
    // Beyond the fade-in (420) density is positive.
    try std.testing.expect(field.regularDensityAt(600.0) > 0.0);
}

test "basement value is negative" {
    const field = Field{ .config = iron_ore_default, .controls = .{}, .map_seed = 341 };
    try std.testing.expect(field.basementValue() < 0.0);
}
