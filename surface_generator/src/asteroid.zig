//! Asteroid-field surface generation (SE prototypes/phase-3/noise-programs.lua).
//!
//! Unlike planets/moons (alien-biomes biome classifier), an asteroid field is a
//! simple argmax between two tiles — se-space (background) and se-asteroid
//! (scattered patches) — plus out-of-map beyond the field disk. The per-tile
//! probabilities (the constant (1/freq-100)*1000 cancels between space/asteroid):
//!
//!   asteroid - space = -1 + max(-25, min(0, size-25)) + min(y/size, -y/size)
//!                      + |billows|
//!   billows = multioctave_noise{x=x/5, y=y/5, persistence=0.7, seed0=map_seed,
//!                               seed1=1, octaves=4, input_scale=1/6, output_scale=1}
//!
//! For an asteroid FIELD size=10000 (belt=200), freq=1/1000. So the size term is
//! 0 and the ridge (min(y/size,-y/size)) is a tiny -|y|/10000 → asteroid wins
//! where |billows| > 1 + |y|/10000 (sparse patches), else space.

const std = @import("std");
const noise = @import("noise.zig");

pub const SPACE_COLOR = [3]u8{ 11, 13, 15 }; // se-space map_color
pub const ASTEROID_COLOR = [3]u8{ 80, 80, 80 }; // se-asteroid map_color
pub const OUT_OF_MAP_COLOR = [3]u8{ 0, 0, 0 };

pub const Tile = enum { space, asteroid, out_of_map };

// Field constants (SE zone.lua: asteroid-field planet-size size=10000, freq=1/1000).
pub const FIELD_SIZE: f64 = 10000.0;
pub const FIELD_FREQ: f64 = 1.0 / 1000.0;

pub const AsteroidField = struct {
    gen: noise.BasisNoiseGen, // billows noise, seed1=1
    size: f64,
    freq: f64,
    /// planet_radius = 10000/6 * (6 + log2(1/freq/6)); out-of-map beyond this.
    planet_radius: f64,

    pub fn init(map_seed: u32, size: f64, freq: f64) AsteroidField {
        return .{
            .gen = noise.BasisNoiseGen.init(map_seed, 1),
            .size = size,
            .freq = freq,
            .planet_radius = 10000.0 / 6.0 * (6.0 + std.math.log2(1.0 / freq / 6.0)),
        };
    }

    /// Default asteroid-field parameters.
    pub fn initField(map_seed: u32) AsteroidField {
        return init(map_seed, FIELD_SIZE, FIELD_FREQ);
    }

    /// The raw asteroid billows multioctave (before abs).
    pub fn moAt(self: *const AsteroidField, x: f64, y: f64) f64 {
        return noise.multioctaveNoisePrebuilt(&self.gen, x / 5.0, y / 5.0, 4, 0.7, 1.0 / 6.0, 1.0);
    }

    /// asteroid - space margin (>0 → asteroid wins). billows_scale lets us test
    /// an amplitude correction against the game.
    pub fn margin(self: *const AsteroidField, x: f64, y: f64, billows_scale: f64) f64 {
        const billows = @abs(self.moAt(x, y)) * billows_scale;
        const size_term = @max(-25.0, @min(0.0, self.size - 25.0));
        const ridge = @min(y / self.size, -y / self.size);
        return -1.0 + size_term + ridge + billows;
    }

    pub fn tileAt(self: *const AsteroidField, x: f64, y: f64) Tile {
        // out-of-map wins beyond the field disk (distance from the spawn point,
        // taken as origin here). 10000*(dist - planet_radius) vs space's ~+900k.
        const dist = @sqrt(x * x + y * y);
        if (10000.0 * (dist - self.planet_radius) > (1.0 / self.freq - 100.0) * 1000.0) return .out_of_map;
        return if (self.margin(x, y, 1.0) > 0.0) .asteroid else .space;
    }

    pub fn colorAt(self: *const AsteroidField, x: f64, y: f64) [3]u8 {
        return switch (self.tileAt(x, y)) {
            .space => SPACE_COLOR,
            .asteroid => ASTEROID_COLOR,
            .out_of_map => OUT_OF_MAP_COLOR,
        };
    }
};
