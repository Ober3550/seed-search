//! Minimal BMP writer — uncompressed 24-bit RGB, bottom-up scanlines.
//! Much simpler than PNG; ideal for testing/visualization.

const std = @import("std");

/// Write a 24-bit BMP to buffer. Pixels are RGB row-major (top to bottom).
pub fn writeBmp(
    alloc: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    width: u32,
    height: u32,
    pixels: []const u8, // RGB, length = width * height * 3
) !void {
    // Row size is padded to 4 bytes
    const row_size: u32 = ((width * 3 + 3) / 4) * 4;
    const pixel_data_size: u32 = row_size * height;
    const file_size: u32 = 14 + 40 + pixel_data_size;

    try buf.ensureTotalCapacity(alloc, buf.items.len + file_size);

    // BMP file header (14 bytes)
    buf.appendSliceAssumeCapacity("BM"); // signature
    writeU32(buf, file_size);
    writeU16(buf, 0); // reserved1
    writeU16(buf, 0); // reserved2
    writeU32(buf, 14 + 40); // data offset

    // DIB header (BITMAPINFOHEADER, 40 bytes)
    writeU32(buf, 40); // header size
    writeI32(buf, @intCast(width));
    writeI32(buf, @as(i32, @intCast(height))); // positive = bottom-up
    writeU16(buf, 1); // planes
    writeU16(buf, 24); // bits per pixel
    writeU32(buf, 0); // compression (BI_RGB = none)
    writeU32(buf, pixel_data_size);
    writeI32(buf, 2835); // pixels per meter X (72 DPI)
    writeI32(buf, 2835); // pixels per meter Y
    writeU32(buf, 0); // colors used
    writeU32(buf, 0); // important colors

    // Pixel data (bottom-up, BGR)
    const pad: usize = @intCast(row_size - width * 3);
    var y: i32 = @as(i32, @intCast(height)) - 1;
    while (y >= 0) : (y -= 1) {
        const src: usize = @as(usize, @intCast(y)) * @as(usize, @intCast(width)) * 3;
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const off: usize = @intCast(x * 3);
            buf.appendAssumeCapacity(pixels[src + off + 2]); // B
            buf.appendAssumeCapacity(pixels[src + off + 1]); // G
            buf.appendAssumeCapacity(pixels[src + off]); // R
        }
        // Padding
        var p: usize = 0;
        while (p < pad) : (p += 1) {
            buf.appendAssumeCapacity(0);
        }
    }
}

fn writeU32(buf: *std.ArrayList(u8), v: u32) void {
    buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(v), @truncate(v >> 8), @truncate(v >> 16), @truncate(v >> 24) });
}

fn writeU16(buf: *std.ArrayList(u8), v: u16) void {
    buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(v), @truncate(v >> 8) });
}

fn writeI32(buf: *std.ArrayList(u8), v: i32) void {
    writeU32(buf, @bitCast(v));
}
