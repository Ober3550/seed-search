//! Alien-biomes tile classifier: given (temperature, moisture, aux, elevation),
//! pick the winning tile and return its map_color. Ports alien-biomes 0.7.4
//! volume_to_noise_expression + apply_beach_expression (see biomes.lua).
//!
//! First pass: plateau-peak fitness + beach penalty only. The per-tile
//! terrain-variation / water / crater noise layers (sub-variant fuzz) are not
//! yet applied — regions/color-families match; sub-variant patches are solid.

const std = @import("std");
const table = @import("biome_table.zig");

pub const Biome = table.Biome;
pub const biomes = table.biomes;

/// plateau_peak_to_noise_expression(var, center, range) = min((range-|var-center|)*20, 1)
fn plateauPeak(v: f64, lohi: [2]f64) f64 {
    const lo = lohi[0];
    const hi = lohi[1];
    const center = (lo + hi) / 2.0;
    const range = @abs(lo - hi) / 2.0;
    const peak = range - @abs(v - center); // range - ridge(var-center, 0, huge)
    return @min(peak * 20.0, 1.0);
}

/// Full fitness (probability_expression) for one biome, minus the deferred noise.
pub fn fitness(b: Biome, t: f64, m: f64, a: f64, e: f64) f64 {
    var f: f64 = std.math.inf(f64); // volume = min over present dims
    if (b.t) |r| f = @min(f, plateauPeak(t, r));
    if (b.m) |r| f = @min(f, plateauPeak(m, r));
    if (b.a) |r| f = @min(f, plateauPeak(a, r));
    if (b.e) |r| f = @min(f, plateauPeak(e, r));
    // apply_beach_expression: beach_weight<0 (default -1) => penalty near/below
    // water; beach_weight>=0 (sand/ice) => no penalty (reaches the shoreline).
    if (b.beach_weight < 0.0) f += @min(0.0, e / 5.0 - 1.0);
    return f;
}

/// Index of the winning biome at (t,m,a,e).
pub fn classifyIndex(t: f64, m: f64, a: f64, e: f64) usize {
    var best_i: usize = 0;
    var best_f: f64 = -std.math.inf(f64);
    for (biomes, 0..) |b, i| {
        const f = fitness(b, t, m, a, e);
        if (f > best_f) {
            best_f = f;
            best_i = i;
        }
    }
    return best_i;
}

pub fn classifyColor(t: f64, m: f64, a: f64, e: f64) [3]u8 {
    return biomes[classifyIndex(t, m, a, e)].color;
}

/// Water tile colors keyed by depth (Horaerratum legend values).
pub const deepwater: [3]u8 = .{ 38, 64, 73 };
pub const water: [3]u8 = .{ 51, 83, 95 };
