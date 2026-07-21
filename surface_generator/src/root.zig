//! Surface Generator — Factorio surface (chunk) generation in Zig.
//!
//! This module replicates Factorio's map generation algorithm:
//!   - RNG (Factorio's triple-LFSR)
//!   - Noise expressions (perlin, simplex, etc.)
//!   - Tile generation (water, grass, desert, etc.)
//!   - Resource autoplace (ore probability fields)
//!   - Cliff & enemy placement
//!
//! The primary entry point is `generateChunk()` which takes a seed,
//! map gen settings, and chunk coordinates, returning tile and entity data
//! that should be bit-identical to the real game.

pub const rng = @import("rng.zig");
pub const noise = @import("noise.zig");
pub const chunk = @import("chunk.zig");
pub const autoplace = @import("autoplace.zig");
pub const ore = @import("ore_placement.zig");
pub const bmp = @import("bmp_writer.zig");

test {
    _ = rng;
    _ = noise;
    _ = chunk;
    _ = autoplace;
    _ = ore;
    _ = bmp;
}
