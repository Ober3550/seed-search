//! Alien-biomes tile classifier: given (x, y, temperature, moisture, aux,
//! elevation), pick the winning tile and return its map_color. Full port of
//! alien-biomes 0.7.4 build_tiles probability_expression:
//!   fitness = min over dims of plateau_peak(v,center,range)
//!           + beach (beach_weight<0 -> min(0, elev/5-1))
//!           + frozen ice/snow water noise (water_coef * multioctave{'water'})
//!           + dirt-3/4 crater noise (-0.6 - 0.7*multioctave{'crater'})
//!           + 0.5 * terrain-variation multioctave{seed1=tv_seed, offset_x=1000}
//! winner = max fitness -> map_color.

const std = @import("std");
const noise = @import("noise.zig");
const table = @import("biome_table.zig");

pub const Biome = table.Biome;
pub const biomes = table.biomes;

// The noise compiler resolves a string seed1 to CRC32(name) (verified exact vs
// the game's probe_water/probe_crater, mse=0).
pub const WATER_SEED: u32 = 4214428890; // crc32("water")
pub const CRATER_SEED: u32 = 3394482400; // crc32("crater")

fn plateauPeak(v: f32, lohi: [2]f64) f32 {
    const lo: f32 = @floatCast(lohi[0]);
    const hi: f32 = @floatCast(lohi[1]);
    const center = (lo + hi) / 2.0;
    const range = @abs(lo - hi) / 2.0;
    return @min((range - @abs(v - center)) * 20.0, 1.0);
}

/// Precomputes one basis generator per tile (terrain-variation) plus the shared
/// water/crater generators, so classification does no per-call allocation.
pub const Classifier = struct {
    tv_gens: [biomes.len]noise.BasisNoiseGen,
    water_gen: noise.BasisNoiseGen,
    crater_gen: noise.BasisNoiseGen,

    pub fn init(map_seed: u32) Classifier {
        var c: Classifier = undefined;
        for (biomes, 0..) |b, i| c.tv_gens[i] = noise.BasisNoiseGen.init(map_seed, b.tv_seed);
        c.water_gen = noise.BasisNoiseGen.init(map_seed, WATER_SEED);
        c.crater_gen = noise.BasisNoiseGen.init(map_seed, CRATER_SEED);
        return c;
    }

    /// Winning land-biome index + its fitness (so water tiles can compete on the
    /// same scale in classifyTile).
    pub fn classifyBest(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) struct { idx: usize, fit: f32 } {
        // Fitness in f32 to match the engine's f32 probability evaluation.
        const tf: f32 = @floatCast(t);
        const mf: f32 = @floatCast(m);
        const af: f32 = @floatCast(a);
        const ef: f32 = @floatCast(e);
        // shared noise fields (same for every candidate tile at this position)
        const water_noise: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 8.0, 0.666));
        const crater_noise: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.crater_gen, x, y, 5, 0.75, 1.0 / 6.0 / 1.0, 0.666));
        const beach: f32 = @min(@as(f32, 0.0), ef / 5.0 - 1.0);

        var best_i: usize = 0;
        var best_f: f32 = -std.math.inf(f32);
        for (biomes, 0..) |b, i| {
            var f: f32 = std.math.inf(f32);
            if (b.t) |r| f = @min(f, plateauPeak(tf, r));
            if (b.m) |r| f = @min(f, plateauPeak(mf, r));
            if (b.a) |r| f = @min(f, plateauPeak(af, r));
            if (b.e) |r| f = @min(f, plateauPeak(ef, r));
            if (b.beach_weight < 0.0) f += beach;
            if (b.water_coef != 0.0) f += @as(f32, @floatCast(b.water_coef)) * water_noise;
            if (b.crater) f += -0.6 - 0.7 * crater_noise;
            f += 0.5 * @as(f32, @floatCast(noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0)));
            if (f > best_f) {
                best_f = f;
                best_i = i;
            }
        }
        return .{ .idx = best_i, .fit = best_f };
    }

    pub fn classifyIndex(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) usize {
        return self.classifyBest(x, y, t, m, a, e).idx;
    }

    pub fn classifyColor(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) [3]u8 {
        return biomes[self.classifyIndex(x, y, t, m, a, e)].color;
    }

    /// Full tile classification INCLUDING the water/wetland tiles (water,
    /// deepwater, water-shallow, water-mud), which compete in the same argmax as
    /// the land biomes. These aren't in the biome table — they have bespoke
    /// probability expressions (elevation-gated for water/deepwater/shallow;
    /// temperature+high-freq-water-noise for the wetland water-mud). Returns the
    /// winning tile's map colour. Replaces the old hard `e<0 -> water` gate.
    pub const Tile = struct { color: [3]u8, name: []const u8, fit: f32 };

    pub fn classifyTile(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) Tile {
        const land = self.classifyBest(x, y, t, m, a, e);
        var best = Tile{ .color = biomes[land.idx].color, .name = biomes[land.idx].name, .fit = land.fit };
        const tf: f32 = @floatCast(t);
        const ef: f32 = @floatCast(e);

        // high-frequency 'water' layers used by water-shallow / water-mud.
        const wn_a: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 0.25, 0.666));
        const wn_b: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 0.314, 0.666));
        const consider = struct {
            fn go(f: f32, c: [3]u8, n: []const u8, b: *Tile) void {
                if (f > b.fit) b.* = .{ .color = c, .name = n, .fit = f };
            }
        }.go;

        // water-mud: plateau_peak(temp,50,50) + 0.5*min(wn_a,wn_b) + min(0,-1+e/5) - 1.15
        const mud: f32 = plateauPeak(tf, .{ 0.0, 100.0 }) + 0.5 * @min(wn_a, wn_b) + @min(@as(f32, 0.0), -1.0 + ef / 5.0) - 1.15;
        consider(mud, water_mud, "water-mud", &best);

        if (e < 0.0) {
            // water: 100*min(-e,1);  deepwater: 200*min(-5-e,1) for e<-5;
            // water-shallow: 200*min(-e,1) + wn_a*50 + e*100 + min(t,0)*10000
            consider(100.0 * @min(-ef, 1.0), water, "water", &best);
            if (e < -5.0) consider(200.0 * @min(-5.0 - ef, 1.0), deepwater, "deepwater", &best);
            consider(200.0 * @min(-ef, 1.0) + wn_a * 50.0 + ef * 100.0 + @min(tf, 0.0) * 10000.0, water_shallow, "water-shallow", &best);
        }
        return best;
    }

    /// Same argmax competition as classifyTile but returns the unified tile index
    /// (land biome index, or IDX_WATER/DEEPWATER/SHALLOW/MUD). Used by the grid
    /// tile-correction pass, which needs indices + layers, not colours.
    pub fn classifyIdx(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) u16 {
        const land = self.classifyBest(x, y, t, m, a, e);
        var best_f = land.fit;
        var best_idx: u16 = @intCast(land.idx);
        const tf: f32 = @floatCast(t);
        const ef: f32 = @floatCast(e);
        const wn_a: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 0.25, 0.666));
        const wn_b: f32 = @floatCast(noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 0.314, 0.666));
        const consider = struct {
            fn go(f: f32, idx: u16, bf: *f32, bi: *u16) void {
                if (f > bf.*) {
                    bf.* = f;
                    bi.* = idx;
                }
            }
        }.go;
        const mud: f32 = plateauPeak(tf, .{ 0.0, 100.0 }) + 0.5 * @min(wn_a, wn_b) + @min(@as(f32, 0.0), -1.0 + ef / 5.0) - 1.15;
        consider(mud, IDX_MUD, &best_f, &best_idx);
        if (e < 0.0) {
            consider(100.0 * @min(-ef, 1.0), IDX_WATER, &best_f, &best_idx);
            if (e < -5.0) consider(200.0 * @min(-5.0 - ef, 1.0), IDX_DEEPWATER, &best_f, &best_idx);
            consider(200.0 * @min(-ef, 1.0) + wn_a * 50.0 + ef * 100.0 + @min(tf, 0.0) * 10000.0, IDX_SHALLOW, &best_f, &best_idx);
        }
        return best_idx;
    }

    /// Debug: print the full fitness breakdown for the top-N tiles at (x,y), so a
    /// disagreement with the ground truth can be traced to a specific term.
    pub fn probe(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) void {
        const water_noise = noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 8.0, 0.666);
        const crater_noise = noise.multioctaveNoisePrebuilt(&self.crater_gen, x, y, 5, 0.75, 1.0 / 6.0 / 1.0, 0.666);
        const tf: f32 = @floatCast(t);
        const mf: f32 = @floatCast(m);
        const af: f32 = @floatCast(a);
        const ef: f32 = @floatCast(e);
        const beach: f32 = @min(@as(f32, 0.0), ef / 5.0 - 1.0);
        std.debug.print("  water_noise={d:.4} crater_noise={d:.4} beach={d:.4}\n", .{ water_noise, crater_noise, beach });

        var fits: [biomes.len]f32 = undefined;
        for (biomes, 0..) |b, i| {
            var f: f32 = std.math.inf(f32);
            if (b.t) |r| f = @min(f, plateauPeak(tf, r));
            if (b.m) |r| f = @min(f, plateauPeak(mf, r));
            if (b.a) |r| f = @min(f, plateauPeak(af, r));
            if (b.e) |r| f = @min(f, plateauPeak(ef, r));
            if (b.beach_weight < 0.0) f += beach;
            if (b.water_coef != 0.0) f += @as(f32, @floatCast(b.water_coef)) * @as(f32, @floatCast(water_noise));
            if (b.crater) f += -0.6 - 0.7 * @as(f32, @floatCast(crater_noise));
            f += 0.5 * @as(f32, @floatCast(noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0)));
            fits[i] = f;
        }
        var order: [biomes.len]usize = undefined;
        for (0..biomes.len) |i| order[i] = i;
        std.mem.sort(usize, &order, &fits, struct {
            fn lt(fs: *const [biomes.len]f32, ia: usize, ib: usize) bool {
                return fs[ia] > fs[ib]; // descending
            }
        }.lt);
        var rank: usize = 0;
        while (rank < 12 and rank < biomes.len) : (rank += 1) {
            const i = order[rank];
            const b = biomes[i];
            const tv = 0.5 * noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
            const tpk = if (b.t) |r| plateauPeak(tf, r) else std.math.inf(f32);
            const mpk = if (b.m) |r| plateauPeak(mf, r) else std.math.inf(f32);
            const apk = if (b.a) |r| plateauPeak(af, r) else std.math.inf(f32);
            const bch: f64 = if (b.beach_weight < 0.0) beach else 0.0;
            const wtr: f64 = if (b.water_coef != 0.0) b.water_coef * water_noise else 0.0;
            std.debug.print("  #{d:>2} f={d:.4}  {s:<26} rgb={d},{d},{d}  tpk={d:.3} mpk={d:.3} apk={d:.3} beach={d:.3} water={d:.3} tv={d:.4}\n", .{ rank, fits[i], b.name, b.color[0], b.color[1], b.color[2], tpk, mpk, apk, bch, wtr, tv });
        }
    }
};

/// WIP / EXPERIMENTAL (opt-in via segen --biome-corrected only; NOT used by the
/// production render). This first cut of the geometry OVER-triggers (single-pass
/// 86.6%, cascaded 25% vs 95.2% uncorrected) — the exact decompiled condition
/// (the x+2di,y-2 "beyond" tile test + the per-tile allowed-neighbour table at
/// prototype offset 0x1ab8) is more restrictive than this. Needs refinement.
/// Port of Factorio's TileCorrectionMapGenerationTask,
/// ghidra/export/tile_gen.c). A tile whose transition `layer` is higher than a
/// lower orthogonal neighbour, where the diagonal beyond that neighbour is higher
/// still and the perpendicular support tile is NOT higher than the candidate, has
/// "weak diagonal support" and is corrected down to that lower neighbour. Iterated
/// to a fixpoint so corrections cascade. `grid` is size×size unified tile indices.
const NEIGHBORS8 = [_][2]i32{ .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 }, .{ -1, 0 }, .{ 1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 } };
const ORTH4 = [_][2]i32{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };

/// Is `tile` at (x,y) consistent given the already-FIXED neighbours? Mirrors
/// isTileConsistentWithFixedTiles's diagonal-support test: a candidate with a
/// lower FIXED orthogonal neighbour N, where the diagonal beyond N (perpendicular)
/// is a fixed tile higher than N and the perpendicular support tile isn't higher
/// than the candidate, has weak diagonal support → inconsistent. Returns the
/// offending lower neighbour as the replacement candidate.
fn tileConsistent(grid: []const u16, fixed: []const bool, w: i32, x: i32, y: i32, tile: u16, cand: *u16) bool {
    const get = struct {
        fn f(g: []const u16, fx: []const bool, sz: i32, ax: i32, ay: i32, fixed_only: bool) u16 {
            if (ax < 0 or ay < 0 or ax >= sz or ay >= sz) return IDX_BG;
            const gi: usize = @intCast(ay * sz + ax);
            if (fixed_only and !fx[gi]) return IDX_BG;
            return g[gi];
        }
    }.f;
    const L = idxLayer(tile);
    for (ORTH4) |o| {
        const N = get(grid, fixed, w, x + o[0], y + o[1], true);
        if (N == IDX_BG) continue;
        const Ln = idxLayer(N);
        if (Ln >= L) continue;
        var s: i32 = -1;
        while (s <= 1) : (s += 2) {
            const dxp = if (o[0] != 0) x + o[0] else x + s;
            const dyp = if (o[0] != 0) y + s else y + o[1];
            const sxp = if (o[0] != 0) x else x + s;
            const syp = if (o[0] != 0) y + s else y;
            const D = get(grid, fixed, w, dxp, dyp, true);
            const S = get(grid, fixed, w, sxp, syp, true);
            if (D == IDX_BG or S == IDX_BG) continue;
            if (idxLayer(D) > Ln and idxLayer(S) <= L) {
                cand.* = N;
                return false;
            }
        }
    }
    return true;
}

pub fn correctTiles(alloc: std.mem.Allocator, grid: []u16, size: usize) void {
    const w: i32 = @intCast(size);
    const fixed = alloc.alloc(bool, grid.len) catch return;
    defer alloc.free(fixed);
    @memset(fixed, false);
    var queue = std.ArrayList(u32).empty;
    defer queue.deinit(alloc);
    // Seed a BFS from every tile in raster order (Factorio's driver seeds
    // correctFromTile per chunk tile); the fixed[] mask makes each check see only
    // settled context, so corrections don't avalanche.
    var sy: i32 = 0;
    while (sy < w) : (sy += 1) {
        var sx: i32 = 0;
        while (sx < w) : (sx += 1) {
            const si: usize = @intCast(sy * w + sx);
            if (fixed[si] or grid[si] == IDX_BG) continue;
            queue.clearRetainingCapacity();
            queue.append(alloc, @intCast(si)) catch return;
            fixed[si] = true;
            var qi: usize = 0;
            while (qi < queue.items.len) : (qi += 1) {
                const p = queue.items[qi];
                const px: i32 = @intCast(p % @as(u32, @intCast(w)));
                const py: i32 = @intCast(p / @as(u32, @intCast(w)));
                for (NEIGHBORS8) |o| {
                    const nx = px + o[0];
                    const ny = py + o[1];
                    if (nx < 0 or ny < 0 or nx >= w or ny >= w) continue;
                    const ni: usize = @intCast(ny * w + nx);
                    if (fixed[ni] or grid[ni] == IDX_BG) continue;
                    var cand: u16 = grid[ni];
                    var enqueue = false;
                    if (!tileConsistent(grid, fixed, w, nx, ny, grid[ni], &cand)) {
                        // replace with the offending lower neighbour if that's consistent
                        var c2: u16 = cand;
                        if (cand != grid[ni] and tileConsistent(grid, fixed, w, nx, ny, cand, &c2)) {
                            grid[ni] = cand;
                        }
                        enqueue = true;
                    }
                    fixed[ni] = true;
                    if (enqueue) queue.append(alloc, @intCast(ni)) catch return;
                }
            }
        }
    }
}

/// Water tile colors (Horaerratum legend values).
pub const deepwater: [3]u8 = .{ 38, 64, 73 };
pub const water: [3]u8 = .{ 51, 83, 95 };
pub const water_shallow: [3]u8 = .{ 53, 97, 110 };
pub const water_mud: [3]u8 = .{ 54, 88, 90 };

/// Base-game water palette — used for Nauvis under the base / Space Age configs
/// (SE water is the Horaerratum teal above).
pub const vanilla_water: [3]u8 = .{ 62, 120, 176 };
pub const vanilla_deepwater: [3]u8 = .{ 34, 70, 118 };

// ── Vanilla Nauvis ground (approximate) ────────────────────────────────────
// The alien-biomes tiles above are Space-Exploration-only. Rendering Nauvis in
// the base / Space Age configs with them leaks SE biomes into non-SE previews.
// The base 2.0 tile-autoplace expressions aren't exported yet, so this is a
// visual approximation of the vanilla look: temperature bands (snow cold →
// green temperate → dry/hot), moisture (grass ↔ dry grass ↔ dirt/sand), aux
// dusting, sandy shores near water, plus a gentle per-pixel texture. It keeps
// the alien palette (and the exact SE ground truth) exclusively for SE configs.
fn vclamp(v: f64, lo: f64, hi: f64) f64 {
    return @max(lo, @min(hi, v));
}
fn vramp(v: f64, a: f64, b: f64) f64 {
    // linear 0→1 as v goes a→b
    return vclamp((v - a) / (b - a), 0.0, 1.0);
}
fn vmix(c1: [3]u8, c2: [3]u8, t: f64) [3]u8 {
    const s = t * t * (3.0 - 2.0 * t); // smoothstep
    return .{
        @intFromFloat(@as(f64, @floatFromInt(c1[0])) + (@as(f64, @floatFromInt(c2[0])) - @as(f64, @floatFromInt(c1[0]))) * s),
        @intFromFloat(@as(f64, @floatFromInt(c1[1])) + (@as(f64, @floatFromInt(c2[1])) - @as(f64, @floatFromInt(c1[1]))) * s),
        @intFromFloat(@as(f64, @floatFromInt(c1[2])) + (@as(f64, @floatFromInt(c2[2])) - @as(f64, @floatFromInt(c1[2]))) * s),
    };
}
fn vshade(c: [3]u8, f: f64) [3]u8 {
    return .{
        @intFromFloat(vclamp(@as(f64, @floatFromInt(c[0])) * f, 0.0, 255.0)),
        @intFromFloat(vclamp(@as(f64, @floatFromInt(c[1])) * f, 0.0, 255.0)),
        @intFromFloat(vclamp(@as(f64, @floatFromInt(c[2])) * f, 0.0, 255.0)),
    };
}

/// Vanilla Nauvis land colour for a tile at (x,y) with the zone's temperature /
/// moisture / aux / elevation. Only called with e >= 0 (water handled by the
/// caller). Approximation — see note above.
pub fn vanillaNauvisLand(x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) [3]u8 {
    const snow_col: [3]u8 = .{ 236, 240, 244 };
    const grass_col: [3]u8 = .{ 99, 137, 60 };
    const lush_col: [3]u8 = .{ 71, 112, 51 };
    const dead_col: [3]u8 = .{ 171, 156, 102 };
    const dirt_col: [3]u8 = .{ 127, 103, 76 };
    const sand_col: [3]u8 = .{ 199, 177, 122 };

    // snow appears only in genuinely cold regions (t < ~0-8, e.g. map poles).
    const snow = vramp(t, 18.0, 2.0); // 1 when t<=2, 0 when t>=18

    // temperate moisture: wet → grass, dry → dead grass / dirt.
    var c: [3]u8 = grass_col;
    if (m < 0.55) {
        c = vmix(grass_col, dead_col, vramp(m, 0.45, 0.12));
        c = vmix(c, dirt_col, 0.35 * vramp(m, 0.25, 0.0));
    } else {
        c = vmix(grass_col, lush_col, vramp(m, 0.6, 0.92));
    }
    // low aux = dustier ground.
    c = vmix(c, dirt_col, 0.55 * vramp(a, 0.34, 0.1));

    // hot desert fringe (rare on Nauvis, dominant only at very high t).
    const hot = vramp(t, 68.0, 88.0);
    const desert = vmix(dirt_col, sand_col, vramp(m, 0.55, 0.05));
    c = vmix(c, desert, hot);

    // sandy shores near water: strongest right at the coastline, only on dry
    // ground (moisture low), suppressed in the snow.
    const shore = @exp(-e * 0.9);
    c = vmix(c, vmix(dirt_col, sand_col, 0.85), 0.6 * shore * (1.0 - snow) * (1.0 - vramp(m, 0.5, 0.15)));

    // snow overrides everything in cold areas (soft band overlap).
    c = vmix(c, snow_col, snow);

    // gentle texture: tiny per-tile brightness wobble from a fixed gradient
    // noise (approximation of the vanilla tile variants).
    const j = vclamp(noise.basisNoise(x, y, 0x51F4AE, 0x6A09E667, 1.0 / 26.0, 1.0), -1.0, 1.0);
    return vshade(c, 1.0 + 0.055 * j);
}

// Unified tile-index space for the tile-correction pass: 0..biomes.len-1 are land
// biomes; the following are the water/wetland tiles; BG = outside the disk.
pub const IDX_WATER: u16 = 60000;
pub const IDX_DEEPWATER: u16 = 60001;
pub const IDX_SHALLOW: u16 = 60002;
pub const IDX_MUD: u16 = 60003;
pub const IDX_BG: u16 = 65535;

pub fn idxLayer(idx: u16) u16 {
    return switch (idx) {
        IDX_WATER, IDX_DEEPWATER => 67,
        IDX_SHALLOW => 70,
        IDX_MUD => 71,
        IDX_BG => 0,
        else => table.tile_layer[idx],
    };
}
pub fn idxColor(idx: u16) [3]u8 {
    return switch (idx) {
        IDX_WATER => water,
        IDX_DEEPWATER => deepwater,
        IDX_SHALLOW => water_shallow,
        IDX_MUD => water_mud,
        IDX_BG => .{ 20, 20, 20 },
        else => biomes[idx].color,
    };
}
pub fn idxName(idx: u16) []const u8 {
    return switch (idx) {
        IDX_WATER => "water",
        IDX_DEEPWATER => "deepwater",
        IDX_SHALLOW => "water-shallow",
        IDX_MUD => "water-mud",
        IDX_BG => "out-of-map",
        else => biomes[idx].name,
    };
}

/// Simplified biome-category background colors for the ore map. Deliberately
/// dark/muted so the bright ore colors (vulcanite red, cryonite blue,
/// vitamelange yellow-green, etc.) stand out on top — e.g. volcanic is a dark
/// warm brown, NOT red, so red vulcanite ore is visible.
pub const CatBg = struct {
    pub const water: [3]u8 = .{ 34, 58, 104 }; // blue (no ore here)
    pub const ice: [3]u8 = .{ 198, 208, 220 }; // light grey (cryonite=frozen)
    pub const volcanic: [3]u8 = .{ 92, 44, 37 }; // dark red-brown (vulcanite)
    pub const vita: [3]u8 = .{ 44, 78, 51 }; // dark green (vitamelange)
    pub const other: [3]u8 = .{ 70, 64, 60 }; // neutral grey (common ores)
};

/// Map a winning biome index to its simplified ore-relevant category background.
pub fn categoryBg(i: usize) [3]u8 {
    const b = biomes[i];
    if (std.mem.eql(u8, b.group, "frozen")) return CatBg.ice;
    if (std.mem.eql(u8, b.group, "volcanic")) return CatBg.volcanic;
    if ((b.restrict & 4) != 0) return CatBg.vita; // se-vitamelange-allowed set
    return CatBg.other;
}

/// True if the resource is biome-restricted (needs a tile classify to gate).
/// Only se-vulcanite/cryonite/vitamelange restrict; every other ore places on
/// any land tile (water is excluded separately by the resource collision mask).
pub fn isBiomeRestricted(resource_name: []const u8) bool {
    return std.mem.eql(u8, resource_name, "se-vulcanite") or
        std.mem.eql(u8, resource_name, "se-cryonite") or
        std.mem.eql(u8, resource_name, "se-vitamelange");
}

/// Whether `resource_name` may place on the winning biome at `biome_index`.
/// Uses the tile_restriction bits baked into biome_table (1=vulcanite,
/// 2=cryonite, 4=vitamelange). Non-restricted resources return true.
pub fn oreAllowedOnBiome(resource_name: []const u8, biome_index: usize) bool {
    const r = biomes[biome_index].restrict;
    if (std.mem.eql(u8, resource_name, "se-vulcanite")) return (r & 1) != 0;
    if (std.mem.eql(u8, resource_name, "se-cryonite")) return (r & 2) != 0;
    if (std.mem.eql(u8, resource_name, "se-vitamelange")) return (r & 4) != 0;
    return true;
}
