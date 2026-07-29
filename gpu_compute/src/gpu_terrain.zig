//! gpu_terrain — GPU surface renderer for the GUI (fast terrain preview).
//!
//! Thin entry point over the shared surface engine (surface_gpu.zig): renders a
//! zone's biome+water (planet/moon) or se-space/se-asteroid (asteroid field) to
//! terrain PNGs. Colours the shared classify mask when `--mask` is given, else
//! classifies inline. See surface_gpu.zig for the full CLI and tiling docs.
const std = @import("std");
const surface = @import("surface_gpu.zig");

pub fn main(init: std.process.Init) !void {
    return surface.run(init, false);
}
