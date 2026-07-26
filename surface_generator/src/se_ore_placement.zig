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

const pi = std.math.pi;

// ---- SE constants (resource_autoplace_overrides.lua) ----
pub const SE_BASE_DISTANCE: f64 = 5000.0; // == double_density_distance
pub const SE_REGULAR_FADE_IN: f64 = 320.0;
pub const SE_STARTING_RADIUS: f64 = 140.0;
pub const SE_CANDIDATE_SPOT_COUNT: u32 = 64;
pub const SE_MIN_CANDIDATE_SPACING: f64 = 128.0; // rs_suggested_minimum_candidate_point_spacing
pub const SE_SIZE_BOOST: f64 = 4.0;
pub const SE_MAX_BASEMENT_RADIUS: f64 = 128.0; // regular
pub const SE_STARTING_AMOUNT: f64 = 100000.0;
pub const SE_STARTING_SPLIT: f64 = 0.25;
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

    /// se_distance = min(distance_from_center, base_distance).
    fn seDistance(x: f64, y: f64) f64 {
        return @min(@sqrt(x * x + y * y), SE_BASE_DISTANCE);
    }

    /// regular_density_at(distance). has_starting_area_placement is 0 or 1 for
    /// every resource here (never -1), so the fade and size_effective_distance
    /// both use the "else" branch: fade over [starting_radius, +fade_in],
    /// size_effective = distance - fade_in.
    fn regularDensityAt(self: SEField, dist: f64) f64 {
        const fade = clamp01((dist - SE_STARTING_RADIUS) / SE_REGULAR_FADE_IN);
        const size_eff = dist - SE_REGULAR_FADE_IN;
        const doubling = 1.0 + clamp01(size_eff / SE_BASE_DISTANCE);
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
        const max_dist = SE_BASE_DISTANCE + SE_REGULAR_FADE_IN; // regular_blob_amplitude_maximum_distance = 5320
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

pub fn makeResourceState(alloc: std.mem.Allocator, map_seed: u32, name: []const u8, cfg: SEResourceConfig, ctrl: Controls) ResourceState {
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
    const spot_v = try st.spot.evalAt(x, y);
    const blobs0 = st.basis.eval(x, y, 1.0 / 8.0, 1.0) + st.basis.eval(x, y, 1.0 / 24.0, 1.0);
    const blob = blobs0 + st.basis.eval(x, y, 1.0 / 64.0, 1.5) - 1.0 / 3.0 +
        0.8 * vein(&st.basis, x, y) * st.config.random_probability;
    return spot_v + blob * st.spot.field.blobAmplitudeAt(x, y);
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

// richness distance multiplier = max(1, (5000 + (5000-320)) / 10000) = 1 (constant,
// because se_distance is a constant 5000 on non-home zones).
const RICHNESS_DISTANCE: f64 = @max(1.0, (SE_BASE_DISTANCE + (SE_BASE_DISTANCE - SE_REGULAR_FADE_IN)) / (SE_BASE_DISTANCE * 2.0));

/// Evaluate one resource at one tile. Read-only w.r.t. `st` once its spot cache
/// has been pre-populated (see computeSEOresInRect), so this is safe to call
/// concurrently from multiple threads on shared ResourceStates.
fn evalTileForState(st: *ResourceState, x: i32, y: i32, fx: f64, fy: f64) !?OreEntity {
    const value = try allPatchesValue(st, fx, fy);
    if (clamp01(value) <= 0.0) return null;

    var richness = value;
    if (st.config.random_probability < 1.0) richness /= st.config.random_probability;
    if (st.config.additional_richness > 0.0) richness += st.config.additional_richness;
    richness *= RICHNESS_DISTANCE * st.richness_mult;

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
        states_buf[ns] = makeResourceState(alloc, map_seed, res.name, res.config, res.controls);
        ns += 1;
    }
    const states = states_buf[0..ns];
    defer for (states) |*st| st.spot.deinit();
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
