//! Factorio-compatible noise system.
//!
//! Implements the noise operations used by Factorio's map generation:
//!   - basis_noise: 2D Perlin noise with seed hashing
//!   - multioctave_noise: Fractal octave sum
//!   - spot_noise: Voronoi-like spot placement (the core of ore generation)
//!   - random_penalty: Random thinning of values
//!
//! Parameters match Factorio's data stage noise expressions exactly.

const std = @import("std");
const rng = @import("rng.zig");

// ============================================================
// Hash function for noise permutations
// ============================================================

fn hash(n: u32) u32 {
    var h: u32 = n;
    h ^= h << 13;
    h ^= h >> 17;
    h ^= h << 5;
    return h;
}

fn hash2(x: u32, y: u32) u32 {
    return hash(x +% hash(y));
}

fn hash3(x: u32, y: u32, z: u32) u32 {
    return hash(x +% hash(y +% hash(z)));
}

// ============================================================
// basis_noise — exact port of Factorio's surflet gradient noise
// (Noise::noise @ 0x1015db970, Noise::setSeed @ 0x1015dae7c,
//  Noise::Noise ctor @ 0x1015daca8). See ghidra/export/spot_noise.c.
//
// NOT classic Perlin: value = sum over the 4 grid corners of
//   (grad_c . offset_c) * max(0, 1 - |offset_c|^2)^3  * output_scale
// with gradients chosen by a double-permutation hash. The 256 base gradients
// are ~4.2*(cos,sin) around a circle via Factorio's fast-sin polynomial;
// setSeed then Fisher-Yates-shuffles the two 256 permutation tables and the
// gradient table with a taus88 RNG seeded by seed0, and picks a seed byte.
// ============================================================

/// One base gradient component: Factorio's fast-sin polynomial of `phase`.
fn gradPoly(phase: f64) f32 {
    const r: f64 = if (phase > 0.0) @trunc(phase + 0.5) else @trunc(phase - 0.5);
    const t = 0.25 - @abs(phase - r);
    const t2 = t * t;
    const t4 = t2 * t2;
    const t8 = t4 * t4;
    const poly = t8 * 39.65735524898863 + t2 * (-41.34167506665737) +
        6.283185269630412 + t4 * (t2 * (-76.56887678023256) + 81.60201529595571);
    return @floatCast(t * poly * 4.2);
}

/// Base gradient vector i (before shuffling): ~4.2*(cos,sin) at angle 2*pi*i/256.
fn baseGradient(i: usize) [2]f32 {
    const ang_f32: f32 = @floatCast(@as(f64, @floatFromInt(i)) * 0.02454369260617026); // *2pi/256
    const phase_x: f64 = @as(f64, ang_f32) * 0.15915494309189535; // /2pi
    const phase_y: f64 = phase_x - 0.25;
    return .{ gradPoly(phase_x), gradPoly(phase_y) };
}

/// A seeded Noise instance (perm tables + gradient table), reusable across
/// input/output scales. Build once per (seed0, seed1); cheap to evaluate.
pub const BasisNoiseGen = struct {
    perm1: [256]u8,
    perm2: [256]u8,
    grad: [256][2]f32,
    seed_byte: u8,

    fn shufflePerm(arr: *[256]u8, prng: *rng.Rng) void {
        var i: usize = 255;
        while (i >= 1) : (i -= 1) {
            const j = prng.next() % @as(u32, @intCast(i + 1));
            const tmp = arr[i];
            arr[i] = arr[j];
            arr[j] = tmp;
            if (i == 1) break;
        }
    }

    pub fn init(seed0: u32, seed1: u32) BasisNoiseGen {
        var self: BasisNoiseGen = undefined;
        var identity: [256]u8 = undefined;
        for (0..256) |i| {
            identity[i] = @intCast(i);
            self.perm1[i] = @intCast(i);
            self.perm2[i] = @intCast(i);
            self.grad[i] = baseGradient(i);
        }

        // setSeed(seed0 + ((seed1>>8)&0xffffff)*7, seed1 & 0xff) per BasisNoise ctor
        // (ghidra 0x1015ff718): the high bytes of seed1 fold into the RNG seed,
        // the low byte selects the seed_byte. For seed1<256 (ore=100, moisture=6)
        // the fold is 0 and this reduces to the old behavior.
        const folded: u32 = seed0 +% (((seed1 >> 8) & 0xffffff) *% 7);
        const s: u32 = if (folded < 342) 341 else folded;
        var prng = rng.Rng.init(s);

        // 1) temp shuffle of an identity copy -> seed_byte = temp[seed1 & 0xff]
        var temp = identity;
        shufflePerm(&temp, &prng);
        self.seed_byte = temp[seed1 & 0xff];

        // 2) shuffle perm1, 3) perm2, 4) gradient table (RNG continues in order).
        shufflePerm(&self.perm1, &prng);
        shufflePerm(&self.perm2, &prng);
        var gi: usize = 255;
        while (gi >= 1) : (gi -= 1) {
            const j = prng.next() % @as(u32, @intCast(gi + 1));
            const tmp = self.grad[gi];
            self.grad[gi] = self.grad[j];
            self.grad[j] = tmp;
            if (gi == 1) break;
        }
        return self;
    }

    /// Evaluate basis_noise at (x, y) with the given input/output scale.
    /// offset_x/offset_y default to 0 for plain basis_noise.
    pub fn eval(self: *const BasisNoiseGen, x: f64, y: f64, input_scale: f64, output_scale: f64) f64 {
        return self.evalOffset(x, y, input_scale, output_scale, 0.0, 0.0);
    }

    /// basis_noise with an offset added in the pre-scale coordinate space:
    /// sample = ((x + offset_x) * input_scale, (y + offset_y) * input_scale).
    /// Matches quick_multioctave_noise's offset handling (BasisNoise op).
    pub fn evalOffset(self: *const BasisNoiseGen, x: f64, y: f64, input_scale: f64, output_scale: f64, offset_x: f64, offset_y: f64) f64 {
        const scale: f32 = @floatCast(input_scale);
        const X: f32 = (@as(f32, @floatCast(x)) + @as(f32, @floatCast(offset_x))) * scale;
        const Y: f32 = (@as(f32, @floatCast(y)) + @as(f32, @floatCast(offset_y))) * scale;
        const ix: i32 = @intFromFloat(@floor(X));
        const iy: i32 = @intFromFloat(@floor(Y));
        const fx: f32 = X - @as(f32, @floatFromInt(ix));
        const fy: f32 = Y - @as(f32, @floatFromInt(iy));

        var sum: f32 = 0.0;
        var cy: i32 = 0;
        while (cy <= 1) : (cy += 1) {
            var cx: i32 = 0;
            while (cx <= 1) : (cx += 1) {
                const p1: u8 = self.perm1[@as(u8, @truncate(@as(u32, @bitCast(iy + cy))))];
                const p2: u8 = self.perm2[@as(u8, @truncate(@as(u32, @bitCast(ix + cx))))];
                const g = self.grad[p1 ^ self.seed_byte ^ p2];
                const dx: f32 = fx - @as(f32, @floatFromInt(cx));
                const dy: f32 = fy - @as(f32, @floatFromInt(cy));
                const d2 = dx * dx + dy * dy;
                if (d2 < 1.0) {
                    const w = 1.0 - d2;
                    sum += (g[0] * dx + g[1] * dy) * w * w * w;
                }
            }
        }
        return @as(f64, sum) * output_scale;
    }
};

/// Convenience wrapper (builds a Gen per call — do NOT use in hot loops; use a
/// cached BasisNoiseGen). Kept for tests / one-off evaluation.
pub fn basisNoise(x: f64, y: f64, seed0: u32, seed1: u32, input_scale: f64, output_scale: f64) f64 {
    const gen = BasisNoiseGen.init(seed0, seed1);
    return gen.eval(x, y, input_scale, output_scale);
}

// ============================================================
// multioctave_noise — Fractal octave sum
// ============================================================

/// Factorio's multioctave_noise expression.
/// Parameters: x, y, seed0, seed1, octaves, persistence, input_scale, output_scale.
pub fn multioctaveNoise(
    x: f64, y: f64,
    seed0: u32, seed1: u32,
    octaves: u32,
    persistence: f64,
    input_scale: f64,
    output_scale: f64,
) f64 {
    const gen = BasisNoiseGen.init(seed0, seed1);
    return multioctaveNoisePrebuilt(&gen, x, y, octaves, persistence, input_scale, output_scale);
}

/// multioctave_noise with a caller-supplied generator (built once per (seed0,
/// seed1) — building it dominates cost, so hoist out of hot loops). Factorio's
/// MultioctaveNoise op (fastVectorMultioctaveNoise @ 0x1015dc590) reuses ONE
/// Noise (single seed) for every octave, scaling only the coordinate: successive
/// octaves get COARSER (input_scale *= 0.5) with amplitude *= persistence.
/// Normalized by the amplitude sum so output_scale controls the final range.
pub fn multioctaveNoisePrebuilt(
    gen: *const BasisNoiseGen,
    x: f64, y: f64,
    octaves: u32,
    persistence: f64,
    input_scale: f64,
    output_scale: f64,
) f64 {
    return multioctaveNoiseOffset(gen, x, y, octaves, persistence, input_scale, output_scale, 0.0, 0.0);
}

/// multioctave_noise with offset_x/offset_y. Verified (mse=0 vs game probe): the
/// offset is added in NOISE space, the same constant every octave — noise-space
/// coord = 17.17*k + offset + coord*coordmul*input_scale.
pub fn multioctaveNoiseOffset(
    gen: *const BasisNoiseGen,
    x: f64, y: f64,
    octaves: u32,
    persistence: f64,
    input_scale: f64,
    output_scale: f64,
    offset_x: f64,
    offset_y: f64,
) f64 {
    // EXACT (fit to game raw-multioctave probes, mse=0.0): single shared seed;
    // per octave k the basis samples at
    //   (x*input_scale*0.5^k + k*C,  y*input_scale*0.5^k)   with C=17.17
    // octaves COARSER (coordmul*=0.5); per-octave x-offset k*C added in noise
    // space; amplitude GROWS by 1/persistence each octave (coarse-dominated);
    // RMS-normalized (÷sqrt(Σ amp²)). The game uses the vectorized path
    // fastVectorMultioctaveNoise @0x1015dc590 (C=17.17). fVar7=1/persistence is
    // the amplitude multiplier — grow, not decay. Verified via a noise-probe mod
    // on a vanilla Nauvis surface (see se-terrain-generation memory).
    const ampmul = 1.0 / persistence;
    var value: f64 = 0.0;
    var amplitude: f64 = 1.0;
    var coordmul: f64 = 1.0;
    var sumsq: f64 = 0.0;
    var k: f64 = 0.0;
    var i: u32 = 0;
    while (i < octaves) : (i += 1) {
        const x_arg = (k * 17.17 + offset_x) / input_scale + x * coordmul;
        const y_arg = offset_y / input_scale + y * coordmul;
        value += gen.eval(x_arg, y_arg, input_scale, 1.0) * amplitude;
        sumsq += amplitude * amplitude;
        coordmul *= 0.5;
        amplitude *= ampmul;
        k += 1.0;
    }
    return (value / @sqrt(sumsq)) * output_scale;
}

/// variable_persistence_multioctave_noise (VariablePersistenceMultioctaveNoise op
/// @0x1015f1c54, ctor @0x101611c50). Exact port of run(): a HORNER accumulation
///   acc = 0; for k in 0..octaves:  acc = acc*persistence + basis(is_k)
/// where is_0 = input_scale*0.5 (the ctor stores input_scale halved) and halves
/// each octave, so the coarsest octave (k=0) gets the smallest weight
/// persistence^(octaves-1) and the finest (k=octaves-1) weight 1. The offset is
/// added in TILE space ((x+offset)*is, via evalOffset) and is constant across
/// octaves. Final result is scaled by output_scale * 2^octaves (the ctor stores
/// output_scale * 2^octaves). `persistence` is a per-tile scalar (may itself be a
/// noise field, e.g. nauvis_detail feeds nauvis_persistance here). Verified vs the
/// game probe probe_vp500_p7 to 5 decimals across 10 points.
pub fn variablePersistence(
    gen: *const BasisNoiseGen,
    x: f64, y: f64,
    octaves: u32,
    input_scale: f64,
    output_scale: f64,
    offset_x: f64,
    offset_y: f64,
    persistence: f64,
) f64 {
    var is_k: f64 = input_scale * 0.5;
    var acc: f64 = 0.0;
    var k: u32 = 0;
    while (k < octaves) : (k += 1) {
        acc = acc * persistence + gen.evalOffset(x, y, is_k, 1.0, offset_x, offset_y);
        is_k *= 0.5;
    }
    return acc * output_scale * std.math.pow(f64, 2.0, @floatFromInt(octaves));
}

// ============================================================
// random_penalty — Random thinning
// ============================================================

/// Factorio's random_penalty op (RandomPenalty run @ 0x1015f0384). Per-tile
/// deterministic uniform draw r; returns `source - r*amplitude`. Seed from the
/// tile position, matching the spot-quantity port in computeRegion:
///   seed = int(x)*7919 + int(y+seed_const)*7907 + 0x3fbe2c  (>=341), triple-LFSR.
/// Used for random_probability<1 (fluid) resources: with source=1,
/// amplitude=1/random_probability the value is <0 on ~(1-rp) of tiles, so the
/// probability_expression clamps to 0 there → the patch becomes sparse dots.
pub fn randomPenalty(x: f64, y: f64, source: f64, amplitude: f64) f64 {
    return randomPenaltySeeded(x, y, source, amplitude, 0);
}

pub fn randomPenaltySeeded(x: f64, y: f64, source: f64, amplitude: f64, seed_const: i32) f64 {
    const xi: i32 = @intFromFloat(@floor(x));
    const yi: i32 = @intFromFloat(@floor(y) + @as(f64, @floatFromInt(seed_const)));
    var s: u32 = (@as(u32, @bitCast(xi)) *% 7919) +% (@as(u32, @bitCast(yi)) *% 7907) +% 0x3fbe2c;
    if (s < 342) s = 341;
    var rr = rng.Rng.init(s);
    const r = rr.float();
    return source - r * amplitude;
}

// ============================================================
// spot_noise — Voronoi-like spot placement
// ============================================================

// Exact port of Factorio's SpotNoise op, decompiled from the arm64 binary
// (ThreadSafeSpotNoiseCache::SpotListGenerator). See ghidra/export/spot_noise.c.
//
// Pipeline per region:
//   1. seed = ((ry*7907 + rx*7919 + seed1*7927 + 0x3fbe2c) ^ map_seed), >=341
//   2. generatePoints: candidate_spot_count*skip_span Poisson-disk points,
//      integer coords in a region CENTERED on (rx,ry)*region_size (±size/2).
//   3. stride from skip_offset by skip_span -> this resource's candidates.
//   4. evaluate density/quantity/radius/favorability at each candidate.
//   5. region_target = mean(density) * region_size^2.
//   6. sort by favorability desc; select accumulating quantity until >= target
//      (hard: clamp last spot's quantity, shrink radius by (q'/q)^(1/3)).
//   7. each spot is a CONE: peak = 3q/(pi r^2), slope = peak/r, r=min(radius,128).
//   field value = max(basement_value, max over spots within 128 of peak-dist*slope)

/// A finalized spot: a cone value = peak - dist*slope for dist in [0, radius].
pub const Spot = struct { x: f64, y: f64, peak: f64, slope: f64 };

const RegionKey = struct { x: i32, y: i32 };

// Upper bound on generatePoints' candidate_point_count = candidate_spot_count *
// skip_span. Must be >= the largest configuration or point_count is silently
// truncated and each resource loses candidate spots (positions stop matching
// the game). Vanilla: 22*6=132. SE regular: 64*18=1152. Sized for SE.
const MAX_POINTS: usize = 1152;

fn cbrt(v: f64) f64 {
    return std.math.pow(f64, v, 1.0 / 3.0);
}

/// Exact per-region seed hash (generatePoints @ 0x1015e67f4).
pub fn regionSeed(seed0: u32, seed1: u32, region_x: i32, region_y: i32) u32 {
    const rx: u32 = @bitCast(region_x);
    const ry: u32 = @bitCast(region_y);
    // 32-bit wrapping arithmetic (C int math), then XOR map_seed.
    var h: u32 = (ry *% 7907) +% (rx *% 7919) +% (seed1 *% 7927) +% 0x3fbe2c;
    h ^= seed0;
    if (h < 342) h = 341;
    return h;
}

/// Per-spot size (random_penalty_between) draw-stream variant, selectable at
/// runtime for calibration against ground truth:
///   0 = seed from first STRIDED candidate, draws forward over strided
///   1 = seed from first strided candidate, draws REVERSED over strided
///       (RandomPenalty::run iterates its column last->first)
///   2 = seed from px[0] of the FULL point list, draws reversed over all points
///   3 = seed from px[0], draws forward over all points
/// Default 1 — verified EXACT against the game's `default-iron-ore-patches`
/// field via calculate_tile_properties (cone apexes match to float32 precision;
/// see calibration/vanilla-sweep/probe_field.py).
pub var spot_size_rng_variant: u8 = 1;

/// Stateful spot field with per-region caching, generic over the expression
/// evaluator `F`, which must expose:
///   spotDensityAt(x,y)  spotQuantityAt(x,y)  spotRadius(q)  favorability(x,y)
pub fn SpotNoiseField(comptime F: type) type {
    return struct {
        const Self = @This();

        alloc: std.mem.Allocator,
        field: F,
        seed0: u32,
        seed1: u32,
        region_size: f64,
        candidate_spot_count: u32,
        skip_span: u32,
        skip_offset: u32,
        hard_region_target_quantity: bool,
        basement_value: f64,
        maximum_spot_basement_radius: f64,
        min_candidate_spacing: f64,
        cache: std.AutoHashMapUnmanaged(RegionKey, []Spot) = .empty,

        pub fn deinit(self: *Self) void {
            var it = self.cache.valueIterator();
            while (it.next()) |slice| self.alloc.free(slice.*);
            self.cache.deinit(self.alloc);
        }

        pub fn spotsForRegion(self: *Self, rx: i32, ry: i32) ![]Spot {
            const key = RegionKey{ .x = rx, .y = ry };
            if (self.cache.get(key)) |s| return s;
            const spots = try self.computeRegion(rx, ry);
            try self.cache.put(self.alloc, key, spots);
            return spots;
        }

        fn computeRegion(self: *Self, rx: i32, ry: i32) ![]Spot {
            const rsize_i: i32 = @intFromFloat(self.region_size);
            if (rsize_i <= 0) return &[_]Spot{};
            const rsize_u: u32 = @intCast(rsize_i);
            const half = @divTrunc(rsize_i, 2);
            const base_x: i32 = rx *% rsize_i -% half;
            const base_y: i32 = ry *% rsize_i -% half;

            var prng = rng.Rng.init(regionSeed(self.seed0, self.seed1, rx, ry));

            const point_count: usize = @min(
                @as(usize, self.candidate_spot_count) * @as(usize, self.skip_span),
                MAX_POINTS,
            );

            // --- generatePoints: Poisson-disk sampled integer points ---
            var px: [MAX_POINTS]f64 = undefined;
            var py: [MAX_POINTS]f64 = undefined;
            var spacing2 = self.min_candidate_spacing * self.min_candidate_spacing;
            var i: usize = 0;
            while (i < point_count) : (i += 1) {
                while (true) {
                    const fx: f64 = @floatFromInt(base_x +% @as(i32, @bitCast(prng.next() % rsize_u)));
                    const fy: f64 = @floatFromInt(base_y +% @as(i32, @bitCast(prng.next() % rsize_u)));
                    var ok = true;
                    var j: usize = 0;
                    while (j < i) : (j += 1) {
                        const ddx = fx - px[j];
                        const ddy = fy - py[j];
                        if (ddx * ddx + ddy * ddy < spacing2) {
                            spacing2 *= 0.9375; // shrink threshold and retry this point
                            ok = false;
                            break;
                        }
                    }
                    if (ok) {
                        px[i] = fx;
                        py[i] = fy;
                        break;
                    }
                }
            }

            // --- stride this resource's candidates and evaluate expressions ---
            // spot_quantity_expression = random_penalty_between(min,max,1) * base.
            // RandomPenalty (op run @ 0x1015f0384): ONE rng seeded from the first
            // element of its x/y column: seed = int(x0)*7919 + int(y0+1)*7907
            // + 0x3fbe2c (>=341), taus88; the op iterates its column from the
            // LAST element to the FIRST, one draw per element with source>0;
            // value = to - r*(to-from), r = draw*2^-32. Which column the game
            // evaluates (strided candidates vs all points) is selected by
            // spot_size_rng_variant for calibration.
            const smin = self.field.randomSpotSizeMinimum();
            const smax = self.field.randomSpotSizeMaximum();
            const strided_n: usize = if (self.skip_offset >= point_count)
                0
            else
                (point_count - 1 - self.skip_offset) / self.skip_span + 1;
            const col_n: usize = if (spot_size_rng_variant >= 2) point_count else strided_n;
            const seed_idx: usize = if (spot_size_rng_variant >= 2) 0 else self.skip_offset;
            var draws: [MAX_POINTS]f64 = undefined;
            {
                var rp_rng = blk: {
                    if (seed_idx >= point_count) break :blk rng.Rng.init(341);
                    const xi: i32 = @intFromFloat(px[seed_idx]);
                    const yi1: i32 = @intFromFloat(py[seed_idx] + 1.0);
                    var rp: u32 = (@as(u32, @bitCast(xi)) *% 7919) +%
                        (@as(u32, @bitCast(yi1)) *% 7907) +% 0x3fbe2c;
                    if (rp < 342) rp = 341;
                    break :blk rng.Rng.init(rp);
                };
                var d: usize = 0;
                while (d < col_n) : (d += 1) draws[d] = rp_rng.float();
            }
            // draw index for column element i (reversed variants: op iterates
            // its column last->first, so element i consumes draw col_n-1-i).
            const reversed = spot_size_rng_variant == 1 or spot_size_rng_variant == 2;

            const Candidate = struct { x: f64, y: f64, density: f64, quantity: f64, radius: f64, fav: f64 };
            var cands: [MAX_POINTS]Candidate = undefined;
            var nc: usize = 0;
            var idx: usize = self.skip_offset;
            while (idx < point_count) : (idx += self.skip_span) {
                const cx = px[idx];
                const cy = py[idx];
                const elem: usize = if (spot_size_rng_variant >= 2) idx else nc;
                const di: usize = if (reversed) col_n - 1 - elem else elem;
                const rand_factor = smax - draws[di] * (smax - smin);
                const q = rand_factor * self.field.spotQuantityBaseAt(cx, cy);
                cands[nc] = .{
                    .x = cx,
                    .y = cy,
                    .density = self.field.spotDensityAt(cx, cy),
                    .quantity = q,
                    .radius = self.field.spotRadius(q),
                    .fav = self.field.favorability(cx, cy),
                };
                nc += 1;
            }
            if (nc == 0) return &[_]Spot{};

            // region_target = mean(density over candidates) * region_size^2
            var dsum: f64 = 0.0;
            for (cands[0..nc]) |c| dsum += c.density;
            const region_target = (dsum / @as(f64, @floatFromInt(nc))) * self.region_size * self.region_size;

            // sort by favorability descending
            const lessThan = struct {
                fn f(_: void, a: Candidate, b: Candidate) bool {
                    return a.fav > b.fav;
                }
            }.f;
            std.mem.sort(Candidate, cands[0..nc], {}, lessThan);

            // select accumulating quantity until region_target reached
            var out = try self.alloc.alloc(Spot, nc);
            var no: usize = 0;
            var accumulated: f64 = 0.0;
            for (cands[0..nc]) |c| {
                if (accumulated >= region_target) break;
                var q = c.quantity;
                var r = @min(c.radius, self.maximum_spot_basement_radius);
                if (q <= 0.0 or r <= 0.0) continue;
                if (self.hard_region_target_quantity) {
                    const qc = @min(q, region_target - accumulated);
                    r *= cbrt(qc / q);
                    q = qc;
                }
                const peak = 3.0 * q / (std.math.pi * r * r);
                out[no] = .{ .x = c.x, .y = c.y, .peak = peak, .slope = peak / r };
                no += 1;
                accumulated += q;
            }
            if (self.alloc.resize(out, no)) {
                out.len = no;
            } else {
                out = self.alloc.realloc(out, no) catch out[0..no];
            }
            return out[0..no];
        }

        /// Field value at (x, y): max(basement, max cone over nearby spots).
        pub fn evalAt(self: *Self, x: f64, y: f64) !f64 {
            var value = self.basement_value;
            const cxr: i32 = @intFromFloat(@round(x / self.region_size));
            const cyr: i32 = @intFromFloat(@round(y / self.region_size));
            var dx: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                var dy: i32 = -1;
                while (dy <= 1) : (dy += 1) {
                    const spots = try self.spotsForRegion(cxr + dx, cyr + dy);
                    for (spots) |s| {
                        const ddx = x - s.x;
                        const ddy = y - s.y;
                        const dist = @sqrt(ddx * ddx + ddy * ddy);
                        if (dist <= self.maximum_spot_basement_radius) {
                            const v = s.peak - dist * s.slope;
                            if (v > value) value = v;
                        }
                    }
                }
            }
            return value;
        }
    };
}// ============================================================
// Tests
// ============================================================

test "basisNoise is deterministic" {
    const a = basisNoise(100.0, 200.0, 341, 100, 1.0 / 8.0, 1.0);
    const b = basisNoise(100.0, 200.0, 341, 100, 1.0 / 8.0, 1.0);
    try std.testing.expectEqual(a, b);
}

test "basisNoise gen matches wrapper" {
    const gen = BasisNoiseGen.init(341, 100);
    try std.testing.expectEqual(
        basisNoise(50.0, 60.0, 341, 100, 1.0 / 24.0, 1.5),
        gen.eval(50.0, 60.0, 1.0 / 24.0, 1.5),
    );
}

test "base gradients are ~magnitude 4.2" {
    const g = baseGradient(0);
    const mag = @sqrt(@as(f64, g[0]) * g[0] + @as(f64, g[1]) * g[1]);
    try std.testing.expect(mag > 4.0 and mag < 4.4);
}

test "multioctaveNoise produces finite values" {
    const val = multioctaveNoise(100.0, 200.0, 341, 100, 4, 0.5, 1.0 / 32.0, 1.0);
    try std.testing.expect(!std.math.isNan(val));
    try std.testing.expect(!std.math.isInf(val));
}

