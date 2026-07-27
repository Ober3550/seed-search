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

fn plateauPeak(v: f64, lohi: [2]f64) f64 {
    const lo = lohi[0];
    const hi = lohi[1];
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

    pub fn classifyIndex(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) usize {
        // shared noise fields (same for every candidate tile at this position)
        const water_noise = noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 8.0, 0.666);
        const crater_noise = noise.multioctaveNoisePrebuilt(&self.crater_gen, x, y, 5, 0.75, 1.0 / 6.0 / 1.0, 0.666);
        const beach = @min(0.0, e / 5.0 - 1.0);

        var best_i: usize = 0;
        var best_f: f64 = -std.math.inf(f64);
        for (biomes, 0..) |b, i| {
            var f: f64 = std.math.inf(f64);
            if (b.t) |r| f = @min(f, plateauPeak(t, r));
            if (b.m) |r| f = @min(f, plateauPeak(m, r));
            if (b.a) |r| f = @min(f, plateauPeak(a, r));
            if (b.e) |r| f = @min(f, plateauPeak(e, r));
            if (b.beach_weight < 0.0) f += beach;
            if (b.water_coef != 0.0) f += b.water_coef * water_noise;
            if (b.crater) f += -0.6 - 0.7 * crater_noise;
            f += 0.5 * noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
            if (f > best_f) {
                best_f = f;
                best_i = i;
            }
        }
        return best_i;
    }

    pub fn classifyColor(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) [3]u8 {
        return biomes[self.classifyIndex(x, y, t, m, a, e)].color;
    }

    /// Debug: print the full fitness breakdown for the top-N tiles at (x,y), so a
    /// disagreement with the ground truth can be traced to a specific term.
    pub fn probe(self: *const Classifier, x: f64, y: f64, t: f64, m: f64, a: f64, e: f64) void {
        const water_noise = noise.multioctaveNoisePrebuilt(&self.water_gen, x, y, 5, 0.75, 1.0 / 6.0 / 8.0, 0.666);
        const crater_noise = noise.multioctaveNoisePrebuilt(&self.crater_gen, x, y, 5, 0.75, 1.0 / 6.0 / 1.0, 0.666);
        const beach = @min(0.0, e / 5.0 - 1.0);
        std.debug.print("  water_noise={d:.4} crater_noise={d:.4} beach={d:.4}\n", .{ water_noise, crater_noise, beach });

        var fits: [biomes.len]f64 = undefined;
        for (biomes, 0..) |b, i| {
            var f: f64 = std.math.inf(f64);
            if (b.t) |r| f = @min(f, plateauPeak(t, r));
            if (b.m) |r| f = @min(f, plateauPeak(m, r));
            if (b.a) |r| f = @min(f, plateauPeak(a, r));
            if (b.e) |r| f = @min(f, plateauPeak(e, r));
            if (b.beach_weight < 0.0) f += beach;
            if (b.water_coef != 0.0) f += b.water_coef * water_noise;
            if (b.crater) f += -0.6 - 0.7 * crater_noise;
            f += 0.5 * noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
            fits[i] = f;
        }
        var order: [biomes.len]usize = undefined;
        for (0..biomes.len) |i| order[i] = i;
        std.mem.sort(usize, &order, &fits, struct {
            fn lt(fs: *const [biomes.len]f64, ia: usize, ib: usize) bool {
                return fs[ia] > fs[ib]; // descending
            }
        }.lt);
        var rank: usize = 0;
        while (rank < 12 and rank < biomes.len) : (rank += 1) {
            const i = order[rank];
            const b = biomes[i];
            const tv = 0.5 * noise.multioctaveNoiseOffset(&self.tv_gens[i], x, y, 6, 0.75, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
            const tpk = if (b.t) |r| plateauPeak(t, r) else std.math.inf(f64);
            const mpk = if (b.m) |r| plateauPeak(m, r) else std.math.inf(f64);
            const apk = if (b.a) |r| plateauPeak(a, r) else std.math.inf(f64);
            const bch: f64 = if (b.beach_weight < 0.0) beach else 0.0;
            const wtr: f64 = if (b.water_coef != 0.0) b.water_coef * water_noise else 0.0;
            std.debug.print("  #{d:>2} f={d:.4}  {s:<26} rgb={d},{d},{d}  tpk={d:.3} mpk={d:.3} apk={d:.3} beach={d:.3} water={d:.3} tv={d:.4}\n", .{ rank, fits[i], b.name, b.color[0], b.color[1], b.color[2], tpk, mpk, apk, bch, wtr, tv });
        }
    }
};

/// Water tile colors keyed by depth (Horaerratum legend values).
pub const deepwater: [3]u8 = .{ 38, 64, 73 };
pub const water: [3]u8 = .{ 51, 83, 95 };

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
