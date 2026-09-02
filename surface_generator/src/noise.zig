//! Factorio-compatible noise system.
//!
//! Implements the noise operations used by Factorio's map generation:
//!   - basis_noise: 2D Perlin noise with seed hashing
//!   - multioctave_noise: Fractal octave sum
//!   - spot_noise: Voronoi-like spot placement (the core of ore generation)
//!   - random_penalty: Random thinning of values
//!   - voronoi_cell_id/spot/facet/pyramid: 2.0 Space Age cellular noise
//!   - terrace: step quantizer (2.0, Gleba terrain)
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
    //   ((x+offset_x)*input_scale*0.5^k + k*C,  (y+offset_y)*input_scale*0.5^k)
    // with C=17.17. octaves COARSER (coordmul*=0.5); per-octave decorrelation
    // offset k*C added in NOISE space; amplitude GROWS by 1/persistence each
    // octave (coarse-dominated); RMS-normalized (÷sqrt(Σ amp²)). The game uses
    // the vectorized path fastVectorMultioctaveNoise @0x1015dc590 (C=17.17).
    //
    // offset_x/offset_y are added in TILE space (to x/y before the per-octave
    // scale), NOT noise space — verified against live Horaerratum tile placement:
    // the terrain-variation tv layers (offset_x=1000) pick the exact placed snow
    // variant (446/446) only with the tile-space offset; noise-space gives 12%.
    // (calculate_tile_properties evaluates offset_x in noise space, so it does
    // NOT predict map-gen placement — do not calibrate the tv against it.)
    // Accumulate in f32 to match the engine's fastVectorMultioctaveNoise (f32).
    const is32: f32 = @floatCast(input_scale);
    const xo: f32 = @floatCast(x + offset_x);
    const yo: f32 = @floatCast(y + offset_y);
    const ampmul: f32 = @floatCast(1.0 / persistence);
    var value: f32 = 0.0;
    var amplitude: f32 = 1.0;
    var coordmul: f32 = 1.0;
    var sumsq: f32 = 0.0;
    var k: f32 = 0.0;
    var i: u32 = 0;
    while (i < octaves) : (i += 1) {
        const x_arg: f32 = (k * 17.17) / is32 + xo * coordmul;
        const y_arg: f32 = yo * coordmul;
        value += @as(f32, @floatCast(gen.eval(x_arg, y_arg, input_scale, 1.0))) * amplitude;
        sumsq += amplitude * amplitude;
        coordmul *= 0.5;
        amplitude *= ampmul;
        k += 1.0;
    }
    return @as(f64, (value / @sqrt(sumsq)) * @as(f32, @floatCast(output_scale)));
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

/// A random_penalty term inside a spot_favorability_expression (e.g.
/// random_penalty_at(v, seed) = random_penalty{source=v, amplitude=v, seed}).
/// Declared by a field via `favorabilityPenalty()`.
pub const FavorabilityPenalty = struct { source: f64, amplitude: f64, seed: f64 };

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

            // Optional favorability random_penalty column (e.g. starting patches:
            // random_penalty_at(0.5, 1)). Same PROVEN semantics as the size
            // draws: seeded from the first strided candidate (with the penalty's
            // own seed param added to y), consumed in reverse candidate order.
            const fav_pen: ?FavorabilityPenalty = if (@hasDecl(F, "favorabilityPenalty"))
                self.field.favorabilityPenalty()
            else
                null;
            var fav_draws: [MAX_POINTS]f64 = undefined;
            if (fav_pen) |pen| {
                var fp_rng = blk: {
                    if (self.skip_offset >= point_count) break :blk rng.Rng.init(341);
                    const xi: i32 = @intFromFloat(px[self.skip_offset]);
                    const yi: i32 = @intFromFloat(py[self.skip_offset] + pen.seed);
                    var rp: u32 = (@as(u32, @bitCast(xi)) *% 7919) +%
                        (@as(u32, @bitCast(yi)) *% 7907) +% 0x3fbe2c;
                    if (rp < 342) rp = 341;
                    break :blk rng.Rng.init(rp);
                };
                var d: usize = 0;
                while (d < strided_n) : (d += 1) fav_draws[d] = fp_rng.float();
            }

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
                    .fav = self.field.favorability(cx, cy) + if (fav_pen) |pen|
                        pen.source - fav_draws[strided_n - 1 - nc] * pen.amplitude
                    else
                        0.0,
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
        /// Gather every spot this field can see for tiles inside [x0,x1)x[y0,y1)
        /// into an owned slice (the 3x3-region window of any tile in the rect is
        /// covered). One-time cost so the hot path can iterate a flat slice
        /// instead of hashing region lookups per tile.
        pub fn allSpotsInRect(self: *Self, alloc: std.mem.Allocator, x0: f64, x1: f64, y0: f64, y1: f64) ![]Spot {
            const rminx: i32 = @as(i32, @intFromFloat(@round(x0 / self.region_size))) - 1;
            const rmaxx: i32 = @as(i32, @intFromFloat(@round(x1 / self.region_size))) + 1;
            const rminy: i32 = @as(i32, @intFromFloat(@round(y0 / self.region_size))) - 1;
            const rmaxy: i32 = @as(i32, @intFromFloat(@round(y1 / self.region_size))) + 1;
            var list: std.ArrayList(Spot) = .empty;
            var rx: i32 = rminx;
            while (rx <= rmaxx) : (rx += 1) {
                var ry: i32 = rminy;
                while (ry <= rmaxy) : (ry += 1) {
                    const spots = try self.spotsForRegion(rx, ry);
                    try list.appendSlice(alloc, spots);
                }
            }
            return list.toOwnedSlice(alloc);
        }

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
// voronoi_cell_id / voronoi_spot_noise / voronoi_facet_noise /
// voronoi_pyramid_noise — exact port of Factorio 2.0's VoronoiNoise op
// ============================================================

// Reverse-engineered + probe-verified against the live game (2.0.77 arm64):
// hash pinned from the VoronoiPoints ctor disassembly (0x10226c098) and the
// run semantics from the four runInternal<DistanceType> instantiations. See
// ghidra/export/voronoi.c + calibration/sa-probe. Every output (nearest d0,
// d1-d0, pyramid bisector distance, winner cell id) verified exact (f32) vs
// calculate_tile_properties across grids 10..64, jitter 0..1, all four
// distance types, numeric + crc32(name) seeds.

const VORONOI_C: u32 = 0x7ed55d16; // salt base / fold add
const VORONOI_C3: u32 = 0xc761c23c;
const VORONOI_W21: u32 = 0x165667b1;
const VORONOI_D: u32 = 0xd3a2646c;
const VORONOI_C2: u32 = 0xfd7046c5;
const VORONOI_B: u32 = 0xb55a4f09;
// per-use salts sit at C + {0, 0x1001, 0x2002} (NOT +1/+2 — the ctor loads
// movk #0x7ed5 with low halves 0x5d16/0x6d17/0x7d18):
const VORONOI_SALT_X: u32 = 0x7ed55d16; // x jitter
const VORONOI_SALT_Y: u32 = 0x7ed56d17; // y jitter
const VORONOI_SALT_ID: u32 = 0x7ed57d18; // cell id

/// One 32-bit mix round of the VoronoiPoints hash: takes the RAW coordinate
/// (the ctor's row/column iterator value), folds it (v*0x1001 + C via
/// v + C + v<<12) then runs the two rounds. Feed the coordinate directly — do
/// NOT pre-fold (mix() folds for you).
fn voronoiMix(v: u32) u32 {
    var x: u32 = v +% VORONOI_C +% (v << 12);
    x = x ^ (x >> 19) ^ VORONOI_C3;
    const a: u32 = (x +% VORONOI_W21) +% (x << 5); // 33*x + W21
    const y: u32 = (a +% VORONOI_D) ^ (a << 9);
    return (y +% VORONOI_C2) +% (y << 3); // *9 + C2
}

fn ror16(v: u32) u32 {
    return (v >> 16) | (v << 16);
}

/// The per-cell combined hash m (xor of the two axis mixes + seed). The
/// ctor hashes the outer (row = y) axis through ror16 first, the inner
/// (column = x) axis raw.
fn voronoiCellM(cx: i32, cy: i32, seed: u32) u32 {
    const hx = voronoiMix(@bitCast(cx));
    const hy = voronoiMix(ror16(@bitCast(cy)));
    return seed ^ (hy >> 16) ^ (hx >> 16) ^ hy ^ hx;
}

/// One salt output: rounds(4097*m + salt) then the h ^ h>>16 ^ 0xb55a4f09
/// finish. Converts to the [0,1) f32 the engine stores (u32 * 2^-32 via f64).
fn voronoiSaltF32(m: u32, salt: u32) f32 {
    var v: u32 = m *% 0x1001 +% salt;
    v = v ^ (v >> 19) ^ VORONOI_C3;
    const a: u32 = (v +% VORONOI_W21) +% (v << 5);
    const y: u32 = (a +% VORONOI_D) ^ (a << 9);
    const h: u32 = (y +% VORONOI_C2) +% (y << 3);
    const out: u32 = (h ^ (h >> 16) ^ VORONOI_B);
    return @floatCast(@as(f64, @as(f64, @floatFromInt(out)) * 2.3283064365386963e-10));
}

pub const VoronoiPoint = struct { x: f32, y: f32, id: f32 };

/// The jittered point of grid cell (cx, cy): returns relative coordinates in
/// [0,1) plus the cell id fraction. px/py follow
/// f32(u32/2^32)*jitter + (1-jitter)/2 with the engine's f32 op order; id is
/// the raw f32(u32/2^32).
pub fn voronoiPoint(cx: i32, cy: i32, seed: u32, jitter: f32) VoronoiPoint {
    const m = voronoiCellM(cx, cy, seed);
    const r = voronoiSaltF32(m, VORONOI_SALT_X);
    const s = voronoiSaltF32(m, VORONOI_SALT_Y);
    const t = voronoiSaltF32(m, VORONOI_SALT_ID);
    const j = jitter;
    // (px*j + (1-j)*0.5) in f32, matching the ctor's NEON fadd chain.
    const off = @as(f32, 1.0 - j) * 0.5;
    return .{ .x = r * j + off, .y = s * j + off, .id = t };
}



pub const VoronoiDistanceType = enum(u8) {
    chebyshev = 0,
    manhattan = 1,
    euclidean = 2,
    minkowski3 = 3,
};

/// Engine's fast Math::exp2f (bit-level approx, f32 arithmetic) used by the
/// minkowski3 cube root: cbrt(s) = exp2f(log2(s) * 0.33333334).
fn fastExp2f(x_in: f32) f32 {
    var x = x_in;
    var f: f32 = if (x < 0.0) 1.0 else 0.0;
    if (x <= -126.0) x = -126.0;
    f = f + (x - @as(f32, @floatFromInt(@as(i32, @intFromFloat(@trunc(x))))));
    const total: f32 = ((x + 121.274055) + 27.728024 / (4.8425255 - f)) + f * -1.4901291;
    // fcvtzs x8,s0,#0x17: (i64)(total * 2^23) truncated toward zero, then the
    // integer bits are the result float.
    const i: i64 = @intFromFloat(@as(f64, total) * 8388608.0);
    return @bitCast(@as(u32, @truncate(@as(u64, @bitCast(i)))));
}

/// (float)Math::log2Precise((double)x) — the PRECISE double log2 used by the
/// noise expression `log2` builtin (NoiseOperations::Functions::log2
/// @0x1015fd4b8), distinct from the fast Math::log2 the minkowski3 distance
/// uses.
pub fn preciseLog2(x: f32) f32 {
    return @floatCast(@log2(@as(f64, x)));
}

/// Engine's fast Math::log2 (approx, f32).
pub fn fastLog2(x: f32) f32 {
    const b: u32 = @bitCast(x);
    const mant: f32 = @bitCast((b & 0x7fffff) | 0x3f000000);
    var s: f32 = @as(f32, @floatFromInt(b)) * 1.1920929e-07 + (-124.22552);
    s = s + mant * -1.4980303;
    s = s + -1.72588 / (mant + 0.35208872);
    return s;
}

/// Distance between sample position (xs, ys) and a point (px, py) in grid
/// units, in the engine's exact f32 op order for the given metric.
fn voronoiDist(metric: VoronoiDistanceType, xs: f32, ys: f32, px: f32, py: f32, offx: f32, offy: f32) f32 {
    const dx: f32 = (px + offx) - xs; // engine: (point + cell offset) - sample frac
    const dy: f32 = (py + offy) - ys;
    const ax = @abs(dx);
    const ay = @abs(dy);
    return switch (metric) {
        .euclidean => @sqrt((ax * ax) + (ay * ay)),
        .manhattan => ax + ay,
        .chebyshev => @max(ax, ay),
        .minkowski3 => blk: {
            const s: f32 = (ax * ax * ax) + (ay * ay * ay);
            if (s == 0.0) break :blk 0.0;
            break :blk fastExp2f(fastLog2(s) * 0.33333334);
        },
    };
}

pub const VoronoiNoise = struct {
    seed: u32,
    grid: u16,
    distance_type: VoronoiDistanceType,
    jitter: f32,

    /// Evaluation result of one sample (in grid units; id in [0,1)).
    pub const Result = struct {
        nearest: f32, // out A: voronoi_spot_noise
        gap: f32, // out B: d1 - d0 (voronoi_facet_noise)
        pyramid: f32, // out C: bisector distance (voronoi_pyramid_noise)
        cell_id: f32, // out D: winner cell id (voronoi_cell_id)
    };

    pub fn init(seed0: u32, seed1: u32, grid: u16, distance_type: VoronoiDistanceType, jitter: f32) VoronoiNoise {
        // +0x20 = asNoiseLayerID(seed1) + (int)seed0: seed1 is the resolved
        // name id (crc32(name) for string seeds, the number itself otherwise)
        // added to seed0, mirroring the op ctor @0x1016126b8.
        return .{ .seed = seed0 +% seed1, .grid = grid, .distance_type = distance_type, .jitter = jitter };
    }

    /// Evaluate at tile coordinates (x, y). The engine indexes cells by
    /// floor(x/grid) and evaluates the 3x3 window around the sample cell
    /// (empirically sufficient for every distance type/jitter the planets
    /// use — the ring-2 point-list expansion only affects region edges).
    pub fn evalAt(self: *const VoronoiNoise, x: f64, y: f64) Result {
        const g: f32 = @floatFromInt(self.grid);
        const sx = @floor(x / @as(f64, g));
        const sy = @floor(y / @as(f64, g));
        const sxi: i32 = @intFromFloat(sx);
        const syi: i32 = @intFromFloat(sy);
        const xg: f32 = @floatCast(x / @as(f64, g));
        const yg: f32 = @floatCast(y / @as(f64, g));
        const xfrac: f32 = xg - @as(f32, @floatFromInt(sxi));
        const yfrac: f32 = yg - @as(f32, @floatFromInt(syi));

        var d0: f32 = std.math.inf(f32);
        var d1: f32 = std.math.inf(f32);
        var win: [2]f32 = undefined; // winner point (grid units, abs cell + rel)
        var wid: f32 = 0;
        var dy: i32 = -1;
        while (dy <= 1) : (dy += 1) {
            var dx: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                const p = voronoiPoint(sxi + dx, syi + dy, self.seed, self.jitter);
                const d = voronoiDist(self.distance_type, xfrac, yfrac, p.x, p.y,
                    @floatFromInt(dx), @floatFromInt(dy));
                if (d < d0) {
                    d1 = d0;
                    d0 = d;
                    win = .{ @as(f32, @floatFromInt(sxi + dx)) + p.x, @as(f32, @floatFromInt(syi + dy)) + p.y };
                    wid = p.id;
                } else if (d < d1) {
                    d1 = d;
                }
            }
        }

        // pyramid: min over the other 8 window points of the distance from the
        // sample to the perpendicular bisector of (winner, that point).
        var pyr: f32 = std.math.inf(f32);
        dy = -1;
        while (dy <= 1) : (dy += 1) {
            var dx: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                const p = voronoiPoint(sxi + dx, syi + dy, self.seed, self.jitter);
                const px: f32 = @as(f32, @floatFromInt(sxi + dx)) + p.x;
                const py: f32 = @as(f32, @floatFromInt(syi + dy)) + p.y;
                if (px == win[0] and py == win[1]) continue;
                const dab2 = (win[0] - px) * (win[0] - px) + (win[1] - py) * (win[1] - py);
                if (dab2 == 0.0) continue;
                const da2 = (xg - win[0]) * (xg - win[0]) + (yg - win[1]) * (yg - win[1]);
                const db2 = (xg - px) * (xg - px) + (yg - py) * (yg - py);
                const d: f32 = @abs(da2 - db2) / (2.0 * @sqrt(dab2));
                if (d < pyr) pyr = d;
            }
        }
        return .{ .nearest = d0, .gap = d1 - d0, .pyramid = pyr, .cell_id = wid };
    }
};

// ============================================================
// terrace — exact port of Factorio 2.0's Terrace op
// ============================================================

// NoiseOperations::Terrace::run @0x1015f1450. Data call:
//   terrace{value = V, offset = O, width = W, strength = S}
// with value & strength evaluated as registers; offset/width constants. Per
// sample (engine scalar tail): q = (value - offset)/width;
// qf = floor(q); frac = q - qf;
// t = strength < frac ? (frac - strength)/(1 - strength) : 0;
// out = offset + width * (qf + t).
// strength = 0 -> identity; strength = 1 -> pure quantization. Uses FLOOR for
// the integer part (verified on negative values where trunc would differ).
pub fn terrace(value: f64, offset: f32, width: f32, strength: f32) f64 {
    const v: f32 = @floatCast(value);
    const q: f32 = (v - offset) / width;
    const qf: f32 = @floatFromInt(@as(i32, @intFromFloat(@floor(q))));
    const frac: f32 = q - qf;
    var t: f32 = 0.0;
    if (strength < frac) t = (frac - strength) / (1.0 - strength);
    return @as(f64, offset + width * (qf + t));
}

// ============================================================
// Tests
// ============================================================

// Vectors below are f32 values returned by the live game (2.0.77) via
// calculate_tile_properties for the same expression configs — see
// calibration/sa-probe (probe-runs 0-4). Columns: grid, jitter, metric, seed,
// x, y, spot(d0), facet(d1-d0), cell id. Metric: 0=chebyshev 1=manhattan
// 2=euclidean 3=minkowski3. seed = map seed 341 + seed1 (42 / crc32(name)).
const VORONOI_VECS = [_][9]f64{
    .{ 32, 0.0, 2, 383, 16, 16, 0.0, 1.0, 0.6794518232345581 },
    .{ 32, 0.0, 2, 383, 0, 0, 0.7071067690849304, 0.0, 0.6794518232345581 },
    .{ 32, 1.0, 2, 383, 120, -32, 0.622063279, 0.241138577, 0.674882889 },
    .{ 24, 0.25, 1, 383, 10, 8, 0.258902639, 0.493976086, 0.6794518232345581 },
    .{ 16, 0.5, 3, 383, -62, -64, 0.415092468, 0.138198853, 0.757491589 },
    .{ 64, 0.35, 1, 1512814738, 64, 0, -1, 0.0563282371, 0.694923699 }, // tag i (seed1='fulgora_cells'); spot unprobed
};

// Seeds in the probes were map-seed 341 + seed1 value (42 or crc32(name)); the
// op seed = seed0 + seed1. crc32("hxprobe") + 341 = 3543714748, crc32("aquilo-cracks") + 341 = 1475574598.

test "voronoi point hash reproduces the game's per-cell ids" {
    // seed 383 (seed1=42 + map 341), jitter 0: cell id of (cx,cy) must match.
    // id(0,0) & id(-1,-1) share (ror16(-1) == -1 makes the axis mixes cancel);
    // id(-1,0) == id(0,-1); other cells distinct.
    const V = VoronoiNoise.init(341, 42, 32, .euclidean, 0.0);
    const a = V.evalAt(16, 16).cell_id;
    const b = V.evalAt(-16, -16).cell_id;
    try std.testing.expectEqual(a, b);
    try std.testing.expectEqual(V.evalAt(-16, 16).cell_id, V.evalAt(16, -16).cell_id);
    try std.testing.expect(a != V.evalAt(48, 16).cell_id);
}

test "voronoi eval matches live-game vectors" {
    for (VORONOI_VECS) |v| {
        const grid: u16 = @intFromFloat(v[0]);
        const jitter: f32 = @floatCast(v[1]);
        const metric: VoronoiDistanceType = @enumFromInt(@as(u8, @intFromFloat(v[2])));
        const s1: u32 = @intFromFloat(v[3]);
        const x: f64 = v[4];
        const y: f64 = v[5];
        const V = VoronoiNoise.init(341, s1 -% 341, grid, metric, jitter);
        const r = V.evalAt(x, y);
        if (v[6] >= 0.0) try std.testing.expectApproxEqAbs(@as(f64, r.nearest), v[6], 1e-6);
        try std.testing.expectApproxEqAbs(@as(f64, r.gap), v[7], 1e-6);
        try std.testing.expectApproxEqAbs(@as(f64, r.cell_id), v[8], 1e-6);
    }
}

test "voronoi pyramid (bisector) matches live game" {
    // out C = distance from sample to the nearest perpendicular bisector of the
    // nearest point and any other window point: 0.5 at a cell centre, 0 on the
    // grid (bisector through the sample).
    const A = VoronoiNoise.init(341, 42, 32, .euclidean, 0.0);
    try std.testing.expectApproxEqAbs(@as(f64, A.evalAt(16, 16).pyramid), 0.5, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f64, A.evalAt(0, 0).pyramid), 0.0, 1e-6);
    const B = VoronoiNoise.init(341, 42, 32, .euclidean, 0.5);
    try std.testing.expectApproxEqAbs(@as(f64, B.evalAt(16, 16).pyramid), 0.39552483, 1e-6);
}

test "terrace matches live-game formula (floor semantics)" {
    // terrace{value=-25+30x, offset=40, width=20, strength=0.2}: v(150) -> 147.5;
    // negative quotients FLOOR: v(-1225) -> -1226.25 (trunc would give -1220).
    try std.testing.expectApproxEqAbs(terrace(-1225.0, 40, 20, 0.2), -1226.25, 1e-3);
    try std.testing.expectApproxEqAbs(terrace(150.0, 40, 20, 0.2), 147.5, 1e-3);
}

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

