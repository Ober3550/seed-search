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

/// Water tile colors (Horaerratum legend values).
pub const deepwater: [3]u8 = .{ 38, 64, 73 };
pub const water: [3]u8 = .{ 51, 83, 95 };
pub const water_shallow: [3]u8 = .{ 53, 97, 110 };
pub const water_mud: [3]u8 = .{ 54, 88, 90 };

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
