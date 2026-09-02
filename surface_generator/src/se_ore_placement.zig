//! Space Exploration resource autoplace — port of SE's overridden algorithm.
//!
//! Mirrors se_extracted/.../prototypes/resource_autoplace_overrides.lua
//! (`se_resource_autoplace_all_patches` + `resource_autoplace_settings`).
//! Reuses the same noise ops as the vanilla port (spot_noise, random_penalty,
//! basis_noise, multioctave); only the wrapping expressions + constants differ.
//! See surface_generator/docs/se-resources.md.
//!
//! SCOPE: implemented for NON-HOMEWORLD zones (moons/planets that are not the
//! spawn world), where `control:planet-size:richness = 0` so `se_distance` is a
//! constant 5000. Under that, density/radius/richness are position-independent
//! and starting_modulation = 0 (starting patches vanish) — so only regular
//! patches place. The homeworld (varying se_distance + starting patches) is not
//! yet handled.

const std = @import("std");
const builtin = @import("builtin");
const noise = @import("noise.zig");
const terrain = @import("terrain.zig");
const biome = @import("biome.zig");
const rng = @import("rng.zig");
const ore = @import("ore_placement.zig");

/// Per-tile placement probability roll. Factorio places a resource on a tile
/// only if a per-tile uniform draw < probability_expression = clamp(all_patches,
/// 0, 1) [* random_penalty for random_probability<1]. This thins the soft patch
/// edge (0<prob<1) instead of filling the whole >0 footprint. `salt` makes the
/// draw independent per resource. (Statistical/count match; exact tile identity
/// would need the game's per-chunk RNG in chunk-scan order.)
fn placementRoll(x: i32, y: i32, salt: u32) f64 {
    const ix: u32 = @bitCast(x);
    const iy: u32 = @bitCast(y);
    var rr = rng.Rng.init((ix *% 73856093) ^ (iy *% 19349663) ^ salt);
    _ = rr.next(); // discard first (LFSR warmup)
    return rr.float();
}

const pi = std.math.pi;

/// Water gate threshold for the per-chunk placement (see vanilla ore_placement
/// TerrainCtx.water_threshold — tiles come from an autoplace competition, so the
/// effective water boundary sits slightly below elevation 0; calibrate per
/// tileset). 0.0 until calibrated for the alien-biomes tile competition.
pub var se_water_threshold: f64 = 0.0;

// ---- SE constants — AUTHORITATIVE: se_resource_autoplace_all_patches
// (prototypes/resource_autoplace_overrides.lua), confirmed byte-for-byte from
// the LIVE game (prototypes.named_noise_expression['default-iron-ore-patches'],
// calibration/mod-dump/live-autoplace-expressions.json). SE's own function IS
// the active path — NOT the base-game resource_autoplace_all_patches.
pub const SE_DOUBLE_DENSITY: f64 = 5000.0; // base_distance / double_density_distance
pub const SE_REGULAR_FADE_IN: f64 = 320.0; // regular_patch_fade_in_distance
pub const SE_STARTING_RADIUS: f64 = 140.0; // starting_resource_placement_radius
// regular_blob_amplitude_maximum_distance = ddd (+ fade when has_starting != nil).
pub const SE_SPOT_ENLARGE_MAX: f64 = SE_DOUBLE_DENSITY + SE_REGULAR_FADE_IN;
pub const SE_CANDIDATE_SPOT_COUNT: u32 = 64;
pub const SE_MIN_CANDIDATE_SPACING: f64 = 128.0; // rs_suggested_minimum_candidate_point_spacing
pub const SE_SIZE_BOOST: f64 = 4.0; // additive spot radius boost (regular; starting uses /2)
pub const SE_MAX_BASEMENT_RADIUS: f64 = 128.0; // regular spot_noise
pub const SE_STARTING_MAX_BASEMENT_RADIUS: f64 = 64.0; // starting spot_noise
pub const SE_STARTING_AMOUNT: f64 = 100000.0; // starting_amount coefficient
pub const SE_STARTING_SPLIT: f64 = 0.25; // starting_patches_split = 1/4
pub const SE_STARTING_CANDIDATE_COUNT: u32 = 64; // candidate_spot_count param
pub const SE_STARTING_CANDIDATE_SPACING: f64 = 128.0; // suggested_minimum_candidate_point_spacing
pub const SE_REGION_SIZE: f64 = 1024.0;
pub const VEIN_OCTAVES: usize = 6; // multioctave_noise octaves for the vein terms

fn cbrt(v: f64) f64 {
    return std.math.pow(f64, v, 1.0 / 3.0);
}
fn clamp01(v: f64) f64 {
    return std.math.clamp(v, 0.0, 1.0);
}
fn dist0(x: f64, y: f64) f64 {
    return @sqrt(x * x + y * y);
}

/// The three per-resource map-gen control values (from computeZoneResourceControls).
/// SE raises each to the power 0.8 (setting_scale) when used as a multiplier.
pub const Controls = struct {
    frequency: f64,
    size: f64,
    richness: f64,
};

/// SE per-resource autoplace parameters (data.lua se_resources + phase-3 defaults).
pub const SEResourceConfig = struct {
    base_density: f64,
    base_spots_per_km2: f64 = 2.5,
    regular_rq_factor_multiplier: f64 = 1.1,
    random_probability: f64 = 1.0,
    additional_richness: f64 = 0.0,
    random_spot_size_minimum: f64 = 0.25,
    random_spot_size_maximum: f64 = 2.0,
    seed1: u32 = 100,
    // Patch-set striding: assigned by data-stage iteration order (phase-3).
    // GHIDRA/DATA-PENDING exact order — positions won't match the game until
    // captured. Counts/sizes are unaffected.
    regular_patch_set_index: u32 = 0,
    regular_patch_set_count: u32 = 8,
    // Starting-area (guaranteed near-spawn) patches. has_starting_area_placement
    // false -> no starting patches (uranium, K2). Indices/count from patchset-dump.
    has_starting_area_placement: bool = false,
    starting_patch_set_index: u32 = 0,
    starting_patch_set_count: u32 = 14,
    starting_rq_factor_multiplier: f64 = 1.0,
};

/// setting_scale(v) = v^0.8 applied to control sliders.
fn slider(v: f64) f64 {
    return std.math.pow(f64, v, 0.8);
}

/// Position-dependent SE resource evaluator. On these surfaces
/// control:planet-size:richness == 1 (confirmed from the live map_gen_settings),
/// so se_distance = clamp(5000 + 1*(distance-5000), 0, 5000) = min(distance, 5000)
/// == distance for zones smaller than 5000. Density/quantity/radius therefore
/// vary with distance from the zone center: smaller toward the middle, zero
/// inside the fade radius. The earlier constant-se_distance=5000 model treated
/// the whole disk as the far edge and overshot spot quantity ~15x.
const SEField = struct {
    base_density: f64,
    freq_mult: f64,
    size_mult: f64,
    base_spots_per_km2: f64,
    rq: f64, // regular_rq_factor
    smin: f64,
    smax: f64,

    /// SE uses the raw distance from center (no clamp; the density plateau is on
    /// the size-effective distance, clamped inside regularDensityAt).
    fn seDistance(x: f64, y: f64) f64 {
        return @sqrt(x * x + y * y);
    }

    /// regular_density_at(distance). has_starting_area_placement is 0 or 1 for
    /// every resource here (never nil), so the fade and size_effective_distance
    /// both use the "else" branch:
    ///   fade = clamp((dist - starting_radius)/fade_in, 0, 1)
    ///   size_eff = clamp(dist - fade_in, 0, spot_enlargement_max)
    ///   doubling = 1 + size_eff/double_density_distance
    fn regularDensityAt(self: SEField, dist: f64) f64 {
        const fade = clamp01((dist - SE_STARTING_RADIUS) / SE_REGULAR_FADE_IN);
        const size_eff = dist - SE_REGULAR_FADE_IN;
        const doubling = 1.0 + clamp01(size_eff / SE_DOUBLE_DENSITY);
        return self.base_density * self.freq_mult * self.size_mult * fade * doubling;
    }

    pub fn spotDensityAt(self: SEField, x: f64, y: f64) f64 {
        return self.regularDensityAt(seDistance(x, y));
    }
    pub fn spotQuantityBaseAt(self: SEField, x: f64, y: f64) f64 {
        const spots_per_km2 = self.base_spots_per_km2 * self.freq_mult;
        return self.regularDensityAt(seDistance(x, y)) * 1_000_000.0 / spots_per_km2;
    }
    /// spot_radius_expression = size_boost + min(32, rq * q^(1/3)) — SE adds a
    /// flat +4 to every regular spot radius (live-confirmed).
    pub fn spotRadius(self: SEField, q: f64) f64 {
        return SE_SIZE_BOOST + @min(32.0, self.rq * cbrt(q));
    }

    /// regular_spot_height_typical_at(distance).
    fn typicalHeightAt(self: SEField, dist: f64) f64 {
        const q_base = self.regularDensityAt(dist) * 1_000_000.0 / (self.base_spots_per_km2 * self.freq_mult);
        return cbrt((self.smin + self.smax) / 2.0 * q_base) / (pi / 3.0 * self.rq * self.rq);
    }

    /// regular_blob_amplitude_at(se_distance) = (1/8) * min(typical(max_dist), typical(se_distance)).
    /// Position-dependent (was frozen at the 5000 value), so the blob-noise term
    /// scales down with the spots toward the zone center.
    pub fn blobAmplitudeAt(self: SEField, x: f64, y: f64) f64 {
        const max_dist = SE_SPOT_ENLARGE_MAX; // regular_blob_amplitude_maximum_distance = 1600
        return (1.0 / 8.0) * @min(self.typicalHeightAt(max_dist), self.typicalHeightAt(seDistance(x, y)));
    }
    pub fn favorability(self: SEField, x: f64, y: f64) f64 {
        _ = self;
        _ = x;
        _ = y;
        return 1.0;
    }
    pub fn randomSpotSizeMinimum(self: SEField) f64 {
        return self.smin;
    }
    pub fn randomSpotSizeMaximum(self: SEField) f64 {
        return self.smax;
    }
};

const SESpotField = noise.SpotNoiseField(SEField);

/// SE starting patches (se_resource_autoplace_all_patches starting_patches).
/// UNLIKE the base game, SE's spot_favorability_expression is the CONSTANT 1
/// (the elevation_lakes/random_penalty favorability is commented out in SE),
/// radius gets a flat +size_boost/2, and quantity is constant (no
/// random_penalty_between). No elevation needed.
const StartingField = struct {
    starting_density: f64,
    spot_quantity: f64, // starting_area_spot_quantity (constant)
    rq_factor: f64, // starting_rq_factor = srq_mult / 8 (SE divides by 8, core by 7)

    fn modulation(x: f64, y: f64) f64 {
        // starting_modulation = clamp((radius - se_distance) * inf, 0, 1) = step
        return if (dist0(x, y) < SE_STARTING_RADIUS) 1.0 else 0.0;
    }
    pub fn spotDensityAt(self: StartingField, x: f64, y: f64) f64 {
        return self.starting_density * modulation(x, y);
    }
    pub fn spotQuantityBaseAt(self: StartingField, x: f64, y: f64) f64 {
        _ = x;
        _ = y;
        return self.spot_quantity;
    }
    pub fn spotRadius(self: StartingField, q: f64) f64 {
        // size_boost/2 + starting_rq_factor * q^(1/3)
        return SE_SIZE_BOOST / 2.0 + self.rq_factor * cbrt(q);
    }
    pub fn favorability(self: StartingField, x: f64, y: f64) f64 {
        _ = self;
        _ = x;
        _ = y;
        return 1.0;
    }
    pub fn randomSpotSizeMinimum(self: StartingField) f64 {
        _ = self;
        return 1.0;
    }
    pub fn randomSpotSizeMaximum(self: StartingField) f64 {
        _ = self;
        return 1.0;
    }
};

const StartingSpotField = noise.SpotNoiseField(StartingField);

/// Precomputed per-resource state for a zone.
const ResourceState = struct {
    name: []const u8,
    config: SEResourceConfig,
    controls: Controls,
    roll_salt: u32 = 0, // per-resource salt for the placement roll (hash of name)
    map_seed: u32,
    freq_mult: f64,
    size_mult: f64,
    richness_mult: f64,
    density: f64,
    quantity_base: f64,
    rq: f64,
    blob_amplitude: f64, // regular_blob_amplitude_at(5000)
    basement_value: f64,
    spot: SESpotField,
    // Guaranteed starting-area patches (null when has_starting_area_placement is
    // false or no elevation was provided). all_patches = max(regular, starting).
    starting_spot: ?StartingSpotField = null,
    starting_blob_amplitude: f64 = 0,
    // Flat spot slices for the fast direct-eval path (filled by
    // computeSEOresInRect after the region precompute; no hashing in hot loops).
    all_spots: []const noise.Spot = &.{},
    all_start_spots: []const noise.Spot = &.{},
    basis: noise.BasisNoiseGen,

    fn typicalHeightAt(self_density: f64, rq: f64, smin: f64, smax: f64, base_spots_per_km2: f64, freq_mult: f64) f64 {
        // regular_spot_height_typical_at using a given density.
        const q_base = self_density * 1_000_000.0 / (base_spots_per_km2 * freq_mult);
        return cbrt((smin + smax) / 2.0 * q_base) / (pi / 3.0 * rq * rq);
    }
};

pub fn makeResourceState(alloc: std.mem.Allocator, map_seed: u32, name: []const u8, cfg: SEResourceConfig, ctrl: Controls) ResourceState {
    return makeResourceStateElev(alloc, map_seed, name, cfg, ctrl, null);
}

pub fn makeResourceStateElev(alloc: std.mem.Allocator, map_seed: u32, name: []const u8, cfg: SEResourceConfig, ctrl: Controls, elev: ?*const terrain.Elevation) ResourceState {
    const freq_mult = slider(ctrl.frequency);
    const size_mult = slider(ctrl.size);
    const richness_mult = slider(ctrl.richness);

    // Reference density at regular_blob_amplitude_maximum_distance (=5320):
    //   fade=1, size_eff = 5320-320 = 5000 -> doubling = 1 + 5000/5000 = 2.
    const density_max = cfg.base_density * freq_mult * size_mult * 2.0;
    const density = density_max;

    // regular_spot_quantity_base = density * 1e6 / (base_spots_per_km2 * freq)
    const spots_per_km2 = cfg.base_spots_per_km2 * freq_mult;
    const quantity_base = density * 1_000_000.0 / spots_per_km2;

    const rq = cfg.regular_rq_factor_multiplier / 10.0;

    // regular_blob_amplitude_maximum = (1/8)*typical(max_dist) (typical at max is the
    // max, so min(typical(max), typical(max)) = typical(max)).
    const th_max = ResourceState.typicalHeightAt(density_max, rq, cfg.random_spot_size_minimum, cfg.random_spot_size_maximum, cfg.base_spots_per_km2, freq_mult);
    const blob_amp = (1.0 / 8.0) * th_max;
    const reg_amp_max = blob_amp;
    // SE starting values (se_resource_autoplace_all_patches, live-confirmed):
    //   starting_amount = 100000 * base_density * ((freq-1)*0.25 + 1) * size
    //   starting_area_spot_quantity = starting_amount / (1/4) / freq
    //   starting_rq_factor = starting_rq_factor_multiplier / 8 (core divides by 7)
    //   starting_blob_amplitude = (1/8) / (pi/3 * srq^2) * ssq^(1/3)
    const starting_rq = cfg.starting_rq_factor_multiplier / 8.0;
    const starting_amount = SE_STARTING_AMOUNT * cfg.base_density *
        ((freq_mult - 1.0) * 0.25 + 1.0) * size_mult;
    const starting_area_spot_quantity = starting_amount / SE_STARTING_SPLIT / freq_mult;
    const starting_blob_amplitude = (1.0 / 8.0) / (pi / 3.0 * starting_rq * starting_rq) *
        cbrt(starting_area_spot_quantity);
    const basement_value = -6.0 * @max(reg_amp_max, starting_blob_amplitude);

    const field = SEField{
        .base_density = cfg.base_density,
        .freq_mult = freq_mult,
        .size_mult = size_mult,
        .base_spots_per_km2 = cfg.base_spots_per_km2,
        .rq = rq,
        .smin = cfg.random_spot_size_minimum,
        .smax = cfg.random_spot_size_maximum,
    };
    const spot = SESpotField{
        .alloc = alloc,
        .field = field,
        .seed0 = map_seed,
        .seed1 = cfg.seed1,
        .region_size = SE_REGION_SIZE,
        .candidate_spot_count = SE_CANDIDATE_SPOT_COUNT,
        .skip_span = cfg.regular_patch_set_count,
        .skip_offset = cfg.regular_patch_set_index,
        .hard_region_target_quantity = false,
        .basement_value = basement_value,
        .maximum_spot_basement_radius = SE_MAX_BASEMENT_RADIUS,
        .min_candidate_spacing = SE_MIN_CANDIDATE_SPACING,
    };

    // Guaranteed starting patches (SE): region 280, hard target, seed1+1,
    // starting patch-set stride, basement radius 64, favorability constant 1
    // (no elevation dependency in SE).
    _ = elev;
    var starting_spot: ?StartingSpotField = null;
    if (cfg.has_starting_area_placement) {
        const starting_density = starting_amount / (pi * SE_STARTING_RADIUS * SE_STARTING_RADIUS);
        starting_spot = StartingSpotField{
            .alloc = alloc,
            .field = StartingField{
                .starting_density = starting_density,
                .spot_quantity = starting_area_spot_quantity,
                .rq_factor = starting_rq,
            },
            .seed0 = map_seed,
            .seed1 = cfg.seed1 + 1,
            .region_size = SE_STARTING_RADIUS * 2.0,
            .candidate_spot_count = SE_STARTING_CANDIDATE_COUNT,
            .skip_span = cfg.starting_patch_set_count,
            .skip_offset = cfg.starting_patch_set_index,
            .hard_region_target_quantity = true,
            .basement_value = basement_value,
            .maximum_spot_basement_radius = SE_STARTING_MAX_BASEMENT_RADIUS,
            .min_candidate_spacing = SE_STARTING_CANDIDATE_SPACING,
        };
    }

    // FNV-1a hash of the resource name for an independent placement-roll stream.
    var salt: u32 = 2166136261;
    for (name) |c| salt = (salt ^ c) *% 16777619;

    return .{
        .name = name,
        .config = cfg,
        .controls = ctrl,
        .roll_salt = salt,
        .map_seed = map_seed,
        .freq_mult = freq_mult,
        .size_mult = size_mult,
        .richness_mult = richness_mult,
        .density = density,
        .quantity_base = quantity_base,
        .rq = rq,
        .blob_amplitude = blob_amp,
        .basement_value = basement_value,
        .spot = spot,
        .starting_spot = starting_spot,
        .starting_blob_amplitude = starting_blob_amplitude,
        .basis = noise.BasisNoiseGen.init(map_seed, cfg.seed1),
    };
}

/// vein = 1 - 10 * abs(multioctave_noise{input_scale=1/4, persistence=0.5, octaves=6})
/// The op reuses ONE Noise (seed0=map_seed, seed1) across octaves == st.basis.
fn vein(gen: *const noise.BasisNoiseGen, x: f64, y: f64) f64 {
    const m = noise.multioctaveNoisePrebuilt(gen, x, y, VEIN_OCTAVES, 0.5, 1.0 / 4.0, 1.0);
    return 1.0 - 10.0 * @abs(m);
}

/// Debug decomposition of the value field at (x,y) for one resource.
pub const Probe = struct { spot_v: f64, blobs0: f64, basis64: f64, vein_raw: f64, blob: f64, amp: f64, value: f64 };
pub fn probeAt(st: *ResourceState, x: f64, y: f64) !Probe {
    const spot_v = try st.spot.evalAt(x, y);
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const basis64 = st.basis.eval(x, y, 1.0 / 64.0, 1.5);
    const vein_raw = vein(&st.basis, x, y);
    const blob = blobs0 + basis64 - 1.0 / 3.0 + 0.8 * vein_raw * st.config.random_probability;
    const amp = st.spot.field.blobAmplitudeAt(x, y);
    return .{ .spot_v = spot_v, .blobs0 = blobs0, .basis64 = basis64, .vein_raw = vein_raw, .blob = blob, .amp = amp, .value = spot_v + blob * amp };
}

/// all_patches value at (x,y) for a resource. Regular patches only (non-home).
fn allPatchesValue(st: *ResourceState, x: f64, y: f64) !f64 {
    // SE regular_patches = regular_spots +
    //   (1*(blobs0 + basis(1/64,1.5) - 1/3) + 0.8*vein*random_probability) * amp,
    // where the noise-function's random_probability param is HARDCODED to 1 by
    // SE's resource_autoplace_settings (the fluid thinning random_penalty is
    // applied to the PROBABILITY expression instead). vein =
    // 1 - 10*|multioctave{is=1/4, oct 6, persistence 0.5, seed1}|.
    const spot_v = try st.spot.evalAt(x, y);
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const blob = blobs0 + st.basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0;
    const vein_v = 1.0 - 10.0 * @abs(noise.multioctaveNoisePrebuilt(&st.basis, x, y, VEIN_OCTAVES, 0.5, 1.0 / 4.0, 1.0));
    const regular = spot_v + (blob + 0.8 * vein_v) * st.spot.field.blobAmplitudeAt(x, y);
    // all_patches = max(starting_patches, regular_patches). starting_patches =
    // starting_spots + (0.4*(blobs0 - 1/4) + 0.2*start_vein) * starting_blob_amp,
    // start_vein = 1 - 10*|multioctave{is=1 (!), oct 6, persistence 0.5, seed1}|.
    if (st.starting_spot) |*ss| {
        const start_spot_v = try ss.evalAt(x, y);
        const start_vein = 1.0 - 10.0 * @abs(noise.multioctaveNoisePrebuilt(&st.basis, x, y, VEIN_OCTAVES, 0.5, 1.0, 1.0));
        const starting = start_spot_v + (0.4 * (blobs0 - 0.25) + 0.2 * start_vein) * st.starting_blob_amplitude;
        return @max(regular, starting);
    }
    return regular;
}

pub const OreEntity = struct {
    x: i32,
    y: i32,
    resource_name: []const u8,
    amount: u32,
};

pub const ResourceInput = struct {
    name: []const u8,
    config: SEResourceConfig,
    controls: Controls,
};

/// post_semd_richness_distance_multiplier_at: richness rises past the density
/// plateau. = max(1, (ddd + sed)/(ddd + semd)), sed = size_effective distance
/// (dist - fade_in). On this moon sed < semd so it stays 1, but keep it correct.
fn richnessDistance(x: f64, y: f64) f64 {
    // max(1, (ddd + sed)/(ddd + semd)) with semd = spot_enlargement_maximum
    // _distance = double_density_distance = 5000 (NOT +fade_in), sed =
    // se_distance - fade_in. Confirmed from the live richness_expression:
    // max(1, (5000 + clamp(...) - 320)/(5000 + 5000)).
    const dist = @min(@sqrt(x * x + y * y), SE_DOUBLE_DENSITY);
    const sed = dist - SE_REGULAR_FADE_IN;
    return @max(1.0, (SE_DOUBLE_DENSITY + sed) / (SE_DOUBLE_DENSITY + SE_DOUBLE_DENSITY));
}

/// Evaluate one resource at one tile. Read-only w.r.t. `st` once its spot cache
/// has been pre-populated (see computeSEOresInRect), so this is safe to call
/// concurrently from multiple threads on shared ResourceStates.
/// Direct max-cone evaluation over a flat spot slice (SpotNoiseField.evalAt
/// semantics without region hashing): max over spots within basement_radius of
/// (peak - slope*dist), floored at basement.
inline fn spotValueDirect(spots: []const noise.Spot, basement: f64, basement_radius: f64, x: f64, y: f64) f64 {
    var value = basement;
    for (spots) |sp| {
        const ddx = x - sp.x;
        const ddy = y - sp.y;
        const dist = @sqrt(ddx * ddx + ddy * ddy);
        if (dist <= basement_radius) {
            const v = sp.peak - dist * sp.slope;
            if (v > value) value = v;
        }
    }
    return value;
}

/// allPatchesValue on the fast path: identical math, but spot fields evaluated
/// from the pre-gathered flat slices.
fn allPatchesValueDirect(st: *ResourceState, x: f64, y: f64) f64 {
    const spot_v = spotValueDirect(st.all_spots, st.basement_value, SE_MAX_BASEMENT_RADIUS, x, y);
    // Early out: the blob/vein terms are bounded by 4*amp, so if even the best
    // spot value cannot reach 0 the tile places nothing — skip the noise evals
    // (3 basis + two 6-octave multioctaves). Most tiles in active chunks are
    // still outside every cone.
    {
        const reg_max = spot_v + 4.0 * st.blob_amplitude;
        var start_max: f64 = -1.0;
        if (st.starting_spot != null) {
            const sv = spotValueDirect(st.all_start_spots, st.basement_value, SE_STARTING_MAX_BASEMENT_RADIUS, x, y);
            start_max = sv + 4.0 * st.starting_blob_amplitude;
        }
        if (reg_max <= 0.0 and start_max <= 0.0) return -1.0;
    }
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const blob = blobs0 + st.basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0;
    const vein_v = 1.0 - 10.0 * @abs(noise.multioctaveNoisePrebuilt(&st.basis, x, y, VEIN_OCTAVES, 0.5, 1.0 / 4.0, 1.0));
    const regular = spot_v + (blob + 0.8 * vein_v) * st.spot.field.blobAmplitudeAt(x, y);
    if (st.starting_spot != null) {
        const start_spot_v = spotValueDirect(st.all_start_spots, st.basement_value, SE_STARTING_MAX_BASEMENT_RADIUS, x, y);
        const start_vein = 1.0 - 10.0 * @abs(noise.multioctaveNoisePrebuilt(&st.basis, x, y, VEIN_OCTAVES, 0.5, 1.0, 1.0));
        const starting = start_spot_v + (0.4 * (blobs0 - 0.25) + 0.2 * start_vein) * st.starting_blob_amplitude;
        return @max(regular, starting);
    }
    return regular;
}

/// Can this resource produce a POSITIVE all_patches value anywhere within
/// `radius` of (cx, cy)? all_patches > 0 requires a spot cone to lift the value
/// above -(blob range)*amp; outside every cone the field sits at basement
/// (-6*amp) which the blob terms (|blob+0.8*vein| < 4) can never overcome. So a
/// chunk with no spot within min(basement_radius, (peak+4*amp)/slope) + radius
/// can be skipped entirely.
fn chunkCanHaveOre(st: *ResourceState, cx: f64, cy: f64, radius: f64) bool {
    const amp4 = 4.0 * st.blob_amplitude;
    for (st.all_spots) |sp| {
        const reach = @min(SE_MAX_BASEMENT_RADIUS, (sp.peak + amp4) / sp.slope);
        const ddx = cx - sp.x;
        const ddy = cy - sp.y;
        if (@sqrt(ddx * ddx + ddy * ddy) <= reach + radius) return true;
    }
    const samp4 = 4.0 * st.starting_blob_amplitude;
    for (st.all_start_spots) |sp| {
        const reach = @min(SE_STARTING_MAX_BASEMENT_RADIUS, (sp.peak + samp4) / sp.slope);
        const ddx = cx - sp.x;
        const ddy = cy - sp.y;
        if (@sqrt(ddx * ddx + ddy * ddy) <= reach + radius) return true;
    }
    return false;
}

/// Raw all_patches values at arbitrary positions — oracle comparison against
/// the live game's `default-<name>-patches` via calculate_tile_properties
/// (calibration/vanilla-sweep/probe_live.py).
pub fn probeSEAllPatches(alloc: std.mem.Allocator, map_seed: u32, name: []const u8, cfg: SEResourceConfig, ctrl: Controls, elev: ?*const terrain.Elevation, xs: []const f64, ys: []const f64, out: []f64) !void {
    var st = makeResourceStateElev(alloc, map_seed, name, cfg, ctrl, elev);
    defer {
        st.spot.deinit();
        if (st.starting_spot) |*ss| ss.deinit();
    }
    for (xs, ys, out) |x, y, *o| o.* = try allPatchesValue(&st, x, y);
}

fn evalTileForState(st: *ResourceState, x: i32, y: i32, fx: f64, fy: f64) !?OreEntity {
    const value = try allPatchesValue(st, fx, fy);
    var probability = clamp01(value);
    if (probability <= 0.0) return null;
    // random_probability<1 (e.g. crude-oil 1/48) multiplies probability by a
    // per-tile random_penalty before the roll.
    if (st.config.random_probability < 1.0) {
        probability *= noise.randomPenalty(fx, fy, 1.0, 1.0 / st.config.random_probability);
        if (probability <= 0.0) return null;
    }
    // Per-tile placement roll: place only if uniform < probability. Thins the
    // soft patch edge instead of filling the whole value>0 footprint.
    if (placementRoll(x, y, st.roll_salt) >= probability) return null;

    var richness = value;
    if (st.config.random_probability < 1.0) richness /= st.config.random_probability;
    if (st.config.additional_richness > 0.0) richness += st.config.additional_richness;
    richness *= richnessDistance(fx, fy) * st.richness_mult;

    const amount: u32 = @intFromFloat(@floor(richness));
    if (amount == 0) return null;
    return OreEntity{ .x = x, .y = y, .resource_name = st.name, .amount = amount };
}

/// One worker: evaluates all resources over a contiguous band of rows [ya, yb).
/// Owns its output buffer (page_allocator) so threads never share a mutable
/// allocator; the caller concatenates and frees these after join.
const Worker = struct {
    states: []ResourceState,
    zone_radius: f64,
    x0: i32,
    x1: i32,
    ya: i32,
    yb: i32,
    sample_step: i32,
    water: ?*const terrain.Elevation,
    // Terrain gating: classify the biome tile ONLY at positions where an ore
    // actually exists (ore is sparse, terrain classify is expensive). Water
    // exclusion applies to every ore; the biome tile_restriction only to
    // se-vulcanite/cryonite/vitamelange.
    zone_terrain: ?*const terrain.ZoneTerrain,
    classifier: ?*const biome.Classifier,
    out: std.ArrayList(OreEntity) = .empty,
    err: ?anyerror = null,
    // --- profiling counters, aggregated by the caller ---
    n_elev: u64 = 0,
    n_field: u64 = 0,
    n_biome: u64 = 0,

    fn run(self: *Worker) void {
        if (self.sample_step != 1) return self.runLegacy();
        const a = std.heap.page_allocator;
        const CHUNK: i32 = 32;
        const cx0 = @divFloor(self.x0, CHUNK);
        const cx1 = @divFloor(self.x1 - 1, CHUNK);
        // Bands are whole chunk rows (ya/yb are chunk-aligned by the caller).
        const cy0 = @divFloor(self.ya, CHUNK);
        const cy1 = @divFloor(self.yb - 1, CHUNK);

        var win_prob: [CHUNK * CHUNK]f64 = undefined;
        var win_res: [CHUNK * CHUNK]i32 = undefined;
        var win_rich: [CHUNK * CHUNK]f64 = undefined;
        var elev_val: [CHUNK * CHUNK]f64 = undefined;
        var elev_done: [CHUNK * CHUNK]bool = undefined;
        var biome_idx: [CHUNK * CHUNK]usize = undefined;
        var biome_done: [CHUNK * CHUNK]bool = undefined;

        var cy: i32 = cy0;
        while (cy <= cy1) : (cy += 1) {
            var cx: i32 = cx0;
            while (cx <= cx1) : (cx += 1) {
                // Chunk culling: skip everything (fields, water, biome, pass 2)
                // when no resource can produce a positive value anywhere in the
                // chunk — ore covers ~2% of the surface, so this skips the vast
                // majority of chunks. Safe: solids don't depend on the RNG
                // stream, and per-chunk streams are independent.
                const ccx: f64 = @floatFromInt(cx * CHUNK + 16);
                const ccy: f64 = @floatFromInt(cy * CHUNK + 16);
                const chunk_r = 16.0 * std.math.sqrt2 + 1.0;
                var any_active = false;
                var active: [64]bool = undefined;
                for (self.states, 0..) |*st0, ri0| {
                    active[ri0] = chunkCanHaveOre(st0, ccx, ccy, chunk_r);
                    if (active[ri0]) any_active = true;
                }
                if (!any_active) continue;

                // PASS 1 (generateEntities): winner per tile = highest
                // probability, ties broken by higher richness.
                var penalty_draws: [CHUNK * CHUNK]f64 = undefined;
                var penalty_done = false;
                @memset(win_res[0..], -1);
                @memset(win_prob[0..], 0.0);
                @memset(elev_done[0..], false);
                @memset(biome_done[0..], false);
                for (self.states, 0..) |*st, ri| {
                    if (!active[ri]) continue;
                    var ly: i32 = 0;
                    while (ly < CHUNK) : (ly += 1) {
                        var lx: i32 = 0;
                        while (lx < CHUNK) : (lx += 1) {
                            const tx = cx * CHUNK + lx;
                            const ty = cy * CHUNK + ly;
                            if (tx < self.x0 or tx >= self.x1 or ty < self.ya or ty >= self.yb) continue;
                            const fx: f64 = @floatFromInt(tx);
                            const fy: f64 = @floatFromInt(ty);
                            if (dist0(fx, fy) > self.zone_radius) continue;
                            const value = allPatchesValueDirect(st, fx, fy);
                            self.n_field += 1;
                            var p = clamp01(value);
                            if (p <= 0.0) continue;
                            const idx: usize = @intCast(ly * CHUNK + lx);
                            if (st.config.random_probability < 1.0) {
                                if (!penalty_done) {
                                    ore.chunkPenaltyColumn(cx * CHUNK, cy * CHUNK, &penalty_draws);
                                    penalty_done = true;
                                }
                                const r_draw = penalty_draws[@as(usize, @intCast(CHUNK * CHUNK - 1)) - idx];
                                p *= 1.0 - r_draw / st.config.random_probability;
                                if (p <= 0.0) continue;
                            }
                            // water gate (lazy per tile)
                            if (self.water) |w| {
                                if (!elev_done[idx]) {
                                    elev_val[idx] = w.at(fx, fy);
                                    self.n_elev += 1;
                                    elev_done[idx] = true;
                                }
                                if (elev_val[idx] < se_water_threshold) continue;
                            }
                            // biome tile_restriction gate (restricted ores only)
                            if (self.classifier) |c| {
                                if (self.zone_terrain) |zt| {
                                    if (biome.isBiomeRestricted(st.name)) {
                                        if (!biome_done[idx]) {
                                            const ev = if (elev_done[idx]) elev_val[idx] else 0.0;
                                            biome_idx[idx] = c.classifyIndex(fx, fy, zt.temperature(fx, fy), zt.moisture(fx, fy), zt.aux(fx, fy), ev);
                                            self.n_biome += 1;
                                            biome_done[idx] = true;
                                        }
                                        if (!biome.oreAllowedOnBiome(st.name, biome_idx[idx])) continue;
                                    }
                                }
                            }
                            const tie = p == win_prob[idx] and win_res[idx] >= 0;
                            if (p > win_prob[idx] or tie) {
                                var rich = value;
                                if (st.config.random_probability < 1.0) rich /= st.config.random_probability;
                                if (st.config.additional_richness > 0.0) rich += st.config.additional_richness;
                                rich *= richnessDistance(fx, fy) * st.richness_mult;
                                if (tie and rich <= win_rich[idx]) continue;
                                win_prob[idx] = p;
                                win_res[idx] = @intCast(ri);
                                win_rich[idx] = rich;
                            }
                        }
                    }
                }
                // PASS 2: shared per-chunk RNG, reverse tile order.
                var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
                if (seed < 342) seed = 341;
                var prng = rng.Rng.init(seed);
                var ii: i32 = CHUNK * CHUNK - 1;
                while (ii >= 0) : (ii -= 1) {
                    const idx: usize = @intCast(ii);
                    if (win_res[idx] < 0) continue;
                    const draw = @as(f64, @floatFromInt(prng.next())) * 2.3283064365386963e-10;
                    if (draw < win_prob[idx]) {
                        const amount: u32 = @intFromFloat(@floor(@max(win_rich[idx], 0.0)));
                        if (amount > 0) {
                            const lx = @mod(ii, CHUNK);
                            const ly = @divFloor(ii, CHUNK);
                            self.out.append(a, .{
                                .x = cx * CHUNK + lx,
                                .y = cy * CHUNK + ly,
                                .resource_name = self.states[@intCast(win_res[idx])].name,
                                .amount = amount,
                            }) catch |e| {
                                self.err = e;
                                return;
                            };
                        }
                    }
                }
            }
        }
    }

    fn runLegacy(self: *Worker) void {
        const a = std.heap.page_allocator;
        var y: i32 = self.ya;
        while (y < self.yb) : (y += self.sample_step) {
            var x: i32 = self.x0;
            while (x < self.x1) : (x += self.sample_step) {
                const fx: f64 = @floatFromInt(x);
                const fy: f64 = @floatFromInt(y);
                if (dist0(fx, fy) > self.zone_radius) continue; // outside the surface
                // Per-tile terrain is resolved lazily: only when an ore candidate
                // is found here, and the biome classify only when a biome-
                // restricted resource has a candidate. Most of the surface (no
                // ore) never touches the terrain generator.
                var water_done = false;
                var is_water = false;
                var biome_done = false;
                var biome_idx: usize = 0;
                var elev: f64 = 0;
                for (self.states) |*st| {
                    const oe = evalTileForState(st, x, y, fx, fy) catch |e| {
                        self.err = e;
                        return;
                    };
                    const o = oe orelse continue;
                    // water gate (applies to every ore) — compute elevation once
                    if (self.water) |w| {
                        if (!water_done) {
                            elev = w.at(fx, fy);
                            is_water = elev < 0.0;
                            water_done = true;
                        }
                        if (is_water) continue;
                    }
                    // biome tile_restriction gate (restricted resources only)
                    if (self.classifier) |c| {
                        if (self.zone_terrain) |zt| {
                            if (biome.isBiomeRestricted(st.name)) {
                                if (!biome_done) {
                                    biome_idx = c.classifyIndex(fx, fy, zt.temperature(fx, fy), zt.moisture(fx, fy), zt.aux(fx, fy), elev);
                                    biome_done = true;
                                }
                                if (!biome.oreAllowedOnBiome(st.name, biome_idx)) continue;
                            }
                        }
                    }
                    self.out.append(a, o) catch |e| {
                        self.err = e;
                        return;
                    };
                }
            }
        }
    }
};

/// Generate SE ore for a zone surface. `map_seed` is the zone seed.
/// Placement is bounded to a disk of `zone_radius` (the moon/planet surface).
///
/// Parallelism: the per-tile field evaluation dominates and is identical work
/// per resource, so we precompute every region's spot list up front (cheap,
/// single-threaded — a handful of regions) and then split the tile grid into
/// row bands across all CPU cores. After the precompute the spot caches are
/// read-only, so the bands share the ResourceStates with no locking.
pub fn computeSEOresInRect(
    alloc: std.mem.Allocator,
    map_seed: u32,
    zone_radius: f64,
    x0: i32, y0: i32,
    x1: i32, y1: i32,
    resources: []const ResourceInput,
    sample_step: i32,
    water: ?*const terrain.Elevation,
    zone_terrain: ?*const terrain.ZoneTerrain,
    classifier: ?*const biome.Classifier,
) !std.ArrayList(OreEntity) {
    var results: std.ArrayList(OreEntity) = .empty;
    if (x1 <= x0 or y1 <= y0) return results;

    // Build states for enabled resources (stable slice — SpotNoiseField caches
    // hold `alloc`-owned memory and are referenced by pointer from the workers).
    const states_buf = try alloc.alloc(ResourceState, resources.len);
    var ns: usize = 0;
    for (resources) |res| {
        if (res.controls.size <= 0.0) continue; // (control:X:size > 0) gate
        states_buf[ns] = makeResourceStateElev(alloc, map_seed, res.name, res.config, res.controls, water);
        ns += 1;
    }
    const states = states_buf[0..ns];
    defer for (states) |*st| {
        st.spot.deinit();
        if (st.starting_spot) |*ss| ss.deinit();
    };
    if (ns == 0) return results;

    // Precompute every region a tile in the rect can request. evalAt looks at
    // round(coord/region_size) ± 1, so cover that whole range for each state.
    const rs = SE_REGION_SIZE;
    const rminx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x0)) / rs))) - 1;
    const rmaxx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x1 - 1)) / rs))) + 1;
    const rminy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y0)) / rs))) - 1;
    const rmaxy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y1 - 1)) / rs))) + 1;
    for (states) |*st| {
        var rx: i32 = rminx;
        while (rx <= rmaxx) : (rx += 1) {
            var ry: i32 = rminy;
            while (ry <= rmaxy) : (ry += 1) {
                _ = try st.spot.spotsForRegion(rx, ry);
            }
        }
        // Starting patches use a small region (2*starting_radius=240) near the
        // origin; precompute the regions any tile can request so the threaded
        // eval sees a read-only cache. round(coord/240)±1 over the rect.
        if (st.starting_spot) |*ss| {
            const srs = SE_STARTING_RADIUS * 2.0;
            const sminx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x0)) / srs))) - 1;
            const smaxx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x1 - 1)) / srs))) + 1;
            const sminy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y0)) / srs))) - 1;
            const smaxy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y1 - 1)) / srs))) + 1;
            var srx: i32 = sminx;
            while (srx <= smaxx) : (srx += 1) {
                var sry: i32 = sminy;
                while (sry <= smaxy) : (sry += 1) {
                    _ = try ss.spotsForRegion(srx, sry);
                }
            }
        }
    }

    // Flat spot slices for the fast path (direct eval + chunk culling).
    {
        const fx0: f64 = @floatFromInt(x0);
        const fx1: f64 = @floatFromInt(x1);
        const fy0: f64 = @floatFromInt(y0);
        const fy1: f64 = @floatFromInt(y1);
        for (states) |*st| {
            st.all_spots = try st.spot.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
            if (st.starting_spot) |*ss| {
                st.all_start_spots = try ss.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
            }
        }
    }

    // Decide worker count from the row (step) budget and CPU cores. For the
    // per-chunk path (sample_step==1) bands are whole 32-row chunk rows so a
    // chunk is never split across workers (its RNG stream must be sequential).
    // WebAssembly (freestanding) has no threads: pin to 1 worker there, which
    // also keeps std.Thread out of the analyzed code for that target.
    const use_threads = comptime builtin.os.tag != .freestanding;
    const total_steps: usize = @intCast(@divTrunc(y1 - y0 - 1, sample_step) + 1);
    const cores = if (use_threads) (std.Thread.getCpuCount() catch 1) else 1;
    const nthreads = @max(@as(usize, 1), @min(cores, total_steps));

    const workers = try alloc.alloc(Worker, nthreads);
    const steps_per = (total_steps + nthreads - 1) / nthreads; // ceil
    const crow0 = @divFloor(y0, 32);
    const crow1 = @divFloor(y1 - 1, 32);
    const crows: usize = @intCast(crow1 - crow0 + 1);
    const crows_per = (crows + nthreads - 1) / nthreads;
    for (workers, 0..) |*w, k| {
        var ya = y0 + @as(i32, @intCast(k * steps_per)) * sample_step;
        var yb = y0 + @as(i32, @intCast((k + 1) * steps_per)) * sample_step;
        if (sample_step == 1) {
            ya = @max(y0, (crow0 + @as(i32, @intCast(k * crows_per))) * 32);
            yb = @min(y1, (crow0 + @as(i32, @intCast((k + 1) * crows_per))) * 32);
            if (ya > yb) ya = yb;
        }
        if (yb > y1) yb = y1;
        w.* = .{
            .states = states,
            .zone_radius = zone_radius,
            .x0 = x0,
            .x1 = x1,
            .ya = @min(ya, y1),
            .yb = yb,
            .sample_step = sample_step,
            .water = water,
            .zone_terrain = zone_terrain,
            .classifier = classifier,
        };
    }

    // Run band 0 on this thread, spawn the rest (single worker on wasm — the
    // spawn branch is comptime-eliminated there so std.Thread never compiles).
    if (nthreads == 1 or !use_threads) {
        workers[0].run();
    } else {
        const threads = try alloc.alloc(std.Thread, nthreads - 1);
        for (threads, workers[1..]) |*t, *w| t.* = try std.Thread.spawn(.{}, Worker.run, .{w});
        workers[0].run();
        for (threads) |t| t.join();
    }

    // Aggregate + report profiling (CPU-time across workers; wall time is
    // roughly cpu/threads). Print is skipped on wasm (no stderr).
    {
        var ne: u64 = 0;
        var nf: u64 = 0;
        var nb: u64 = 0;
        for (workers) |*w| {
            ne += w.n_elev;
            nf += w.n_field;
            nb += w.n_biome;
        }
        if (comptime builtin.os.tag != .freestanding) {
            std.debug.print("# profile counts: field evals {d}, elevation evals {d}, biome classifies {d}\n", .{ nf, ne, nb });
        }
    }

    // Merge worker outputs (in band order) and surface any worker error.
    var total: usize = 0;
    for (workers) |*w| {
        if (w.err) |e| {
            for (workers) |*w2| w2.out.deinit(std.heap.page_allocator);
            return e;
        }
        total += w.out.items.len;
    }
    try results.ensureTotalCapacity(alloc, total);
    for (workers) |*w| {
        results.appendSliceAssumeCapacity(w.out.items);
        w.out.deinit(std.heap.page_allocator);
    }
    return results;
}

// ── GPU ore input serialization ────────────────────────────────────────────
// Hand the CPU-computed per-resource params + precomputed spots to gpu_ore,
// which does the per-tile eval on the GPU. gpu_ore rebuilds each resource's
// basis tables from (map_seed, seed1). Binary (native LE):
//   GpuOreHeader, then per resource: GpuResHeader, name bytes,
//   spots[nspots] (noise.Spot), start_spots[nstart].
pub const GpuOreHeader = extern struct {
    magic: u32 = 0x45524f47, // "GORE"
    nres: u32,
    map_seed: u32,
    is_field: u32,
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    zone_radius: f64,
    // Placement-model constants. Defaults are the SE values, so the SE serializer
    // (which leaves these unset) reproduces the original hardcoded shader exactly.
    // The vanilla (Nauvis) serializer overrides them — same GPU kernel, base-game
    // resource_autoplace tuning: no vein, different fade/starting/double-density.
    mode_vanilla: f64 = 0.0, // 0 = SE, 1 = vanilla (base game)
    double_density: f64 = 5000.0, // double_density_distance (vanilla 1300)
    regular_fade_in: f64 = 320.0, // regular_patch_fade_in_distance (vanilla 300)
    starting_radius: f64 = 140.0, // starting_resource_placement_radius (vanilla 120)
    spot_enlarge_max: f64 = 5320.0, // regular_blob_amplitude_maximum_distance (vanilla 1600)
    reg_vein_w: f64 = 0.8, // regular vein weight (vanilla 0 — no vein)
    start_blob_c: f64 = 0.4, // starting (blobs0-0.25) coefficient (vanilla 1.0)
    start_vein_w: f64 = 0.2, // starting vein weight (vanilla 0 — no vein)
};
pub const GpuResHeader = extern struct {
    base_density: f64,
    freq_mult: f64,
    size_mult: f64,
    base_spots_per_km2: f64,
    rq: f64,
    smin: f64,
    smax: f64,
    basement_value: f64,
    richness_mult: f64,
    additional_richness: f64,
    random_probability: f64,
    starting_blob_amplitude: f64,
    seed1: u32,
    roll_salt: u32,
    has_starting: u32,
    name_len: u32,
    nspots: u32,
    nstart: u32,
    pad0: u32 = 0,
    pad1: u32 = 0,
};

pub fn serializeGpuInput(
    alloc: std.mem.Allocator,
    map_seed: u32,
    zone_radius: f64,
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    resources: []const ResourceInput,
    is_field: bool,
) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(alloc);

    var states: std.ArrayList(ResourceState) = .empty;
    defer {
        for (states.items) |*st| {
            st.spot.deinit();
            if (st.starting_spot) |*ss| ss.deinit();
        }
        states.deinit(alloc);
    }
    for (resources) |res| {
        if (res.controls.size <= 0.0) continue;
        // Fluids (random_probability<1: crude-oil, uranium) are placed via a
        // per-chunk penalty the GPU kernel doesn't do — and the GUI's CPU ore
        // path drops them too (--ores-only). Exclude them from the dump.
        if (res.config.random_probability < 1.0) continue;
        try states.append(alloc, makeResourceStateElev(alloc, map_seed, res.name, res.config, res.controls, null));
    }

    // Same region precompute + flat-spot gather as computeSEOresInRect.
    const rs = SE_REGION_SIZE;
    const rminx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x0)) / rs))) - 1;
    const rmaxx: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(x1 - 1)) / rs))) + 1;
    const rminy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y0)) / rs))) - 1;
    const rmaxy: i32 = @as(i32, @intFromFloat(@round(@as(f64, @floatFromInt(y1 - 1)) / rs))) + 1;
    const fx0: f64 = @floatFromInt(x0);
    const fx1: f64 = @floatFromInt(x1);
    const fy0: f64 = @floatFromInt(y0);
    const fy1: f64 = @floatFromInt(y1);
    for (states.items) |*st| {
        var rx: i32 = rminx;
        while (rx <= rmaxx) : (rx += 1) {
            var ry: i32 = rminy;
            while (ry <= rmaxy) : (ry += 1) _ = try st.spot.spotsForRegion(rx, ry);
        }
        if (st.starting_spot) |*ss| {
            const srs = SE_STARTING_RADIUS * 2.0;
            const sminx: i32 = @as(i32, @intFromFloat(@round(fx0 / srs))) - 1;
            const smaxx: i32 = @as(i32, @intFromFloat(@round((fx1 - 1) / srs))) + 1;
            const sminy: i32 = @as(i32, @intFromFloat(@round(fy0 / srs))) - 1;
            const smaxy: i32 = @as(i32, @intFromFloat(@round((fy1 - 1) / srs))) + 1;
            var srx: i32 = sminx;
            while (srx <= smaxx) : (srx += 1) {
                var sry: i32 = sminy;
                while (sry <= smaxy) : (sry += 1) _ = try ss.spotsForRegion(srx, sry);
            }
        }
        st.all_spots = try st.spot.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
        if (st.starting_spot) |*ss| st.all_start_spots = try ss.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
    }

    const hdr = GpuOreHeader{
        .nres = @intCast(states.items.len),
        .map_seed = map_seed,
        .is_field = if (is_field) 1 else 0,
        .x0 = x0,
        .y0 = y0,
        .x1 = x1,
        .y1 = y1,
        .zone_radius = zone_radius,
    };
    try buf.appendSlice(alloc, std.mem.asBytes(&hdr));
    for (states.items) |*st| {
        const rh = GpuResHeader{
            .base_density = st.spot.field.base_density,
            .freq_mult = st.freq_mult,
            .size_mult = st.size_mult,
            .base_spots_per_km2 = st.spot.field.base_spots_per_km2,
            .rq = st.rq,
            .smin = st.spot.field.smin,
            .smax = st.spot.field.smax,
            .basement_value = st.basement_value,
            .richness_mult = st.richness_mult,
            .additional_richness = st.config.additional_richness,
            .random_probability = st.config.random_probability,
            .starting_blob_amplitude = st.starting_blob_amplitude,
            .seed1 = st.config.seed1,
            .roll_salt = st.roll_salt,
            .has_starting = if (st.starting_spot != null) 1 else 0,
            .name_len = @intCast(st.name.len),
            .nspots = @intCast(st.all_spots.len),
            .nstart = @intCast(st.all_start_spots.len),
        };
        try buf.appendSlice(alloc, std.mem.asBytes(&rh));
        try buf.appendSlice(alloc, st.name);
        try buf.appendSlice(alloc, std.mem.sliceAsBytes(st.all_spots));
        try buf.appendSlice(alloc, std.mem.sliceAsBytes(st.all_start_spots));
    }
    return buf.toOwnedSlice(alloc);
}

// Same wire format as serializeGpuInput, but built from the base-game (vanilla)
// resource_autoplace path (ore_placement.zig) instead of the SE one — for Nauvis.
// The GpuOreHeader carries mode_vanilla=1 plus the vanilla placement constants, so
// gpu_ore's shared kernel evaluates these spots with base-game tuning (no vein,
// fade-in 300, starting radius 120, double-density 1300). Fluids (random_probability
// < 1: crude-oil) are excluded, exactly as the SE dump and the CPU --ores-only path.
pub fn serializeVanillaGpuInput(
    alloc: std.mem.Allocator,
    map_seed: u32,
    zone_radius: f64,
    x0: i32,
    y0: i32,
    x1: i32,
    y1: i32,
    configs: []const ore.ResourceAutoplaceConfig,
    names: []const []const u8,
    controls: []const ore.AutoplaceControls,
    lakes: ?*const terrain.ElevationLakes,
) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(alloc);

    const VState = struct {
        name: []const u8,
        field: ore.Field,
        spot: ore.RegularSpotField,
        sspot: ?ore.StartingSpotField,
        all_spots: []noise.Spot = &.{},
        all_start_spots: []noise.Spot = &.{},
    };
    var states: std.ArrayList(VState) = .empty;
    defer {
        for (states.items) |*st| {
            st.spot.deinit();
            if (st.sspot) |*ss| ss.deinit();
            alloc.free(st.all_spots);
            alloc.free(st.all_start_spots);
        }
        states.deinit(alloc);
    }
    for (configs, names, controls) |cfg, name, ctrl| {
        // Fluids place via a per-chunk penalty the GPU kernel doesn't do (and the
        // CPU --ores-only oracle drops them too) — exclude from the dump.
        if (cfg.random_probability < 1.0) continue;
        const field = ore.Field{
            .config = cfg,
            .controls = .{ .frequency = ctrl.frequency, .size = ctrl.size, .richness = ctrl.richness },
            .map_seed = map_seed,
        };
        const has_start = field.has() == 1;
        try states.append(alloc, .{
            .name = name,
            .field = field,
            .spot = ore.makeRegularSpotField(alloc, field),
            .sspot = if (has_start) ore.makeStartingSpotField(alloc, field, lakes) else null,
        });
    }

    // Gather each resource's spots covering the rect (region pre-pass warms the
    // spot cache, then allSpotsInRect collects those whose cones reach the rect).
    const fx0: f64 = @floatFromInt(x0);
    const fx1: f64 = @floatFromInt(x1);
    const fy0: f64 = @floatFromInt(y0);
    const fy1: f64 = @floatFromInt(y1);
    for (states.items) |*st| {
        const rs = ore.REGULAR_REGION_SIZE;
        const rminx: i32 = @as(i32, @intFromFloat(@round(fx0 / rs))) - 1;
        const rmaxx: i32 = @as(i32, @intFromFloat(@round((fx1 - 1) / rs))) + 1;
        const rminy: i32 = @as(i32, @intFromFloat(@round(fy0 / rs))) - 1;
        const rmaxy: i32 = @as(i32, @intFromFloat(@round((fy1 - 1) / rs))) + 1;
        var rx: i32 = rminx;
        while (rx <= rmaxx) : (rx += 1) {
            var ry: i32 = rminy;
            while (ry <= rmaxy) : (ry += 1) _ = try st.spot.spotsForRegion(rx, ry);
        }
        if (st.sspot) |*ss| {
            const srs = ore.STARTING_RESOURCE_PLACEMENT_RADIUS * 2.0;
            const sminx: i32 = @as(i32, @intFromFloat(@round(fx0 / srs))) - 1;
            const smaxx: i32 = @as(i32, @intFromFloat(@round((fx1 - 1) / srs))) + 1;
            const sminy: i32 = @as(i32, @intFromFloat(@round(fy0 / srs))) - 1;
            const smaxy: i32 = @as(i32, @intFromFloat(@round((fy1 - 1) / srs))) + 1;
            var srx: i32 = sminx;
            while (srx <= smaxx) : (srx += 1) {
                var sry: i32 = sminy;
                while (sry <= smaxy) : (sry += 1) _ = try ss.spotsForRegion(srx, sry);
            }
        }
        st.all_spots = try st.spot.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
        if (st.sspot) |*ss| st.all_start_spots = try ss.allSpotsInRect(alloc, fx0, fx1, fy0, fy1);
    }

    const hdr = GpuOreHeader{
        .nres = @intCast(states.items.len),
        .map_seed = map_seed,
        .is_field = 0,
        .x0 = x0,
        .y0 = y0,
        .x1 = x1,
        .y1 = y1,
        .zone_radius = zone_radius,
        .mode_vanilla = 1.0,
        .double_density = ore.DOUBLE_DENSITY_DISTANCE,
        .regular_fade_in = ore.REGULAR_PATCH_FADE_IN_DISTANCE,
        .starting_radius = ore.STARTING_RESOURCE_PLACEMENT_RADIUS,
        .spot_enlarge_max = ore.DOUBLE_DENSITY_DISTANCE + ore.REGULAR_PATCH_FADE_IN_DISTANCE,
        .reg_vein_w = 0.0, // base game has no vein term
        .start_blob_c = 1.0, // starting_patches = spots + (blobs0 - 0.25) * amp
        .start_vein_w = 0.0,
    };
    try buf.appendSlice(alloc, std.mem.asBytes(&hdr));
    for (states.items) |*st| {
        const f = st.field;
        // FNV-1a of the name → independent placement-roll stream (matches the SE
        // dump and the CPU vanilla path, which salt the per-tile roll the same way).
        var salt: u32 = 2166136261;
        for (st.name) |ch| salt = (salt ^ ch) *% 16777619;
        const rh = GpuResHeader{
            .base_density = f.config.base_density,
            .freq_mult = f.controls.frequency, // vanilla uses raw sliders (no ^0.8)
            .size_mult = f.controls.size,
            .base_spots_per_km2 = f.config.base_spots_per_km2,
            .rq = f.regularRqFactor(),
            .smin = f.config.random_spot_size_minimum,
            .smax = f.config.random_spot_size_maximum,
            .basement_value = f.basementValue(),
            .richness_mult = f.config.richness_post_multiplier * f.controls.richness,
            .additional_richness = f.config.additional_richness,
            .random_probability = f.config.random_probability,
            .starting_blob_amplitude = f.startingBlobAmplitude(),
            .seed1 = f.config.seed1,
            .roll_salt = salt,
            .has_starting = if (st.sspot != null) 1 else 0,
            .name_len = @intCast(st.name.len),
            .nspots = @intCast(st.all_spots.len),
            .nstart = @intCast(st.all_start_spots.len),
        };
        try buf.appendSlice(alloc, std.mem.asBytes(&rh));
        try buf.appendSlice(alloc, st.name);
        try buf.appendSlice(alloc, std.mem.sliceAsBytes(st.all_spots));
        try buf.appendSlice(alloc, std.mem.sliceAsBytes(st.all_start_spots));
    }
    return buf.toOwnedSlice(alloc);
}
