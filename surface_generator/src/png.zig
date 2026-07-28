//! PNG encoding via zigimg — replaces the write-BMP-then-convert-externally
//! flow. Encoding only (RGB -> PNG bytes); callers write the bytes with their
//! own file API (segen uses std.Io.Dir, gpu_compute uses libc), since Zig 0.16
//! filesystem access differs by whether the binary links libc.

const std = @import("std");
const zigimg = @import("zigimg");

/// Encode a top-left-origin RGB buffer (3 bytes/px) to PNG bytes.
/// Caller owns and frees the returned slice.
pub fn encode(alloc: std.mem.Allocator, width: u32, height: u32, rgb: []const u8) ![]u8 {
    return encodeFmt(alloc, width, height, rgb, .rgb24, 3);
}

/// Encode a top-left-origin RGBA buffer (4 bytes/px) to PNG bytes, preserving
/// the alpha channel (e.g. a transparent-background ore overlay).
pub fn encodeRgba(alloc: std.mem.Allocator, width: u32, height: u32, rgba: []const u8) ![]u8 {
    return encodeFmt(alloc, width, height, rgba, .rgba32, 4);
}

test "encode rgb + rgba produce valid PNG (rgba keeps alpha)" {
    const alloc = std.testing.allocator;
    // 2x2 RGB
    const rgb = [_]u8{ 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255 };
    const p_rgb = try encode(alloc, 2, 2, &rgb);
    defer alloc.free(p_rgb);
    try std.testing.expect(std.mem.eql(u8, p_rgb[0..8], &.{ 137, 80, 78, 71, 13, 10, 26, 10 })); // PNG magic
    try std.testing.expectEqual(@as(u8, 2), p_rgb[25]); // IHDR colortype 2 = truecolour

    // 2x2 RGBA with a transparent pixel
    const rgba = [_]u8{ 255, 0, 0, 255, 0, 0, 0, 0, 0, 255, 0, 128, 0, 0, 255, 255 };
    const p_rgba = try encodeRgba(alloc, 2, 2, &rgba);
    defer alloc.free(p_rgba);
    try std.testing.expectEqual(@as(u8, 6), p_rgba[25]); // IHDR colortype 6 = truecolour+alpha
}

fn encodeFmt(alloc: std.mem.Allocator, width: u32, height: u32, px: []const u8, fmt: zigimg.PixelFormat, channels: usize) ![]u8 {
    std.debug.assert(px.len == @as(usize, width) * height * channels);
    var img = try zigimg.Image.fromRawPixels(alloc, width, height, px, fmt);
    defer img.deinit(alloc);

    // writeToMemory encodes into a caller-provided buffer and returns a slice of
    // it. PNG output never exceeds raw-RGBA + a small header/overhead.
    const scratch = try alloc.alloc(u8, @as(usize, width) * height * 4 + 4096);
    defer alloc.free(scratch);
    const encoded = try img.writeToMemory(alloc, scratch, .{ .png = .{} });
    return alloc.dupe(u8, encoded);
}
