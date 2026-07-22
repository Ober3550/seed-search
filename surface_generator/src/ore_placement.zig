//! Factorio resource autoplace — ore placement via spot noise (FFF #258 algorithm).
const std = @import("std");
const noise = @import("noise.zig");

pub const AutoplaceControls = struct {
    frequency: f64 = 1.0, size: f64 = 1.0, richness: f64 = 1.0,
};

pub const ResourceAutoplaceConfig = struct {
    base_density: f64, seed1: u32 = 100,
    base_spots_per_km2: f64 = 2.5, candidate_spot_count: u32 = 21,
    regular_rq_factor_multiplier: f64 = 1.0,
    random_probability: f64 = 1.0, additional_richness: f64 = 0.0, richness_post_multiplier: f64 = 1.0,
};

pub const iron_ore_default = ResourceAutoplaceConfig{ .base_density = 10.0, .candidate_spot_count = 22, .regular_rq_factor_multiplier = 1.10 };
pub const copper_ore_default = ResourceAutoplaceConfig{ .base_density = 8.0, .candidate_spot_count = 22, .regular_rq_factor_multiplier = 1.10 };
pub const coal_default = ResourceAutoplaceConfig{ .base_density = 8.0, .regular_rq_factor_multiplier = 1.0 };
pub const stone_default = ResourceAutoplaceConfig{ .base_density = 4.0, .regular_rq_factor_multiplier = 1.0 };
pub const uranium_ore_default = ResourceAutoplaceConfig{ .base_density = 0.9, .base_spots_per_km2 = 1.25 };

const DOUBLE_DENSITY_DISTANCE: f64 = 1300.0;

fn regularDensityAt(distance: f64, config: ResourceAutoplaceConfig, controls: AutoplaceControls) f64 {
    return config.base_density * controls.frequency * controls.size * (1.0 + @min(1.0, distance / DOUBLE_DENSITY_DISTANCE));
}

fn regularSpotQuantity(distance: f64, config: ResourceAutoplaceConfig, controls: AutoplaceControls) f64 {
    return 1.125 * (1_000_000.0 / config.base_spots_per_km2 / controls.frequency) * regularDensityAt(distance, config, controls);
}

fn regularSpotRadius(quantity: f64, rq_factor: f64) f64 {
    const r = rq_factor * std.math.pow(f64, quantity, 1.0 / 3.0);
    return if (r > 32.0) 32.0 else r;
}

pub fn computeOreAt(alloc: std.mem.Allocator, map_seed: u32, x: f64, y: f64, distance: f64, config: ResourceAutoplaceConfig, controls: AutoplaceControls) !f64 {
    if (controls.size <= 0.0) return 0.0;
    const rq = config.regular_rq_factor_multiplier / 10.0;
    const density = regularDensityAt(distance, config, controls);
    const spot_qty = regularSpotQuantity(distance, config, controls);
    const spot_r = regularSpotRadius(spot_qty, rq);
    const blob = noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 8.0, 1.0) + noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 24.0, 1.0);
    const blob_amp = (1.0 / 8.0) / (std.math.pi / 3.0 * rq * rq) * std.math.pow(f64, spot_qty, 1.0 / 3.0);
    const rx = @floor(x / 1024.0);
    const ry = @floor(y / 1024.0);
    var spots = try noise.generateSpots(alloc, rx, ry, map_seed, 1024.0, config.candidate_spot_count, density, spot_qty, spot_r);
    defer spots.deinit(alloc);
    var value = noise.spotNoise(x, y, spots.items, -1.0 * blob_amp);
    value += (blob - 0.25) * blob_amp;
    if (config.random_probability < 1.0) value = noise.randomPenalty(x, y, value, 1.0 / config.random_probability);
    const prob = @max(0.0, @min(1.0, value));
    if (prob <= 0.0) return 0.0;
    var richness = value;
    if (config.random_probability < 1.0) richness /= config.random_probability;
    if (config.additional_richness > 0.0) richness += config.additional_richness;
    richness *= config.richness_post_multiplier * controls.richness;
    return richness * @max((DOUBLE_DENSITY_DISTANCE + distance) / (DOUBLE_DENSITY_DISTANCE * 2.0), 1.0);
}

pub const OreEntity = struct { x: i32, y: i32, resource_name: []const u8, amount: u32 };

pub fn computeOresInRect(alloc: std.mem.Allocator, map_seed: u32, x0: i32, y0: i32, x1: i32, y1: i32, resources: []const ResourceAutoplaceConfig, resource_names: []const []const u8, controls: AutoplaceControls) !std.ArrayList(OreEntity) {
    var results: std.ArrayList(OreEntity) = .empty;
    var y: i32 = y0;
    while (y < y1) : (y += 1) {
        var x: i32 = x0;
        while (x < x1) : (x += 1) {
            const fx: f64 = @floatFromInt(x);
            const fy: f64 = @floatFromInt(y);
            const d = @sqrt(fx * fx + fy * fy);
            for (resources, resource_names) |cfg, name| {
                const r = try computeOreAt(alloc, map_seed, fx, fy, d, cfg, controls);
                if (r > 0.0) {
                    const a: u32 = @intFromFloat(@floor(r));
                    if (a > 0) try results.append(alloc, .{ .x = x, .y = y, .resource_name = name, .amount = a });
                }
            }
        }
    }
    return results;
}
