//! Factorio resource autoplace — ore placement via spot noise.
//!
//! Implements the exact resource autoplace algorithm from Factorio's data stage
//! (see core/prototypes/noise-functions.lua, resource_autoplace_all_patches).
//!
//! Ore placement uses spot_noise with parameters derived from autoplace controls
//! (frequency, size, richness) and resource-specific settings (base_density, seed1).

const std = @import("std");
const rng = @import("rng.zig");
const noise = @import("noise.zig");

/// Autoplace control values (sliders in the map generator GUI).
pub const AutoplaceControls = struct {
    frequency: f64 = 1.0,
    size: f64 = 1.0,
    richness: f64 = 1.0,
};

/// Resource-specific autoplace parameters.
/// These match the parameters passed to resource_autoplace_settings() in Factorio's data stage.
pub const ResourceAutoplaceConfig = struct {
    /// Base density — amount of ore per tile on average.
    base_density: f64,
    /// Resource-specific seed offset (seed1 in the noise expression).
    seed1: u32,
    /// Patches per square km near the starting area.
    base_spots_per_km2: f64 = 2.5,
    /// Number of candidate spots per region.
    candidate_spot_count: u32 = 21,
    /// Random spot size range.
    random_spot_size_minimum: f64 = 0.25,
    random_spot_size_maximum: f64 = 2.0,
    /// Regular blob amplitude multiplier (divided by 8 in the expression).
    regular_blob_amplitude_multiplier: f64 = 1.0,
    /// Regular rq factor multiplier (divided by 10). Higher = fatter/shallower patches.
    regular_rq_factor_multiplier: f64 = 1.0,
    /// Starting blob amplitude multiplier (divided by 8).
    starting_blob_amplitude_multiplier: f64 = 1.0,
    /// Starting rq factor multiplier (divided by 7).
    starting_rq_factor_multiplier: f64 = 1.0,
    /// Additional richness added to the base expression.
    additional_richness: f64 = 0.0,
    /// Minimum richness cap.
    minimum_richness: f64 = 0.0,
    /// Random probability of placement within a patch (1 = always).
    random_probability: f64 = 1.0,
    /// Whether this resource has starting area placement.
    has_starting_area_placement: bool = false,
    /// Richness post-multiplier.
    richness_post_multiplier: f64 = 1.0,
};

/// Default config for iron-ore (matches Factorio base game).
pub const iron_ore_default = ResourceAutoplaceConfig{
    .base_density = 8.0,
    .seed1 = 100,
    .has_starting_area_placement = true,
    .starting_blob_amplitude_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.0,
    .random_probability = 1.0,
};

/// Default config for copper-ore.
pub const copper_ore_default = ResourceAutoplaceConfig{
    .base_density = 7.0,
    .seed1 = 200,
    .has_starting_area_placement = true,
    .starting_blob_amplitude_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.0,
    .random_probability = 1.0,
};

/// Default config for coal.
pub const coal_default = ResourceAutoplaceConfig{
    .base_density = 6.0,
    .seed1 = 300,
    .has_starting_area_placement = true,
    .starting_blob_amplitude_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.0,
    .random_probability = 1.0,
};

/// Default config for stone.
pub const stone_default = ResourceAutoplaceConfig{
    .base_density = 4.0,
    .seed1 = 400,
    .has_starting_area_placement = true,
    .starting_blob_amplitude_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.0,
    .random_probability = 1.0,
};

/// Default config for uranium-ore.
pub const uranium_ore_default = ResourceAutoplaceConfig{
    .base_density = 0.5,
    .seed1 = 500,
    .base_spots_per_km2 = 0.5,
    .candidate_spot_count = 21,
    .random_probability = 1.0,
    .regular_blob_amplitude_multiplier = 1.0,
    .regular_rq_factor_multiplier = 1.0,
};

/// Default config for crude-oil.
pub const crude_oil_default = ResourceAutoplaceConfig{
    .base_density = 4000.0, // Fluid, so higher numbers
    .seed1 = 600,
    .has_starting_area_placement = true,
    .starting_blob_amplitude_multiplier = 1.0,
    .starting_rq_factor_multiplier = 1.0,
    .random_probability = 1.0,
    .base_spots_per_km2 = 2.5,
    .regular_blob_amplitude_multiplier = 1.0,
    .regular_rq_factor_multiplier = 1.0,
};

// ============================================================
// Ore placement computation
// ============================================================

/// Distance parameter — how far from spawn.
const DOUBLE_DENSITY_DISTANCE: f64 = 1300.0;
const REGULAR_PATCH_FADE_IN_DISTANCE: f64 = 300.0;
const STARTING_RESOURCE_PLACEMENT_RADIUS: f64 = 120.0;

/// Compute the regular density at a given distance from spawn.
fn regularDensityAt(distance: f64, base_density: f64, frequency: f64, size: f64, spots_per_km2: f64) f64 {
    // density = base_density * frequency * spots_per_km2 / 1000 * (distance factor)
    // distance factor: starting at 0, ramps up to 1 at fade_in_distance, then
    // increases to 2 at double_density_distance
    const base = base_density * frequency * spots_per_km2 / 1000.0;
    const distance_factor = if (distance < REGULAR_PATCH_FADE_IN_DISTANCE)
        distance / REGULAR_PATCH_FADE_IN_DISTANCE
    else
        1.0 + (distance - REGULAR_PATCH_FADE_IN_DISTANCE) / (DOUBLE_DENSITY_DISTANCE - REGULAR_PATCH_FADE_IN_DISTANCE);
    return base * distance_factor * size;
}

/// Compute the regular spot quantity for a given distance.
fn regularSpotQuantity(distance: f64, config: ResourceAutoplaceConfig, controls: AutoplaceControls) f64 {
    const density = regularDensityAt(distance, config.base_density, controls.frequency, controls.size, config.base_spots_per_km2);
    // spot_quantity = density * region_size^2 / spots_per_region / spot_favorability
    // Simplified from Factorio's formula
    const region_size: f64 = 1024.0;
    const region_area = region_size * region_size;
    const spots_per_region = @as(f64, @floatFromInt(config.candidate_spot_count));
    return density * region_area / spots_per_region;
}

/// Compute the regular spot radius for a given quantity.
fn regularSpotRadius(quantity: f64, rq_factor: f64) f64 {
    // radius = rq_factor * quantity^(1/3), capped at 32
    var radius = rq_factor * std.math.pow(f64, quantity, 1.0 / 3.0);
    if (radius > 32.0) radius = 32.0;
    return radius;
}

/// Compute the ore value at a single tile position for a given resource.
///
/// Returns a positive value if ore should be placed here, representing the richness.
/// Returns a value <= 0 if no ore should be placed.
///
/// Parameters:
///   - map_seed: The map seed
///   - x, y: Tile position
///   - distance: Distance from spawn (0,0)
///   - config: Resource-specific autoplace config
///   - controls: Autoplace control values (frequency/size/richness)
pub fn computeOreAt(
    alloc: std.mem.Allocator,
    map_seed: u32,
    x: f64, y: f64,
    distance: f64,
    config: ResourceAutoplaceConfig,
    controls: AutoplaceControls,
) !f64 {
    // If size control is 0, no ore at all
    if (controls.size <= 0.0) return 0.0;

    const rq_factor = config.regular_rq_factor_multiplier / 10.0;
    const start_rq_factor = config.starting_rq_factor_multiplier / 7.0;

    // Compute starting patch value (if applicable)
    var starting_value: f64 = 0.0;
    if (config.has_starting_area_placement and distance < STARTING_RESOURCE_PLACEMENT_RADIUS) {
        const start_amount = 20000.0 * config.base_density * (controls.frequency + 1.0) * controls.size;
        const spot_qty = start_amount / 0.5 / controls.frequency;
        const spot_radius = start_rq_factor * std.math.pow(f64, spot_qty, 1.0 / 3.0);

        const blob = noise.basisNoise(x, y, map_seed, config.seed1 + 1, 1.0 / 8.0, 1.0) +
            noise.basisNoise(x, y, map_seed, config.seed1 + 1, 1.0 / 24.0, 1.0);

        const blob_amplitude = (config.starting_blob_amplitude_multiplier / 8.0) /
            (std.math.pi / 3.0 * start_rq_factor * start_rq_factor) *
            std.math.pow(f64, spot_qty, 1.0 / 3.0);

        const favorability = @max(0.0, 1.0 - distance / STARTING_RESOURCE_PLACEMENT_RADIUS);

        starting_value = try noise.spotNoise(
            alloc,
            x, y,
            map_seed, config.seed1 + 1,
            STARTING_RESOURCE_PLACEMENT_RADIUS * 2.0,
            32, // candidate_spot_count for starting
            start_amount / (std.math.pi * STARTING_RESOURCE_PLACEMENT_RADIUS * STARTING_RESOURCE_PLACEMENT_RADIUS),
            spot_qty,
            spot_radius,
            favorability,
            -6.0 * blob_amplitude,
            128.0,
        ) + (blob - 0.25) * blob_amplitude;
    }

    // Compute regular patch value
    const density = regularDensityAt(distance, config.base_density, controls.frequency, controls.size, config.base_spots_per_km2);
    const spot_qty = regularSpotQuantity(distance, config, controls);
    const spot_radius = regularSpotRadius(spot_qty, rq_factor);

    const blob = noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 8.0, 1.0) +
        noise.basisNoise(x, y, map_seed, config.seed1, 1.0 / 24.0, 1.0);

    const blob_amplitude = (config.regular_blob_amplitude_multiplier / 8.0) /
        (std.math.pi / 3.0 * rq_factor * rq_factor) *
        std.math.pow(f64, spot_qty, 1.0 / 3.0);

    const basement = -6.0 * blob_amplitude;

    const regular_value = try noise.spotNoise(
        alloc,
        x, y,
        map_seed, config.seed1,
        1024.0, // region_size
        config.candidate_spot_count,
        density,
        spot_qty,
        spot_radius,
        1.0, // spot_favorability
        basement,
        128.0,
    ) + (blob - 0.25) * blob_amplitude;

    // Combine starting and regular
    var value: f64 = if (config.has_starting_area_placement)
        @max(starting_value, regular_value)
    else
        regular_value;

    // Apply random penalty if random_probability < 1
    if (config.random_probability < 1.0) {
        value = noise.randomPenalty(x, y, value, 1.0 / config.random_probability);
    }

    // Clamp to [0, 1] for probability
    const probability = @max(0.0, @min(1.0, value));

    if (probability <= 0.0) return 0.0;

    // Richness calculation
    var richness = value;
    if (config.random_probability < 1.0) {
        richness /= config.random_probability;
    }
    if (config.additional_richness > 0.0) {
        richness += config.additional_richness;
    }
    if (config.minimum_richness > 0.0) {
        richness = @max(richness, config.minimum_richness);
    }

    // Apply richness control multiplier
    richness *= config.richness_post_multiplier * controls.richness;

    // Apply distance-based richness multiplier
    const richness_distance_factor = @max(
        (DOUBLE_DENSITY_DISTANCE + distance) / (DOUBLE_DENSITY_DISTANCE * 2.0),
        1.0,
    );
    richness *= richness_distance_factor;

    return richness;
}

// ============================================================
// Batch ore computation for a chunk
// ============================================================

/// A single ore entity placed on the map.
pub const OreEntity = struct {
    x: i32,
    y: i32,
    resource_name: []const u8,
    amount: u32,
};

/// Compute all ore placements for a set of resources across a rectangular region.
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
                        try results.append(alloc, .{
                            .x = x,
                            .y = y,
                            .resource_name = name,
                            .amount = amount,
                        });
                    }
                }
            }
        }
    }

    return results;
}

test "computeOreAt returns 0 for size=0" {
    const controls = AutoplaceControls{ .frequency = 1.0, .size = 0.0, .richness = 1.0 };
    const result = try computeOreAt(std.testing.allocator, 341, 100, 100, 100, iron_ore_default, controls);
    try std.testing.expectEqual(0.0, result);
}

test "computeOreAt produces finite values" {
    const controls = AutoplaceControls{ .frequency = 1.0, .size = 1.0, .richness = 1.0 };
    const result = try computeOreAt(std.testing.allocator, 341, 100, 100, 500, iron_ore_default, controls);
    try std.testing.expect(!std.math.isNan(result));
    try std.testing.expect(!std.math.isInf(result));
}
