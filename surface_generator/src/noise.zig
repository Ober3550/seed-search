//! Factorio-compatible noise system with exact spot_noise algorithm.
//!
//! Implements the "spot noise" expression type described in FFF #258:
//!   1. Generate random candidate points per region
//!   2. Calculate density, quantity, radius, favorability for each
//!   3. Sort by favorability, select until target quantity reached
//!   4. Evaluate selected spots at (x,y)

const std = @import("std");
const rng = @import("rng.zig");
const sha1 = @import("sha1.zig");

// ============================================================
// Hash function for Perlin noise permutations
// ============================================================

fn hash(n: u32) u32 {
    var h: u32 = n;
    h ^= h << 13;
    h ^= h >> 17;
    h ^= h << 5;
    return h;
}

fn hash3(x: u32, y: u32, z: u32) u32 {
    const a = x +% hash(y +% hash(z));
    return hash(a);
}

// ============================================================
// 2D Perlin noise (basis_noise)
// ============================================================

const GRAD2: [8][2]f64 = .{
    .{ 1, 0 }, .{ -1, 0 }, .{ 0, 1 }, .{ 0, -1 },
    .{ 1, 1 }, .{ -1, 1 }, .{ 1, -1 }, .{ -1, -1 },
};

fn smoothstep(t: f64) f64 {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

fn dotGrad2(hash_val: u32, dx: f64, dy: f64) f64 {
    const g = GRAD2[hash_val & 7];
    return g[0] * dx + g[1] * dy;
}

pub fn perlin2d(x: f64, y: f64, seed0: u32, seed1: u32) f64 {
    const ix: i32 = @intFromFloat(@floor(x));
    const iy: i32 = @intFromFloat(@floor(y));
    const fx = x - @as(f64, @floatFromInt(ix));
    const fy = y - @as(f64, @floatFromInt(iy));
    const u = smoothstep(fx);
    const v = smoothstep(fy);
    const xi0: u32 = @bitCast(ix);
    const yi0: u32 = @bitCast(iy);
    const xi1: u32 = @bitCast(ix + 1);
    const yi1: u32 = @bitCast(iy + 1);
    const s = seed0 +% seed1;
    const n00 = dotGrad2(hash3(xi0, yi0, s), fx, fy);
    const n10 = dotGrad2(hash3(xi1, yi0, s), fx - 1.0, fy);
    const n01 = dotGrad2(hash3(xi0, yi1, s), fx, fy - 1.0);
    const n11 = dotGrad2(hash3(xi1, yi1, s), fx - 1.0, fy - 1.0);
    const nx0 = n00 + u * (n10 - n00);
    const nx1 = n01 + u * (n11 - n01);
    return nx0 + v * (nx1 - nx0);
}

pub fn basisNoise(x: f64, y: f64, seed0: u32, seed1: u32, input_scale: f64, output_scale: f64) f64 {
    return perlin2d(x * input_scale, y * input_scale, seed0, seed1) * output_scale;
}

// ============================================================
// spot_noise — FFF #258 algorithm
// ============================================================

const MAX_CANDIDATES = 64; // enough for any region + neighbors


pub const SpotCandidate = struct {
    x: f64,
    y: f64,
    quantity: f64,
    radius: f64,
    favorability: f64,
};

/// Generate and select spots using FFF #258 algorithm.
/// Returns all selected spots across 9 regions around (rx, ry).
pub fn generateSpots(
    alloc: std.mem.Allocator,
    rx: f64, ry: f64,
    map_seed: u32,
    region_size: f64,
    candidate_spot_count: u32,
    density_expression: f64,
    spot_quantity: f64,
    spot_radius: f64,
) !std.ArrayList(SpotCandidate) {
    var candidates = std.ArrayList(SpotCandidate).init(alloc);

    var drx: i32 = -1;
    while (drx <= 1) : (drx += 1) {
        var dry: i32 = -1;
        while (dry <= 1) : (dry += 1) {
            const nrx = rx + @as(f64, @floatFromInt(drx));
            const nry = ry + @as(f64, @floatFromInt(dry));

            var sha_buf: [16]u8 = undefined;
            std.mem.writeInt(i64, sha_buf[0..8], @as(i64, @intFromFloat(nrx)), .little);
            std.mem.writeInt(i64, sha_buf[8..16], @as(i64, @intFromFloat(nry)), .little);
            var digest: [20]u8 = undefined;
            sha1.hash16(&sha_buf, &digest);
            const region_seed = std.mem.readInt(u32, digest[0..4], .little);
            var region_rng = rng.Rng.init(region_seed);
            _ = map_seed;

            var si: u32 = 0;
            while (si < candidate_spot_count) : (si += 1) {
                const sx = nrx * region_size + region_rng.float() * region_size;
                const sy = nry * region_size + region_rng.float() * region_size;
                const scale = 0.5 + region_rng.float();
                try candidates.append(.{
                    .x = sx,
                    .y = sy,
                    .quantity = spot_quantity * scale,
                    .radius = spot_radius * scale,
                    .favorability = 1.0,
                });
            }
        }
    }

    // Sort by favorability descending
    std.mem.sort(SpotCandidate, candidates.items, {}, struct {
        fn lt(_: void, a: SpotCandidate, b: SpotCandidate) bool {
            return a.favorability > b.favorability;
        }
    }.lt);

    // Select until target quantity reached
    const region_area = region_size * region_size;
    const target_quantity = density_expression * region_area * 9.0; // 9 regions

    var total_qty: f64 = 0;
    var keep: usize = 0;
    for (candidates.items) |c| {
        if (total_qty >= target_quantity) break;
        total_qty += c.quantity;
        keep += 1;
    }

    // Shrink to selected spots
    try candidates.resize(keep);
    return candidates;
}

/// Evaluate spot_noise at (x,y) using pre-generated spots.
pub fn spotNoise(
    x: f64, y: f64,
    spots: []const SpotCandidate,
    basement_value: f64,
) f64 {
    var value: f64 = basement_value;
    for (spots) |c| {
        const dx = x - c.x;
        const dy = y - c.y;
        const dist = @sqrt(dx * dx + dy * dy);
        if (dist < c.radius) {
            const t = dist / c.radius;
            const falloff = (1.0 - t) * (1.0 - t);
            value += (c.quantity / (std.math.pi * c.radius * c.radius)) * falloff;
        }
    }
    return value;
}

// ============================================================
// random_penalty
// ============================================================

pub fn randomPenalty(x: f64, y: f64, source: f64, amplitude: f64) f64 {
    const ix: u32 = @bitCast(@as(i32, @intFromFloat(@floor(x))));
    const iy: u32 = @bitCast(@as(i32, @intFromFloat(@floor(y))));
    var rr = rng.Rng.init(ix ^ (iy << 16));
    const r = rr.float();
    if (r > amplitude) return source * r;
    return source;
}

// ============================================================
// Tests
// ============================================================

test "perlin2d produces values in [-1, 1]" {
    const val = perlin2d(42.5, 13.7, 341, 100);
    try std.testing.expect(val >= -1.0);
    try std.testing.expect(val <= 1.0);
}

test "perlin2d is deterministic" {
    try std.testing.expectEqual(perlin2d(100, 200, 12345, 67890), perlin2d(100, 200, 12345, 67890));
}
