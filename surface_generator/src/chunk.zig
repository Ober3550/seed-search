//! Chunk generation — produces a 32×32 tile chunk.
//!
//! A Factorio surface is divided into 32×32 tile chunks. Generation produces:
//!   - Tile IDs (water, grass, sand, etc.)
//!   - Resource entities (iron-ore, copper-ore, etc.) with amounts
//!   - Cliffs
//!   - Enemy spawners
//!   - Trees and decoratives
//!
//! The chunk generator takes a seed, map gen settings, and chunk position
//! (in chunk coordinates, not tile coordinates) and returns a fully
//! populated chunk.

const std = @import("std");
const rng = @import("rng.zig");

/// Size of a chunk in tiles.
pub const CHUNK_SIZE: u32 = 32;

/// A single tile in a chunk.
pub const Tile = struct {
    /// Tile prototype name (e.g., "grass-1", "water", "sand-1").
    name: []const u8,
};

/// A resource entity on a tile.
pub const Resource = struct {
    /// Resource prototype name (e.g., "iron-ore", "copper-ore").
    name: []const u8,
    /// Amount (richness) of the resource.
    amount: u32,
};

/// A fully generated 32×32 chunk.
pub const Chunk = struct {
    /// Tile at [y * CHUNK_SIZE + x].
    tiles: [CHUNK_SIZE * CHUNK_SIZE]Tile,
    /// Resources placed on tiles (sparse; most tiles have none).
    resources: [CHUNK_SIZE * CHUNK_SIZE]?Resource,
    /// Chunk X coordinate (world tile x / 32).
    cx: i32,
    /// Chunk Y coordinate (world tile y / 32).
    cy: i32,
};

/// Generate a chunk at the given chunk coordinates.
pub fn generateChunk(alloc: std.mem.Allocator, seed: u32, cx: i32, cy: i32) !Chunk {
    _ = alloc;
    // TODO: Derive per-chunk RNG state from map seed + chunk position
    const chunk_rng = rng.Rng.init(seed);
    _ = chunk_rng;
    _ = cx;
    _ = cy;
    @panic("Chunk generation not yet implemented");
}

test "chunk size constant" {
    try std.testing.expectEqual(@as(u32, 32), CHUNK_SIZE);
}
