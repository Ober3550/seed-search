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
pub const se_ore = @import("se_ore_placement.zig");
// SE surface generation calibration (resource configs, map colors, FSR
// overrides) — shared between the native segen CLI and the browser WASM
// surface generator (se_wasm.zig).
pub const se_resources = @import("se_resources.zig");
pub const terrain = @import("terrain.zig");
pub const biome = @import("biome.zig");
pub const asteroid = @import("asteroid.zig");
pub const bmp = @import("bmp_writer.zig");
pub const png = @import("png.zig");
pub const sha1 = @import("sha1.zig");
// Data-driven (2.0 noise-expression) planet surface generator.
pub const sa_json = @import("sa_json.zig");
pub const sa_expr = @import("sa_expr.zig");
pub const sa_data = @import("sa_data.zig");
pub const sa_program = @import("sa_program.zig");
pub const sa_surface = @import("sa_surface.zig");

test {
    _ = rng;
    _ = noise;
    _ = png;
    _ = chunk;
    _ = autoplace;
    _ = ore;
    _ = se_ore;
    _ = bmp;
}

test "data-driven planet generator vs live-game vectors" {
    _ = @import("sa_test.zig");
}
