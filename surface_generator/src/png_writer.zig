//! Minimal PNG writer — writes uncompressed RGBA PNG to an ArrayList buffer.

const std = @import("std");

/// Write a PNG to buffer. Uses alloc for temporary CRC buffers.
pub fn writePng(
    alloc: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    width: u32,
    height: u32,
    pixels: []const u8, // RGBA, length = width * height * 4
) !void {
    const scanline: u32 = 1 + width * 4;
    const raw_len: u32 = scanline * height;
    const deflate_hdr = [_]u8{ 0x01, @truncate(raw_len), @truncate(raw_len >> 8), @truncate(~raw_len), @truncate(~raw_len >> 8) };
    const idat_data_len: u32 = @intCast(deflate_hdr.len + raw_len);

    const ihdr = [_]u8{
        @truncate(width >> 24), @truncate(width >> 16), @truncate(width >> 8), @truncate(width),
        @truncate(height >> 24), @truncate(height >> 16), @truncate(height >> 8), @truncate(height),
        8, 6, 0, 0, 0,
    };

    // Reserve space
    const total = 8 + 12 + ihdr.len + 4 + 12 + idat_data_len + 4 + 12;
    try buf.ensureTotalCapacity(alloc, buf.items.len + total);

    // Signature
    buf.appendSliceAssumeCapacity(&[_]u8{ 137, 80, 78, 71, 13, 10, 26, 10 });

    // Helper: write a chunk
    const ChunkWriter = struct {
        fn write(buf2: *std.ArrayList(u8), alloc2: std.mem.Allocator, ctype: []const u8, data: []const u8) !void {
            const len: u32 = @intCast(data.len);
            buf2.appendSliceAssumeCapacity(&[_]u8{ @truncate(len >> 24), @truncate(len >> 16), @truncate(len >> 8), @truncate(len) });
            buf2.appendSliceAssumeCapacity(ctype[0..4]);
            buf2.appendSliceAssumeCapacity(data);
            // CRC
            var crc_in = try std.ArrayList(u8).initCapacity(alloc2, 4 + data.len);
            crc_in.appendSliceAssumeCapacity(ctype[0..4]);
            crc_in.appendSliceAssumeCapacity(data);
            const crc = crc32(crc_in.items);
            buf2.appendSliceAssumeCapacity(&[_]u8{ @truncate(crc >> 24), @truncate(crc >> 16), @truncate(crc >> 8), @truncate(crc) });
        }
    };
    try ChunkWriter.write(buf, alloc, "IHDR", &ihdr);

    // IDAT
    {
        const len: u32 = idat_data_len;
        buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(len >> 24), @truncate(len >> 16), @truncate(len >> 8), @truncate(len) });
        buf.appendSliceAssumeCapacity("IDAT");
        buf.appendSliceAssumeCapacity(&deflate_hdr);

        var y: u32 = 0;
        while (y < height) : (y += 1) {
            buf.appendAssumeCapacity(0);
            const src: usize = @intCast(y * width * 4);
            buf.appendSliceAssumeCapacity(pixels[src .. src + width * 4]);
        }

        // CRC over "IDAT" + deflate + scanlines
        var crc_in = try std.ArrayList(u8).initCapacity(alloc, 4 + deflate_hdr.len + raw_len);
        crc_in.appendSliceAssumeCapacity("IDAT");
        crc_in.appendSliceAssumeCapacity(&deflate_hdr);
        y = 0;
        while (y < height) : (y += 1) {
            crc_in.appendAssumeCapacity(0);
            const src: usize = @intCast(y * width * 4);
            crc_in.appendSliceAssumeCapacity(pixels[src .. src + width * 4]);
        }
        const crc = crc32(crc_in.items);
        buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(crc >> 24), @truncate(crc >> 16), @truncate(crc >> 8), @truncate(crc) });
    }

    // IEND
    buf.appendSliceAssumeCapacity(&[_]u8{ 0, 0, 0, 0, 'I', 'E', 'N', 'D' });
    const iend_crc = crc32("IEND");
    buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(iend_crc >> 24), @truncate(iend_crc >> 16), @truncate(iend_crc >> 8), @truncate(iend_crc) });
}

fn crc32(data: []const u8) u32 {
    var crc: u32 = 0xffffffff;
    for (data) |b| {
        crc ^= b;
        var i: u32 = 0;
        while (i < 8) : (i += 1) {
            if ((crc & 1) != 0) {
                crc = (crc >> 1) ^ 0xedb88320;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc ^ 0xffffffff;
}
