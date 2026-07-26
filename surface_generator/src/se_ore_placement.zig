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
const noise = @import("noise.zig");
const terrain = @import("terrain.zig");
const biome = @import("biome.zig");
const rng = @import("rng.zig");

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

// ---- SE constants (SE resource-autoplace.lua, prototypes/phase-1/entity) ----
pub const SE_DOUBLE_DENSITY: f64 = 1300.0; // double_density_distance
pub const SE_REGULAR_FADE_IN: f64 = 300.0; // regular_patch_fade_in_distance
pub const SE_STARTING_RADIUS: f64 = 120.0; // starting_resource_placement_radius
// regular_blob_amplitude_maximum_distance = spot_enlargement_maximum_distance.
// = double_density_distance, + fade_in when has_starting_area_placement is set
// (all our resources set it 0 or 1, never nil) -> 1600.
pub const SE_SPOT_ENLARGE_MAX: f64 = SE_DOUBLE_DENSITY + SE_REGULAR_FADE_IN;
pub const SE_CANDIDATE_SPOT_COUNT: u32 = 64;
pub const SE_MIN_CANDIDATE_SPACING: f64 = 128.0; // rs_suggested_minimum_candidate_point_spacing
pub const SE_SIZE_BOOST: f64 = 4.0;
pub const SE_MAX_BASEMENT_RADIUS: f64 = 128.0; // regular
pub const SE_STARTING_AMOUNT: f64 = 20000.0; // starting_amount coefficient
pub const SE_STARTING_SPLIT: f64 = 0.5; // starting_patches_split
pub const SE_STARTING_CANDIDATE_COUNT: u32 = 32; // starting candidate_spot_count
pub const SE_STARTING_CANDIDATE_SPACING: f64 = 32.0; // suggested_minimum_candidate_point_spacing
pub const SE_REGION_SIZE: f64 = 1024.0;
pub const VEIN_OCTAVES: usize = 6; // multioctave_noise octaves for the vein term

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

/// Control multipliers (frequency/size/richness) are used DIRECTLY in the noise
/// expressions (var('control:X:frequency') etc.) — no ^0.8 transform.
fn slider(v: f64) f64 {
    return v;
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
    /// spot_radius_expression = size_boost + min(32, rq * q^(1/3))
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

/// Starting-area guaranteed patches (base-game resource_autoplace_all_patches
/// starting_patches). Placed near spawn (dist < starting_radius) with a hard
/// region-target quantity. density = starting_density inside the radius (step),
/// spot quantity constant, favorability gates to land (elevation > 1) and
/// prefers the center. Needs elevation for the feasibility term.
const StartingField = struct {
    starting_density: f64,
    spot_quantity: f64, // starting_area_spot_quantity (constant)
    rq_factor: f64, // starting_rq_factor
    elev: *const terrain.Elevation,

    fn modulation(x: f64, y: f64) f64 {
        // starting_modulation = starting_resource_placement_radius > distance
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
        // starting_rq_factor * starting_area_spot_quantity^(1/3) (no min(32)/boost)
        return self.rq_factor * cbrt(q);
    }
    pub fn favorability(self: StartingField, x: f64, y: f64) f64 {
        const mod = modulation(x, y);
        const feasibility = clamp01((self.elev.at(x, y) - 1.0) / 10.0) * mod;
        // random_penalty_at(0.5, seed=1) = 0.5 - r*0.5, r per-tile uniform.
        const rp = noise.randomPenaltySeeded(x, y, 0.5, 0.5, 1);
        return feasibility * 2.0 - dist0(x, y) / SE_STARTING_RADIUS + rp;
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

    // Reference density at regular_blob_amplitude_maximum_distance (=1600):
    //   fade=1, size_eff = clamp(1600-300,0,1600)=1300 -> doubling = 1+1300/1300 = 2.
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
    // Starting-area values (base-game resource_autoplace_all_patches):
    //   starting_amount = 20000 * base_density * (freq+1) * size
    //   starting_area_spot_quantity = starting_amount / 0.5 / freq
    //   starting_rq_factor = starting_rq_factor_multiplier / 7
    //   starting_blob_amplitude = (1/8) / (pi/3 * srq^2) * ssq^(1/3)
    const starting_rq = cfg.starting_rq_factor_multiplier / 7.0;
    const starting_amount = SE_STARTING_AMOUNT * cfg.base_density *
        (freq_mult + 1.0) * size_mult;
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

    // Guaranteed starting patches (only when the resource has them AND we have
    // elevation for the feasibility term). region_size = 2*starting_radius, hard
    // target, seed1+1, its own starting patch-set stride.
    var starting_spot: ?StartingSpotField = null;
    if (cfg.has_starting_area_placement) {
        if (elev) |e| {
            const starting_density = starting_amount / (pi * SE_STARTING_RADIUS * SE_STARTING_RADIUS);
            starting_spot = StartingSpotField{
                .alloc = alloc,
                .field = StartingField{
                    .starting_density = starting_density,
                    .spot_quantity = starting_area_spot_quantity,
                    .rq_factor = starting_rq,
                    .elev = e,
                },
                .seed0 = map_seed,
                .seed1 = cfg.seed1 + 1,
                .region_size = SE_STARTING_RADIUS * 2.0,
                .candidate_spot_count = SE_STARTING_CANDIDATE_COUNT,
                .skip_span = cfg.starting_patch_set_count,
                .skip_offset = cfg.starting_patch_set_index,
                .hard_region_target_quantity = true,
                .basement_value = basement_value,
                .maximum_spot_basement_radius = SE_MAX_BASEMENT_RADIUS,
                .min_candidate_spacing = SE_STARTING_CANDIDATE_SPACING,
            };
        }
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
    // SE regular_patches = regular_spots + blobs1f * regular_blob_amplitude,
    // blobs1f = basis(1/8) + basis(1/24) + basis(1/64,1.5) - 1/3. There is NO
    // extra vein/high-frequency term — random_probability applies a multiplicative
    // random_penalty to PROBABILITY (see evalTileForState), not to the blob.
    const spot_v = try st.spot.evalAt(x, y);
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const blob = blobs0 + st.basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0;
    const regular = spot_v + blob * st.spot.field.blobAmplitudeAt(x, y);
    // all_patches = max(starting_patches, regular_patches). starting_patches =
    // starting_spots + (blobs0 - 0.25) * starting_blob_amplitude.
    if (st.starting_spot) |*ss| {
        const start_spot_v = try ss.evalAt(x, y);
        const starting = start_spot_v + (blobs0 - 0.25) * st.starting_blob_amplitude;
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
    const dist = @sqrt(x * x + y * y);
    const sed = dist - SE_REGULAR_FADE_IN;
    return @max(1.0, (SE_DOUBLE_DENSITY + sed) / (SE_DOUBLE_DENSITY + SE_SPOT_ENLARGE_MAX));
}

/// Evaluate one resource at one tile. Read-only w.r.t. `st` once its spot cache
/// has been pre-populated (see computeSEOresInRect), so this is safe to call
/// concurrently from multiple threads on shared ResourceStates.
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

    fn run(self: *Worker) void {
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

    // Decide worker count from the row (step) budget and CPU cores.
    const total_steps: usize = @intCast(@divTrunc(y1 - y0 - 1, sample_step) + 1);
    const cores = std.Thread.getCpuCount() catch 1;
    const nthreads = @max(@as(usize, 1), @min(cores, total_steps));

    const workers = try alloc.alloc(Worker, nthreads);
    const steps_per = (total_steps + nthreads - 1) / nthreads; // ceil
    for (workers, 0..) |*w, k| {
        const ya = y0 + @as(i32, @intCast(k * steps_per)) * sample_step;
        var yb = y0 + @as(i32, @intCast((k + 1) * steps_per)) * sample_step;
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

    // Run band 0 on this thread, spawn the rest.
    if (nthreads == 1) {
        workers[0].run();
    } else {
        const threads = try alloc.alloc(std.Thread, nthreads - 1);
        for (threads, workers[1..]) |*t, *w| t.* = try std.Thread.spawn(.{}, Worker.run, .{w});
        workers[0].run();
        for (threads) |t| t.join();
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
