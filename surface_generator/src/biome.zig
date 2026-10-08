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

// ── Base-game (vanilla 2.0) Nauvis ground ──────────────────────────────────
// Nauvis under the base / Space Age configs must NOT use the alien-biomes
// tilesheet (that is Space-Exploration-only ground). This is a data-driven
// port of the base tile autoplace competition (base/prototypes/tile/tiles.lua,
// 2.0.77): each tile prototype carries
//   probability_expression = moisture/aux band(s) + noise_layer_noise(seed)
// and water/deepwater use water_base(elevation) — all competing in one argmax,
// exactly the engine's basic-tiles task. Real map_colours are used verbatim.
// The one engine primitive not ported yet is expression_in_range (band-edge
// shape), so bands use the same linear plateau as the alien-biomes classifier
// (verified shape) — selection is therefore approximate until it's RE'd, but
// the tile set / palette / competition structure is the real data.

/// Base-Nauvis palette (index → { name, map_colour }); index order == the
/// per-pixel tile ids the classifier returns.
pub const NauvisTile = struct { name: []const u8, color: [3]u8 };

pub const NB_WATER: u8 = 0;
pub const NB_DEEPWATER: u8 = 1;
pub const NB_SAND1: u8 = 2;
pub const NB_SAND2: u8 = 3;
pub const NB_SAND3: u8 = 4;
pub const NB_DRY_DIRT: u8 = 5;
pub const NB_DIRT1: u8 = 6;
pub const NB_DIRT2: u8 = 7;
pub const NB_DIRT3: u8 = 8;
pub const NB_DIRT4: u8 = 9;
pub const NB_DIRT5: u8 = 10;
pub const NB_DIRT6: u8 = 11;
pub const NB_DIRT7: u8 = 12;
pub const NB_GRASS1: u8 = 13;
pub const NB_GRASS2: u8 = 14;
pub const NB_GRASS3: u8 = 15;
pub const NB_GRASS4: u8 = 16;
pub const NB_REDDESERT0: u8 = 17;
pub const NB_REDDESERT1: u8 = 18;
pub const NB_REDDESERT2: u8 = 19;
pub const NB_REDDESERT3: u8 = 20;

pub const nauvis_base_palette = [_]NauvisTile{
    .{ .name = "water", .color = .{ 51, 83, 95 } },
    .{ .name = "deepwater", .color = .{ 38, 64, 73 } },
    .{ .name = "sand-1", .color = .{ 138, 103, 58 } },
    .{ .name = "sand-2", .color = .{ 128, 93, 52 } },
    .{ .name = "sand-3", .color = .{ 115, 83, 47 } },
    .{ .name = "dry-dirt", .color = .{ 94, 66, 37 } },
    .{ .name = "dirt-1", .color = .{ 141, 104, 60 } },
    .{ .name = "dirt-2", .color = .{ 136, 96, 59 } },
    .{ .name = "dirt-3", .color = .{ 133, 92, 53 } },
    .{ .name = "dirt-4", .color = .{ 103, 72, 43 } },
    .{ .name = "dirt-5", .color = .{ 91, 63, 38 } },
    .{ .name = "dirt-6", .color = .{ 80, 55, 31 } },
    .{ .name = "dirt-7", .color = .{ 80, 54, 28 } },
    .{ .name = "grass-1", .color = .{ 55, 53, 11 } },
    .{ .name = "grass-2", .color = .{ 66, 57, 15 } },
    .{ .name = "grass-3", .color = .{ 65, 52, 28 } },
    .{ .name = "grass-4", .color = .{ 59, 40, 18 } },
    .{ .name = "red-desert-0", .color = .{ 103, 70, 32 } },
    .{ .name = "red-desert-1", .color = .{ 116, 81, 39 } },
    .{ .name = "red-desert-2", .color = .{ 116, 84, 43 } },
    .{ .name = "red-desert-3", .color = .{ 128, 93, 52 } },
};

const NB_Band = struct { lo: f64, hi: f64 };
const NauvisRule = struct {
    idx: u8,
    /// primary aux×moisture band (range args of expression_in_range_base)
    aux: NB_Band,
    moist: NB_Band,
    /// optional second band under max(...) (dirt-1/4, sand-2/3)
    aux2: ?NB_Band = null,
    moist2: ?NB_Band = null,
    /// noise_layer_noise seed1 (per-tile layer speckle)
    noise_seed: u32 = 0,
    /// sand-1's shoreline term: expression_in_range(5, inf, elevation, aux,
    /// -1.5, 0.5, 1.5, 1) — an elevation×aux band centred on sea level.
    shore: bool = false,
};

/// Land-tile rules, verbatim from base tiles.lua autoplace expressions.
const nauvis_rules = [_]NauvisRule{
    .{ .idx = NB_SAND1, .aux = .{ .lo = -10, .hi = 0.25 }, .moist = .{ .lo = -10, .hi = 0.15 }, .noise_seed = 36, .shore = true },
    .{ .idx = NB_SAND2, .aux = .{ .lo = -10, .hi = 0.3 }, .moist = .{ .lo = 0.15, .hi = 0.2 }, .aux2 = .{ .lo = 0.25, .hi = 0.3 }, .moist2 = .{ .lo = -10, .hi = 0.15 }, .noise_seed = 37 },
    .{ .idx = NB_SAND3, .aux = .{ .lo = -10, .hi = 0.4 }, .moist = .{ .lo = 0.2, .hi = 0.25 }, .aux2 = .{ .lo = 0.3, .hi = 0.4 }, .moist2 = .{ .lo = -10, .hi = 0.2 }, .noise_seed = 38 },
    .{ .idx = NB_DRY_DIRT, .aux = .{ .lo = 0.45, .hi = 0.55 }, .moist = .{ .lo = -10, .hi = 0.35 }, .noise_seed = 13 },
    .{ .idx = NB_DIRT1, .aux = .{ .lo = -10, .hi = 0.45 }, .moist = .{ .lo = 0.25, .hi = 0.3 }, .aux2 = .{ .lo = 0.4, .hi = 0.45 }, .moist2 = .{ .lo = -10, .hi = 0.25 }, .noise_seed = 6 },
    .{ .idx = NB_DIRT2, .aux = .{ .lo = -10, .hi = 0.45 }, .moist = .{ .lo = 0.3, .hi = 0.35 }, .noise_seed = 7 },
    .{ .idx = NB_DIRT3, .aux = .{ .lo = -10, .hi = 0.55 }, .moist = .{ .lo = 0.35, .hi = 0.4 }, .noise_seed = 8 },
    .{ .idx = NB_DIRT4, .aux = .{ .lo = 0.55, .hi = 0.6 }, .moist = .{ .lo = -10, .hi = 0.35 }, .aux2 = .{ .lo = 0.6, .hi = 11 }, .moist2 = .{ .lo = 0.3, .hi = 0.35 }, .noise_seed = 9 },
    .{ .idx = NB_DIRT5, .aux = .{ .lo = -10, .hi = 0.55 }, .moist = .{ .lo = 0.4, .hi = 0.45 }, .noise_seed = 10 },
    .{ .idx = NB_DIRT6, .aux = .{ .lo = -10, .hi = 0.55 }, .moist = .{ .lo = 0.45, .hi = 0.5 }, .noise_seed = 11 },
    .{ .idx = NB_DIRT7, .aux = .{ .lo = -10, .hi = 0.55 }, .moist = .{ .lo = 0.5, .hi = 0.55 }, .noise_seed = 12 },
    .{ .idx = NB_GRASS1, .aux = .{ .lo = -10, .hi = 11 }, .moist = .{ .lo = 0.7, .hi = 11 }, .noise_seed = 19 },
    .{ .idx = NB_GRASS2, .aux = .{ .lo = 0.45, .hi = 11 }, .moist = .{ .lo = 0.45, .hi = 0.8 }, .noise_seed = 20 },
    .{ .idx = NB_GRASS3, .aux = .{ .lo = -10, .hi = 0.65 }, .moist = .{ .lo = 0.6, .hi = 0.9 }, .noise_seed = 21 },
    .{ .idx = NB_GRASS4, .aux = .{ .lo = -10, .hi = 0.55 }, .moist = .{ .lo = 0.5, .hi = 0.7 }, .noise_seed = 22 },
    .{ .idx = NB_REDDESERT0, .aux = .{ .lo = 0.55, .hi = 11 }, .moist = .{ .lo = 0.35, .hi = 0.5 }, .noise_seed = 30 },
    .{ .idx = NB_REDDESERT1, .aux = .{ .lo = 0.6, .hi = 0.7 }, .moist = .{ .lo = -10, .hi = 0.3 }, .aux2 = .{ .lo = 0.7, .hi = 11 }, .moist2 = .{ .lo = 0.25, .hi = 0.3 }, .noise_seed = 31 },
    .{ .idx = NB_REDDESERT2, .aux = .{ .lo = 0.7, .hi = 0.8 }, .moist = .{ .lo = -10, .hi = 0.25 }, .aux2 = .{ .lo = 0.8, .hi = 11 }, .moist2 = .{ .lo = 0.2, .hi = 0.25 }, .noise_seed = 32 },
    .{ .idx = NB_REDDESERT3, .aux = .{ .lo = 0.8, .hi = 11 }, .moist = .{ .lo = -10, .hi = 0.2 }, .noise_seed = 33 },
};

/// Base-Nauvis tile competition. One basis-noise gen per land rule (the
/// per-layer noise_layer_noise), precomputed from the map seed.
pub const BaseNauvis = struct {
    gens: [nauvis_rules.len]noise.BasisNoiseGen,

    pub fn init(map_seed: u32) BaseNauvis {
        var c: BaseNauvis = undefined;
        for (nauvis_rules, 0..) |r, i| c.gens[i] = noise.BasisNoiseGen.init(map_seed, r.noise_seed);
        return c;
    }

    /// ExpressionInRange (engine op, RE'd 2.0.77): per-dim linear tent
    ///   peak(v, lo, hi) = (hi-lo)/2 - |v - (lo+hi)/2|   scaled by A, capped at
    ///   B when finite, then min across dims (no lower clamp). The base tile
    ///   autoplace bands are expression_in_range(20, 1, aux, moisture,
    ///   aux_lo, m_lo, aux_hi, m_hi). Verified bit-exact vs live-game probes
    ///   (mse 0 on 4 banded datasets). All f32: the engine evaluates the tile
    //    competition in f32 noise registers (tile_gen.c reads float*), so the
    //    peaks/water/noise compare in f32 like the game.
    fn peak(v: f32, lo: f64, hi: f64, mult: f32, cap: f32) f32 {
        const half: f32 = @floatCast((hi - lo) / 2.0);
        const center: f32 = @floatCast((lo + hi) / 2.0);
        var p: f32 = (half - @abs(v - center)) * mult;
        if (cap != std.math.inf(f32) and p > cap) p = cap;
        return p;
    }
    fn eirDim(aux: f32, m: f32, lo_aux: f64, hi_aux: f64, lo_m: f64, hi_m: f64) f32 {
        // expression_in_range(20, 1, aux, moisture, lo_aux, lo_m, hi_aux, hi_m)
        return @min(peak(aux, lo_aux, hi_aux, 20.0, 1.0), peak(m, lo_m, hi_m, 20.0, 1.0));
    }
    fn bandEir(aux: f32, m: f32, r: *const NauvisRule) f32 {
        var p = eirDim(aux, m, r.aux.lo, r.aux.hi, r.moist.lo, r.moist.hi);
        if (r.aux2 != null) {
            const alt = eirDim(aux, m, r.aux2.?.lo, r.aux2.?.hi, r.moist2.?.lo, r.moist2.?.hi);
            p = @max(p, alt);
        }
        return p;
    }

    /// Winning tile index into nauvis_base_palette at (x, y) given elevation,
    /// moisture, aux. Water/deepwater (water_base) compete in the same argmax
    /// as every land tile — the effective shoreline falls where water_base
    /// (~100·-e) stops beating the land plateau, i.e. e ≈ −0.01 (the game
    /// calibrates ≈ −0.012).
    pub fn classify(self: *const BaseNauvis, x: f64, y: f64, e: f64, m: f64, aux: f64) u8 {
        // engine evaluates properties + tile probs in f32 registers
        const ef: f32 = @floatCast(e);
        const mf: f32 = @floatCast(m);
        const af: f32 = @floatCast(aux);
        // water_base(0,100) / water_base(-2,200): influence·min(max_elev-e,1)
        const water_p: f32 = if (ef < 0.0) 100.0 * @min(-ef, 1.0) else -std.math.inf(f32);
        const deep_p: f32 = if (ef < -2.0) 200.0 * @min(-2.0 - ef, 1.0) else -std.math.inf(f32);
        var best = water_p;
        var best_idx: u8 = NB_WATER;
        if (deep_p > best) {
            best = deep_p;
            best_idx = NB_DEEPWATER;
        }
        for (&nauvis_rules, 0..) |*r, i| {
            var p = bandEir(af, mf, r);
            if (r.shore) {
                // sand-1 shoreline: expression_in_range(5, inf, elevation,
                // aux, -1.5, 0.5, 1.5, 1)
                const shore = @min(peak(ef, -1.5, 1.5, 5.0, std.math.inf(f32)),
                    peak(af, 0.5, 1.0, 5.0, std.math.inf(f32)));
                p = @max(p, shore);
            }
            // noise_layer_noise(seed) = multioctave, 4 octaves, 0.7 persist,
            // input_scale 1/6, output_scale 2/3 — makes patchy tile speckle.
            p += @as(f32, @floatCast(noise.multioctaveNoisePrebuilt(&self.gens[i], x, y, 4, 0.7, 1.0 / 6.0, 2.0 / 3.0)));
            if (p > best) {
                best = p;
                best_idx = r.idx;
            }
        }
        return best_idx;
    }
};

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
