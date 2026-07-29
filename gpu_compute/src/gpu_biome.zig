//! gpu_biome — shared biome/space/water classifier.
//!
//! Thin entry point over the shared surface engine (surface_gpu.zig) that always
//! runs in classify-only mode: it writes the per-cell mask biome_<grid>_<cell>.bin
//! (u32/tile — planet biome index, or asteroid-field mask 0=space/1=asteroid/
//! 2=out-of-map) and no image. The mask is consumed by both gpu_terrain (--mask)
//! and gpu_ore (--mask) so the classifier runs once per surface.
const std = @import("std");
const surface = @import("surface_gpu.zig");

pub fn main(init: std.process.Init) !void {
    return surface.run(init, true);
}
