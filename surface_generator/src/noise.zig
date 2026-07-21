//! Noise expression evaluator.
//!
//! Factorio's map generation uses a tree of noise expressions combining:
//!   - Perlin noise (2D/3D)
//!   - Simplex noise
//!   - Voronoi (cellular) noise
//!   - Arithmetic ops (add, mul, min, max, clamp, lerp)
//!   - Distance fields (from spawn, from water, etc.)
//!
//! The noise tree is defined in map gen settings (noise_expressions table)
//! and evaluated per-tile at generation time.

const std = @import("std");

/// A 2D coordinate (tile position).
pub const Pos2 = struct { x: f64, y: f64 };

/// A noise expression node — placeholder; to be fleshed out during RE.
pub const NoiseExpr = union(enum) {
    constant: f64,
    perlin_2d: struct { seed: u32, scale: f64, octaves: u8 },
    simplex_2d: struct { seed: u32, scale: f64, octaves: u8 },
    add: struct { a: *NoiseExpr, b: *NoiseExpr },
    mul: struct { a: *NoiseExpr, b: *NoiseExpr },
    // TODO: Add remaining node types from Factorio's noise expression system
};

/// Evaluate a noise expression at a given position.
/// Returns a value in [-1, 1] for noise nodes.
pub fn evaluate(expr: *const NoiseExpr, pos: Pos2, seed: u32) f64 {
    _ = pos;
    _ = seed;
    return switch (expr.*) {
        .constant => |v| v,
        // TODO: Implement noise evaluation
        else => 0.0,
    };
}

test "constant noise evaluates correctly" {
    const expr = NoiseExpr{ .constant = 0.75 };
    try std.testing.expectEqual(0.75, evaluate(&expr, .{ .x = 0, .y = 0 }, 341));
}
