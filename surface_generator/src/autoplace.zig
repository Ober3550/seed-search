//! Resource autoplace — probability-driven ore placement.
//!
//! Factorio places resources using "autoplace" specifications that combine:
//!   - A probability expression (noise-based) for where ore can appear
//!   - A richness expression that scales the amount
//!   - Peak definitions that map noise values to probability/richness curves
//!
//! Each resource (iron-ore, copper-ore, etc.) has its own autoplace config.
//! The probability at a given tile depends on the noise value at that tile,
//! mapped through the peak's influence curve.

const std = @import("std");
const rng = @import("rng.zig");

/// Autoplace peak: a single probability peak within a resource's config.
pub const Peak = struct {
    /// Noise level at which probability is maximized.
    influence: f64,
    /// Width of the peak (standard deviation).
    width: f64,
    /// Base richness at the peak center.
    richness: f64,
};

/// Autoplace configuration for a single resource.
pub const AutoplaceConfig = struct {
    /// Resource prototype name (e.g., "iron-ore").
    resource_name: []const u8,
    /// Probability peaks (multiple peaks = multiple bands/regions of ore).
    peaks: []const Peak,
    /// Minimum probability threshold to place any ore.
    min_probability: f64 = 0.01,
    /// Seed offset for the noise expression.
    seed_offset: u32 = 0,
};

/// Compute the resource amount at a single tile position.
/// Returns 0 if no resource should be placed.
pub fn computeAmount(
    config: *const AutoplaceConfig,
    seed: u32,
    x: f64,
    y: f64,
) u32 {
    _ = config;
    _ = seed;
    _ = x;
    _ = y;
    // TODO: Implement autoplace probability evaluation
    // 1. Evaluate noise expression at (x, y)
    // 2. Map through peaks to get probability
    // 3. Roll RNG against probability
    // 4. If placed, compute richness from peak curve
    return 0;
}

test "autoplace returns zero for unimplemented" {
    const config = AutoplaceConfig{
        .resource_name = "iron-ore",
        .peaks = &.{},
    };
    try std.testing.expectEqual(@as(u32, 0), computeAmount(&config, 341, 0, 0));
}
