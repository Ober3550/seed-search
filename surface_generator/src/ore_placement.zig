//! Factorio resource autoplace — ore placement via spot noise.
//!
//! Implements the resource autoplace algorithm from Factorio's data stage.
//! Constants sourced from base/prototypes/entity/resources.lua.
//!
//! Ore placement uses spot_noise with parameters from autoplace controls
//! (frequency, size, richness) and resource-specific settings.

const std = @import("std");
const rng = @import("rng.zig");
const noise = @import("noise.zig");

pub const AutoplaceControls = struct {
    frequency: f64 = 1.0,
    size: f64 = 1.0,
    richness: f64 = 1.0,
};

pub const ResourceAutoplaceConfig = struct {
    base_density: f64,
    seed1: u32,
    base_spots_per_km2: f64 = 2.5,
    candidate_spot_count: u32 = 21,
    regular_rq_factor_multiplier: f64 = 1.0,
    starting_rq_factor_multiplier: f64 = 1.0,
    has_starting_area_placement: bool = false,
    random_probability: f64 = 1.0,
    additional_richness: f64 = 0.0,
    richness_post_multiplier: f64 = 1.0,
};

// Exact values from base/prototypes/entity/resources.lua
pub const iron_ore_default = ResourceAutoplaceConfig{
    .base_density = 10.0, .seed1 = 100, .candidate_spot_count = 22,
    .regular_rq_factor_multiplier = 1.10, .starting_rq_factor_multiplier = 1.5,
    .has_starting_area_placement = true,
};
pub const copper_ore_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .seed1 = 200, .candidate_spot_count = 22,
    .regular_rq_factor_multiplier = 1.10, .starting_rq_factor_multiplier = 1.2,
    .has_starting_area_placement = true,
};
pub const coal_default = ResourceAutoplaceConfig{
    .base_density = 8.0, .seed1 = 300,
    .regular_rq_factor_multiplier = 1.0, .starting_rq_factor_multiplier = 1.1,
    .has_starting_area_placement = true,
};
pub const stone_default = ResourceAutoplaceConfig{
    .base_density = 4.0, .seed1 = 400,
    .regular_rq_factor_multiplier = 1.0, .starting_rq_factor_multiplier = 1.1,
    .has_starting_area_placement = true,
};
pub const uranium_ore_default = ResourceAutoplaceConfig{
    .base_density = 0.9, .seed1 = 500, .base_spots_per_km2 = 1.25,
    .has_starting_area_placement = false,
};
pub const crude_oil_default = ResourceAutoplaceConfig{
    .base_density = 8.2, .seed1 = 600, .base_spots_per_km2 = 1.8,
    .random_probability = 1.0 / 48.0, .additional_richness = 220000,
    .has_starting_area_placement = false,
};

const DOUBLE_DENSITY_DISTANCE: f64 = 1300.0;
const REGULAR_PATCH_FADE_IN_DISTANCE: f64 = 300.0;
const STARTING_RESOURCE_PLACEMENT_RADIUS: f64 = 120.0;

fn regularDensityAt(distance: f64, base_density: f64, frequency: f64, size: f64, spots_per_km2: f64) f64 {
    const base = base_density * frequency * spots_per_km2 / 1000.0;
    const dist_factor = if (distance < REGULAR_PATCH_FADE_IN_DISTANCE)
        distance / REGULAR_PATCH_FADE_IN_DISTANCE
    else
        1.0 + (distance - REGULAR_PATCH_FADE_IN_DISTANCE) / (DOUBLE_DENSITY_DISTANCE - REGULAR_PATCH_FADE_IN_DISTANCE);
    return base * dist_factor * size;
}

fn regularSpotQuantity(distance: f64, config: ResourceAutoplaceConfig, controls: AutoplaceControls) f64 {
    const density = regularDensityAt(distance, config.base_density, controls.frequency, controls.size, config.base_spots_per_km2);
    return density * 1024.0 * 1024.0 / @as(f64, @floatFromInt(config.candidate_spot_count));
}

fn regularSpotRadius(quantity: f64, rq_factor: f64) f64 {
    var radius = rq_factor * std.math.pow(f64, quantity, 1.0 / 3.0);
    if (radius > 32.0) radius = 32.0;
    return radius;
}

/// Compute ore richness at a single tile position.
pub fn computeOreAt(
    alloc: std.mem.Allocator,
    map_seed: u32,
    x: f64, y: f64,
    distance: f64,
    config: ResourceAutoplaceConfig,
    controls: AutoplaceControls,
) !f64 {
    if (controls.size <= 0.0) return 0.0;

    const rq = config.regular_rq_factor_multiplier / 10.0;
    const start_rq = config.starting_rq_factor_multiplier / 7.0;
    var value: f64 = 0.0;

    // Starting area patches
    if (config.has_starting_area_placement and distance < STARTING_RESOURCE_PLACEMENT_RADIUS) {
        const amount = 20000.0 * config.base_density * (controls.frequency + 1.0) * controls.size;
        const spot_qty = amount / 0.5 / controls.frequency;
        const spot_r = start_rq * std.math.pow(f64, spot_qty, 1.0 / 3.0);
        const blob = noise.basisNoise(x, y, map_seed, config.seed1 + 1, 1.0 / 8.0, 1.0) +
            noise.basisNoise(x, y, map_seed, config.seed1 + 1, 1.0 / 24.0, 1.0);
        const blob_amp = (1.0 / 8.0) / (std.math.pi / 3.0 * start_rq * start_rq) *
            std.math.pow(f64, spot_qty, 1.0 / 3.0);
        const favorability = @max(0.0, 1.0 - distance / STARTING_RESOURCE_PLACEMENT_RADIUS);

        value = try noise.spotNoise(alloc, x, y, map_seed, config.seed1 + 1,
            STARTING_RESOURCE_PLACEMENT_RADIUS * 2.0, 64,
            amount / (std.math.pi * STARTING_RESOURCE_PLACEMENT_RADIUS * STARTING_RESOURCE_PLACEMENT_RADIUS),
            spot_qty, spot_r, favorability,
            -1.0 * blob_amp, 128.0);
        value += (blob - 0.25) * blob_amp;
    } else {
        // Regular patches
        const density = regularDensityAt(distance, config.base_density, controls.frequency, controls.size, config.base_spots_per_km2);
        const spot_qty = regularSpotQuantity(distance, config, controls);
        const spot_r = regularSpotRadius(spot_qty, rq);
        const blob = noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 8.0, 1.0) +
            noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 24.0, 1.0);
        const blob_amp = (1.0 / 8.0) / (std.math.pi / 3.0 * rq * rq) *
            std.math.pow(f64, spot_qty, 1.0 / 3.0);

        value = try noise.spotNoise(alloc, x, y, map_seed, config.seed1,
            1024.0, config.candidate_spot_count,
            density, spot_qty, spot_r, 1.0,
            -1.0 * blob_amp, 128.0);
        value += (blob - 0.25) * blob_amp;
    }

    // Probability and richness
    if (config.random_probability < 1.0) {
        value = noise.randomPenalty(x, y, value, 1.0 / config.random_probability);
    }
    const probability = @max(0.0, @min(1.0, value));
    if (probability <= 0.0) return 0.0;

    var richness = value;
    if (config.random_probability < 1.0) richness /= config.random_probability;
    if (config.additional_richness > 0.0) richness += config.additional_richness;
    richness *= config.richness_post_multiplier * controls.richness;
    const dist_mult = @max((DOUBLE_DENSITY_DISTANCE + distance) / (DOUBLE_DENSITY_DISTANCE * 2.0), 1.0);
    richness *= dist_mult;

    return richness;
}

// ============================================================
// Batch ore computation for a region
// ============================================================

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

    var y: i32 = y0;
    while (y < y1) : (y += 1) {
        var x: i32 = x0;
        while (x < x1) : (x += 1) {
            const fx: f64 = @floatFromInt(x);
            const fy: f64 = @floatFromInt(y);
            const distance = @sqrt(fx * fx + fy * fy);

            for (resources, resource_names) |config, name| {
                const richness = try computeOreAt(alloc, map_seed, fx, fy, distance, config, controls);
                if (richness > 0.0) {
                    const amount: u32 = @intFromFloat(@floor(richness));
                    if (amount > 0) {
                        try results.append(alloc, .{ .x = x, .y = y, .resource_name = name, .amount = amount });
                    }
                }
            }
        }
    }

    return results;
}

test "computeOreAt zero for size=0" {
    const c = AutoplaceControls{ .size = 0.0 };
    const r = try computeOreAt(std.testing.allocator, 341, 100, 100, 100, iron_ore_default, c);
    try std.testing.expectEqual(0.0, r);
}
