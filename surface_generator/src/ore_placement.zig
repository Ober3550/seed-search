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
const terrain = @import("terrain.zig");
const rng = @import("rng.zig");

const pi = std.math.pi;

// ---- constants from resource_autoplace_all_patches local_expressions ----
pub const DOUBLE_DENSITY_DISTANCE: f64 = 1300.0;
pub const REGULAR_PATCH_FADE_IN_DISTANCE: f64 = 300.0;
pub const STARTING_RESOURCE_PLACEMENT_RADIUS: f64 = 120.0;
const STARTING_PATCHES_SPLIT: f64 = 0.5;
pub const MAXIMUM_SPOT_BASEMENT_RADIUS: f64 = 128.0;
pub const REGULAR_REGION_SIZE: f64 = 1024.0;
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
    starting_patch_set_index: u32 = 0,
    random_probability: f64 = 1.0,
    additional_richness: f64 = 0.0,
    minimum_richness: f64 = 0.0,
    richness_post_multiplier: f64 = 1.0,
    /// Autoplace order group: entities are placed group-by-group in ASCII order
    /// of AutoplaceSpecification.order; each group consumes the shared per-chunk
    /// RNG. Vanilla: group 0 = order "b" (iron/copper/coal/stone), group 1 =
    /// order "c" (uranium, crude-oil).
    order_group: u8 = 0,
};

pub const iron_ore_default = ResourceAutoplaceConfig{
    .base_density = 10.0, .regular_rq_factor_multiplier = 1.10,
    .starting_rq_factor_multiplier = 1.5,
    .candidate_spot_count = 22, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 0, .starting_patch_set_index = 0,
};
pub const copper_ore_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .regular_rq_factor_multiplier = 1.10,
    .starting_rq_factor_multiplier = 1.2,
    .candidate_spot_count = 22, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 1, .starting_patch_set_index = 1,
};
pub const coal_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .regular_rq_factor_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.1,
    .candidate_spot_count = 21, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 2, .starting_patch_set_index = 2,
};
pub const stone_default = ResourceAutoplaceConfig{
    .base_density = 4.0, .regular_rq_factor_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.1,
    .candidate_spot_count = 21, .has_starting_area_placement = .yes,
    .regular_patch_set_index = 3, .starting_patch_set_index = 3,
};
pub const uranium_ore_default = ResourceAutoplaceConfig{
    .base_density = 0.9, .base_spots_per_km2 = 1.25,
    .candidate_spot_count = 21, .regular_rq_factor_multiplier = 1.0,
    .random_spot_size_minimum = 2.0, .random_spot_size_maximum = 4.0,
    .has_starting_area_placement = .no, .regular_patch_set_index = 5,
    .order_group = 1,
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
    .order_group = 1,
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
    pub fn has(self: Field) i8 {
        return @intFromEnum(self.config.has_starting_area_placement);
    }
    pub fn regularRqFactor(self: Field) f64 {
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
    pub fn startingBlobAmplitude(self: Field) f64 {
        const rq = self.startingRqFactor();
        return self.startingBlobAmpMult() / (pi / 3.0 * rq * rq) *
            cbrt(self.startingAreaSpotQuantity());
    }

    // basement_value = -6 * max(regular_blob_amplitude_at(max_dist), starting_blob_amplitude)
    pub fn basementValue(self: Field) f64 {
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
pub const RegularSpotField = noise.SpotNoiseField(Field);

/// Build the regular-patch spot field for a resource (noise-functions.lua:236).
pub fn makeRegularSpotField(alloc: std.mem.Allocator, field: Field) RegularSpotField {
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

/// Starting-patch spot evaluator (noise-functions.lua:211-229). density is a
/// step inside r<120 (starting_modulation = 120 > distance); quantity and
/// radius are CONSTANT (no random_penalty_between); favorability =
/// clamp((elevation_lakes - 1)/10, 0, 1)*modulation*2 - distance/120
/// + random_penalty_at(0.5, 1) [the penalty term is applied by SpotNoiseField
/// via favorabilityPenalty()].
pub const StartingField = struct {
    field: Field,
    lakes: ?*const terrain.ElevationLakes,

    fn modulation(x: f64, y: f64) f64 {
        return if (distanceFromOrigin(x, y) < STARTING_RESOURCE_PLACEMENT_RADIUS) 1.0 else 0.0;
    }
    pub fn spotDensityAt(self: StartingField, x: f64, y: f64) f64 {
        const r = STARTING_RESOURCE_PLACEMENT_RADIUS;
        return self.field.startingAmount() / (pi * r * r) * modulation(x, y);
    }
    pub fn spotQuantityBaseAt(self: StartingField, x: f64, y: f64) f64 {
        _ = x;
        _ = y;
        return self.field.startingAreaSpotQuantity();
    }
    pub fn spotRadius(self: StartingField, quantity: f64) f64 {
        return self.field.startingRqFactor() * cbrt(quantity);
    }
    pub fn favorability(self: StartingField, x: f64, y: f64) f64 {
        const elev_term: f64 = if (self.lakes) |lk|
            clamp01((lk.at(x, y) - 1.0) / 10.0)
        else
            1.0;
        return elev_term * modulation(x, y) * 2.0 -
            distanceFromOrigin(x, y) / STARTING_RESOURCE_PLACEMENT_RADIUS;
    }
    /// random_penalty_at(0.5, 1) in the favorability expression.
    pub fn favorabilityPenalty(self: StartingField) ?noise.FavorabilityPenalty {
        _ = self;
        return .{ .source = 0.5, .amplitude = 0.5, .seed = 1.0 };
    }
    pub fn randomSpotSizeMinimum(self: StartingField) f64 {
        _ = self;
        return 1.0; // constant spot quantity (no random_penalty_between)
    }
    pub fn randomSpotSizeMaximum(self: StartingField) f64 {
        _ = self;
        return 1.0;
    }
};

pub const StartingSpotField = noise.SpotNoiseField(StartingField);

/// Build the starting-patch spot field (noise-functions.lua:211-229): seed1+1,
/// region 240, hard target, candidate_spot_count 32, spacing 32, starting set stride.
pub fn makeStartingSpotField(alloc: std.mem.Allocator, field: Field, lakes: ?*const terrain.ElevationLakes) StartingSpotField {
    return .{
        .alloc = alloc,
        .field = StartingField{ .field = field, .lakes = lakes },
        .seed0 = field.map_seed,
        .seed1 = field.config.seed1 + 1,
        .region_size = STARTING_RESOURCE_PLACEMENT_RADIUS * 2.0,
        .candidate_spot_count = 32,
        .skip_span = STARTING_PATCH_SET_COUNT,
        .skip_offset = field.config.starting_patch_set_index,
        .hard_region_target_quantity = true,
        .basement_value = field.basementValue(),
        .maximum_spot_basement_radius = MAXIMUM_SPOT_BASEMENT_RADIUS,
        .min_candidate_spacing = 32.0,
    };
}

/// starting_patches = starting_spots + (blobs0 - 0.25) * starting_blob_amplitude.
fn startingPatches(field: Field, basis: *const noise.BasisNoiseGen, x: f64, y: f64, starting_spot_value: f64) f64 {
    return starting_spot_value + (blobs0(basis, x, y) - 0.25) * field.startingBlobAmplitude();
}

/// Full per-resource field value at (x, y): the pre-clamp "all patches" value.
/// `starting_spot_value` is StartingSpotField.evalAt (null when the resource has
/// no starting placement or no starting field was built).
fn allPatchesValue(field: Field, basis: *const noise.BasisNoiseGen, x: f64, y: f64, spot_value: f64, starting_spot_value: ?f64) f64 {
    const regular = regularPatches(field, basis, x, y, spot_value);
    if (field.has() == 1) {
        if (starting_spot_value) |ssv| {
            return @max(startingPatches(field, basis, x, y, ssv), regular);
        }
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
/// Raw all_patches values at arbitrary positions — for calibration against the
/// game's `default-<name>-patches` named noise expression evaluated via
/// surface.calculate_tile_properties (see calibration/vanilla-sweep/probe_field.py).
pub fn probeAllPatches(alloc: std.mem.Allocator, map_seed: u32, config: ResourceAutoplaceConfig, controls: AutoplaceControls, lakes: ?*const terrain.ElevationLakes, xs: []const f64, ys: []const f64, out: []f64) !void {
    const field = Field{ .config = config, .controls = controls, .map_seed = map_seed };
    var spot = makeRegularSpotField(alloc, field);
    defer spot.deinit();
    var sspot: ?StartingSpotField = if (field.has() == 1) makeStartingSpotField(alloc, field, lakes) else null;
    defer if (sspot) |*ss| ss.deinit();
    const basis = noise.BasisNoiseGen.init(map_seed, config.seed1);
    for (xs, ys, out) |x, y, *o| {
        const sv = try spot.evalAt(x, y);
        const ssv: ?f64 = if (sspot) |*ss| try ss.evalAt(x, y) else null;
        o.* = allPatchesValue(field, &basis, x, y, sv, ssv);
    }
}

/// The probability_expression value at a tile: clamp(all_patches, 0, 1) *
/// (random_probability<1 ? random_penalty : 1). No placement roll — that is the
/// per-chunk RNG in computeOresInRect. Returns 0 if not part of any patch.
fn probabilityAt(field: Field, spot: *RegularSpotField, sspot: ?*StartingSpotField, basis: *const noise.BasisNoiseGen, x: f64, y: f64) !f64 {
    if (field.controls.size <= 0.0) return 0.0;
    const spot_value = try spot.evalAt(x, y);
    const ssv: ?f64 = if (sspot) |ss| try ss.evalAt(x, y) else null;
    const value = allPatchesValue(field, basis, x, y, spot_value, ssv);
    return clamp01(value);
    // NOTE: the fluid random_penalty (random_probability < 1) is applied by the
    // caller from the per-chunk penalty column — the game evaluates the
    // probability expression over the whole 32x32 chunk as ONE noise column, so
    // RandomPenalty seeds once from the chunk's first tile and consumes one
    // draw per tile in reverse column order (same semantics proven for the
    // spot-quantity draws). Not a per-tile-seeded value.
}

/// Per-chunk fluid penalty draw column. RandomPenalty::run over the chunk's
/// tile column: seed = int(x0)*7919 + int(y0+seed_param)*7907 + 0x3fbe2c from
/// the FIRST column element (chunk origin, row-major), one taus88 draw per
/// element, element i consuming draw (N-1-i). Seed has no resource term, so
/// every fluid shares this column; penalty = 1 - r*amplitude.
pub fn chunkPenaltyColumn(cx0: i32, cy0: i32, draws: *[32 * 32]f64) void {
    // seed param of random_penalty DEFAULTS TO 1 (verified via the rp-probe
    // oracle: unique linear solve gave c = 0x3fbe2c + 7907, i.e. y+1), so the
    // seed is int(x0)*7919 + int(y0+1)*7907 + 0x3fbe2c. Verified EXACT against
    // 4041/4041 probe dots over 256 chunks (calibration/vanilla-sweep,
    // rp-probe mod, probe-341 world).
    var seed: u32 = @bitCast(cx0 *% 7919 +% (cy0 +% 1) *% 7907 +% 0x3fbe2c);
    if (seed < 342) seed = 341;
    var prng = rng.Rng.init(seed);
    for (draws) |*d| d.* = prng.float();
}

pub const OreEntity = struct {
    x: i32, y: i32,
    resource_name: []const u8,
    amount: u32,
};

/// Optional terrain context for vanilla Nauvis generation:
/// - `elev` (elevation_nauvis) gates placement off water tiles (elevation < 0),
/// - `lakes` (elevation_lakes) feeds the starting-patch favorability, and its
///   presence enables the guaranteed starting patches.
pub const TerrainCtx = struct {
    elev: ?*const terrain.Elevation = null,
    lakes: ?*const terrain.ElevationLakes = null,
    /// Land-eligible order groups BEFORE resource group "b" (vanilla: huge-rock,
    /// big-rock, 20 tree groups = 22). fish ('' order) sweeps WATER tiles.
    land_groups_before_b: u32 = 22,
    /// Land groups between "b" and "c" (vanilla: 2 enemy groups).
    land_groups_b_to_c: u32 = 2,
    /// Per-chunk jitter-placement extras (each placed tree/rock/fish consumes 2
    /// extra draws): map key = (cx<<32)|cy packed, value = [before_b, b_to_c].
    extras: ?*const std.AutoHashMapUnmanaged(u64, [2]u32) = null,
    /// Water gate threshold. The game picks tiles by autoplace competition:
    /// water_base(0,100) = 100*(-elev) must beat the best LAND tile probability
    /// (plateau ~1 + per-tile noise_layer_noise), so the effective water
    /// boundary sits slightly BELOW elevation 0. -0.012 calibrated against
    /// seed-341 ground truth (3 wrong tiles / 8190; exact boundary needs the
    /// full tile-autoplace competition + the engine correction pass).
    water_threshold: f64 = -0.012,
};

pub fn computeOresInRect(
    alloc: std.mem.Allocator,
    map_seed: u32,
    x0: i32, y0: i32,
    x1: i32, y1: i32,
    resources: []const ResourceAutoplaceConfig,
    resource_names: []const []const u8,
    controls: AutoplaceControls,
    ctx: TerrainCtx,
    // Optional per-resource FSR override, parallel to `resources`. When non-null,
    // per_controls[i] replaces the shared `controls` for resource i — used by the
    // GUI's FSR test bench to drive each ore's frequency/size/richness
    // independently. null (or a length mismatch) falls back to `controls`.
    per_controls: ?[]const AutoplaceControls,
) !std.ArrayList(OreEntity) {
    var results: std.ArrayList(OreEntity) = .empty;

    // Per-resource state (spot cache + basis gen), built once.
    const RState = struct { field: Field, spot: RegularSpotField, sspot: ?StartingSpotField, basis: noise.BasisNoiseGen, name: []const u8 };
    const rstates = try alloc.alloc(RState, resources.len);
    defer alloc.free(rstates);
    for (resources, resource_names, 0..) |config, name, i| {
        const ctrl = if (per_controls) |pc| (if (i < pc.len) pc[i] else controls) else controls;
        const field = Field{ .config = config, .controls = ctrl, .map_seed = map_seed };
        const sspot: ?StartingSpotField = if (field.has() == 1) makeStartingSpotField(alloc, field, ctx.lakes) else null;
        rstates[i] = .{ .field = field, .spot = makeRegularSpotField(alloc, field), .sspot = sspot, .basis = noise.BasisNoiseGen.init(map_seed, config.seed1), .name = name };
    }
    defer for (rstates) |*rs| {
        rs.spot.deinit();
        if (rs.sspot) |*ss| ss.deinit();
    };

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
    var water: [CHUNK * CHUNK]bool = undefined; // per-chunk mask, computed once

    var cy: i32 = cy0;
    while (cy <= cy1) : (cy += 1) {
        var cx: i32 = cx0;
        while (cx <= cx1) : (cx += 1) {
            // Per-chunk water mask + counts (fish sweeps water; land groups
            // sweep every land tile regardless of probability — winner best is
            // initialized/reset to -inf, so any eligible tile rolls).
            var water_count: u32 = 0;
            var i: usize = 0;
            while (i < CHUNK * CHUNK) : (i += 1) {
                water[i] = if (ctx.elev) |el| el.at(
                    @floatFromInt(cx * CHUNK + @as(i32, @intCast(@mod(i, CHUNK)))),
                    @floatFromInt(cy * CHUNK + @as(i32, @intCast(@divTrunc(i, CHUNK)))),
                ) < ctx.water_threshold else false;
                if (water[i]) water_count += 1;
            }
            const land_count: u32 = @as(u32, CHUNK * CHUNK) - water_count;
            const extras: [2]u32 = if (ctx.extras) |ex| blk: {
                const k = (@as(u64, @as(u32, @bitCast(cx))) << 32) | @as(u64, @as(u32, @bitCast(cy)));
                break :blk ex.get(k) orelse .{ 0, 0 };
            } else .{ 0, 0 };

            // Shared per-chunk placement RNG, seeded once; consumed by every
            // order group in sequence.
            var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
            if (seed < 342) seed = 341;
            var prng = rng.Rng.init(seed);
            // fish ('' order): one draw per WATER tile + 2 per placed fish;
            // then the pre-"b" land groups (rocks + trees): one draw per land
            // tile each + 2 per placed jitter entity.
            var skip: u64 = water_count + 2 * @as(u64, extras[0]) +
                @as(u64, ctx.land_groups_before_b) * land_count;
            while (skip > 0) : (skip -= 1) _ = prng.next();

            var penalty_draws: [CHUNK * CHUNK]f64 = undefined;
            var penalty_done = false;

            var group: u8 = 0;
            while (group < 2) : (group += 1) {
                if (group == 1) {
                    // between "b" and "c": enemy groups sweep land + extras.
                    var skip2: u64 = @as(u64, ctx.land_groups_b_to_c) * land_count + 2 * @as(u64, extras[1]);
                    while (skip2 > 0) : (skip2 -= 1) _ = prng.next();
                }
                // PASS 1: winner per tile among THIS group's resources.
                i = 0;
                while (i < CHUNK * CHUNK) : (i += 1) {
                    win_res[i] = -1;
                    win_prob[i] = 0.0;
                }
                for (rstates, 0..) |*rs, ri| {
                    if (rs.field.config.order_group != group) continue;
                    var ly: i32 = 0;
                    while (ly < CHUNK) : (ly += 1) {
                        var lx: i32 = 0;
                        while (lx < CHUNK) : (lx += 1) {
                            const tx = cx * CHUNK + lx;
                            const ty = cy * CHUNK + ly;
                            if (tx < x0 or tx >= x1 or ty < y0 or ty >= y1) continue;
                            if (water[@intCast(ly * CHUNK + lx)]) continue;
                            const sspot_ptr: ?*StartingSpotField = if (rs.sspot) |*ss| ss else null;
                            var p = try probabilityAt(rs.field, &rs.spot, sspot_ptr, &rs.basis, @floatFromInt(tx), @floatFromInt(ty));
                            if (p < 0.0) p = 0.0;
                            const idx: usize = @intCast(ly * CHUNK + lx);
                            if (rs.field.config.random_probability < 1.0) {
                                if (!penalty_done) {
                                    chunkPenaltyColumn(cx * CHUNK, cy * CHUNK, &penalty_draws);
                                    penalty_done = true;
                                }
                                const r_draw = penalty_draws[CHUNK * CHUNK - 1 - idx];
                                p *= 1.0 - r_draw / rs.field.config.random_probability;
                                if (p < 0.0) p = 0.0;
                            }
                            const tie = p == win_prob[idx] and win_res[idx] >= 0;
                            if (p > win_prob[idx] or tie or win_res[idx] < 0) {
                                var rich: f64 = 0.0;
                                if (p > 0.0) {
                                    const spot_value = try rs.spot.evalAt(@floatFromInt(tx), @floatFromInt(ty));
                                    const ssv2: ?f64 = if (sspot_ptr) |ss| try ss.evalAt(@floatFromInt(tx), @floatFromInt(ty)) else null;
                                    rich = richnessAt(rs.field, @floatFromInt(tx), @floatFromInt(ty), allPatchesValue(rs.field, &rs.basis, @floatFromInt(tx), @floatFromInt(ty), spot_value, ssv2));
                                }
                                if (tie and rich <= win_rich[idx]) continue;
                                win_prob[idx] = p;
                                win_res[idx] = @intCast(ri);
                                win_rich[idx] = rich;
                            }
                        }
                    }
                }
                // PASS 2: reverse tile order; EVERY land tile in the rect
                // consumes one draw (winner exists at any eligible tile in the
                // game — our group members are all land resources).
                var ii: i32 = CHUNK * CHUNK - 1;
                while (ii >= 0) : (ii -= 1) {
                    const idx: usize = @intCast(ii);
                    const lx = @mod(ii, CHUNK);
                    const ly = @divFloor(ii, CHUNK);
                    const tx = cx * CHUNK + lx;
                    const ty = cy * CHUNK + ly;
                    if (water[idx]) continue; // no eligible entity -> no draw
                    const draw = @as(f64, @floatFromInt(prng.next())) * 2.3283064365386963e-10;
                    if (tx < x0 or tx >= x1 or ty < y0 or ty >= y1) continue;
                    if (win_res[idx] < 0) continue;
                    if (draw < win_prob[idx]) {
                        const amount: u32 = @intFromFloat(@floor(@max(win_rich[idx], 0.0)));
                        if (amount > 0) {
                            try results.append(alloc, .{ .x = tx, .y = ty, .resource_name = rstates[@intCast(win_res[idx])].name, .amount = amount });
                        }
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
