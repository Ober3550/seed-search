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

const pi = std.math.pi;

// ---- SE constants (resource_autoplace_overrides.lua) ----
const SE_BASE_DISTANCE: f64 = 5000.0; // == double_density_distance
const SE_REGULAR_FADE_IN: f64 = 320.0;
const SE_STARTING_RADIUS: f64 = 140.0;
const SE_CANDIDATE_SPOT_COUNT: u32 = 64;
const SE_MIN_CANDIDATE_SPACING: f64 = 128.0; // rs_suggested_minimum_candidate_point_spacing
const SE_SIZE_BOOST: f64 = 4.0;
const SE_MAX_BASEMENT_RADIUS: f64 = 128.0; // regular
const SE_STARTING_AMOUNT: f64 = 100000.0;
const SE_STARTING_SPLIT: f64 = 0.25;
const SE_REGION_SIZE: f64 = 1024.0;

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
};

/// setting_scale(v) = v^0.8 applied to control sliders.
fn slider(v: f64) f64 {
    return std.math.pow(f64, v, 0.8);
}

/// Constant-se_distance evaluator for a single SE resource on a non-home zone.
const SEField = struct {
    density: f64, // regular_density_at(5000), constant
    quantity_base: f64, // regular_spot_quantity_base_at(5000), constant
    rq: f64, // regular_rq_factor
    smin: f64,
    smax: f64,

    pub fn spotDensityAt(self: SEField, x: f64, y: f64) f64 {
        _ = x;
        _ = y;
        return self.density;
    }
    pub fn spotQuantityBaseAt(self: SEField, x: f64, y: f64) f64 {
        _ = x;
        _ = y;
        return self.quantity_base;
    }
    /// spot_radius_expression = size_boost + min(32, rq * q^(1/3))
    pub fn spotRadius(self: SEField, q: f64) f64 {
        return SE_SIZE_BOOST + @min(32.0, self.rq * cbrt(q));
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

/// Precomputed per-resource state for a zone.
const ResourceState = struct {
    name: []const u8,
    config: SEResourceConfig,
    controls: Controls,
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
    basis: noise.BasisNoiseGen,

    fn typicalHeightAt(self_density: f64, rq: f64, smin: f64, smax: f64, base_spots_per_km2: f64, freq_mult: f64) f64 {
        // regular_spot_height_typical_at using a given density.
        const q_base = self_density * 1_000_000.0 / (base_spots_per_km2 * freq_mult);
        return cbrt((smin + smax) / 2.0 * q_base) / (pi / 3.0 * rq * rq);
    }
};

fn makeResourceState(alloc: std.mem.Allocator, map_seed: u32, name: []const u8, cfg: SEResourceConfig, ctrl: Controls) ResourceState {
    const freq_mult = slider(ctrl.frequency);
    const size_mult = slider(ctrl.size);
    const richness_mult = slider(ctrl.richness);

    // regular_density_at(se_distance=5000):
    //   base_density * freq * size * fade(=1) * (1 + clamp(size_eff/5000))
    //   size_eff = 5000 - 320 = 4680 -> clamp(4680/5000)=0.936
    const size_eff = SE_BASE_DISTANCE - SE_REGULAR_FADE_IN;
    const density = cfg.base_density * freq_mult * size_mult *
        (1.0 + clamp01(size_eff / SE_BASE_DISTANCE));

    // regular_spot_quantity_base_at(5000) = density * 1e6 / (base_spots_per_km2 * freq)
    const spots_per_km2 = cfg.base_spots_per_km2 * freq_mult;
    const quantity_base = density * 1_000_000.0 / spots_per_km2;

    const rq = cfg.regular_rq_factor_multiplier / 10.0;

    // regular_blob_amplitude_at(5000) = (1/8) * min(typical(5320), typical(5000))
    // density(5320): size_eff=5000 -> (1+1)=2; density(5000): (1+0.936)=1.936
    const density_5320 = cfg.base_density * freq_mult * size_mult * 2.0;
    const th_5000 = ResourceState.typicalHeightAt(density, rq, cfg.random_spot_size_minimum, cfg.random_spot_size_maximum, cfg.base_spots_per_km2, freq_mult);
    const th_5320 = ResourceState.typicalHeightAt(density_5320, rq, cfg.random_spot_size_minimum, cfg.random_spot_size_maximum, cfg.base_spots_per_km2, freq_mult);
    const blob_amp = (1.0 / 8.0) * @min(th_5000, th_5320);

    // basement_value = -6 * max(regular_blob_amplitude_at(5320), starting_blob_amplitude)
    // regular_blob_amplitude_at(5320) = (1/8)*typical(5320)
    const reg_amp_max = (1.0 / 8.0) * th_5320;
    // starting_blob_amplitude (starting_rq_factor = starting_rq_mult/8, default mult 1 -> 1/8)
    const starting_rq = 1.0 / 8.0;
    const starting_amount = SE_STARTING_AMOUNT * cfg.base_density *
        (((freq_mult - 1.0) * 0.25) + 1.0) * size_mult;
    const starting_area_spot_quantity = starting_amount / SE_STARTING_SPLIT / freq_mult;
    const starting_blob_amplitude = (1.0 / 8.0) / (pi / 3.0 * starting_rq * starting_rq) *
        cbrt(starting_area_spot_quantity);
    const basement_value = -6.0 * @max(reg_amp_max, starting_blob_amplitude);

    const field = SEField{
        .density = density,
        .quantity_base = quantity_base,
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

    return .{
        .name = name,
        .config = cfg,
        .controls = ctrl,
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
        .basis = noise.BasisNoiseGen.init(map_seed, cfg.seed1),
    };
}

/// vein = 1 - 10 * abs(multioctave_noise{input_scale=1/4, persistence=0.5, octaves=6})
fn vein(map_seed: u32, seed1: u32, x: f64, y: f64) f64 {
    const m = noise.multioctaveNoise(x, y, map_seed, seed1, 6, 0.5, 1.0 / 4.0, 1.0);
    return 1.0 - 10.0 * @abs(m);
}

/// all_patches value at (x,y) for a resource. Regular patches only (non-home).
fn allPatchesValue(st: *ResourceState, x: f64, y: f64) !f64 {
    const spot_v = try st.spot.evalAt(x, y);
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const blob = blobs0 + st.basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0 +
        0.8 * vein(st.map_seed, st.config.seed1, x, y) * st.config.random_probability;
    return spot_v + blob * st.blob_amplitude;
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

/// Generate SE ore for a zone surface. `map_seed` is the zone seed.
/// Placement is bounded to a disk of `zone_radius` (the moon/planet surface).
pub fn computeSEOresInRect(
    alloc: std.mem.Allocator,
    map_seed: u32,
    zone_radius: f64,
    x0: i32, y0: i32,
    x1: i32, y1: i32,
    resources: []const ResourceInput,
) !std.ArrayList(OreEntity) {
    var results: std.ArrayList(OreEntity) = .empty;

    for (resources) |res| {
        if (res.controls.size <= 0.0) continue; // (control:X:size > 0) gate
        var st = makeResourceState(alloc, map_seed, res.name, res.config, res.controls);
        defer st.spot.deinit();

        // richness distance multiplier = max(1, (5000 + (5000-320)) / 10000) = 1 (constant)
        const richness_distance: f64 = @max(1.0, (SE_BASE_DISTANCE + (SE_BASE_DISTANCE - SE_REGULAR_FADE_IN)) / (SE_BASE_DISTANCE * 2.0));

        var y: i32 = y0;
        while (y < y1) : (y += 1) {
            var x: i32 = x0;
            while (x < x1) : (x += 1) {
                const fx: f64 = @floatFromInt(x);
                const fy: f64 = @floatFromInt(y);
                if (dist0(fx, fy) > zone_radius) continue; // outside the surface

                const value = try allPatchesValue(&st, fx, fy);
                const probability = clamp01(value);
                if (probability <= 0.0) continue;

                var richness = value;
                if (res.config.random_probability < 1.0) richness /= res.config.random_probability;
                if (res.config.additional_richness > 0.0) richness += res.config.additional_richness;
                richness *= richness_distance * st.richness_mult;

                const amount: u32 = @intFromFloat(@floor(richness));
                if (amount > 0) {
                    try results.append(alloc, .{ .x = x, .y = y, .resource_name = res.name, .amount = amount });
                }
            }
        }
    }
    return results;
}
