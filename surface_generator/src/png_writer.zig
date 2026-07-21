//! Minimal PNG writer — writes uncompressed RGBA PNG to an ArrayList buffer.

const std = @import("std");

/// Write a PNG to buffer.
pub fn writePng(
    alloc: std.mem.Allocator,
    buf: *std.ArrayList(u8),
    width: u32,
    height: u32,
    pixels: []const u8, // RGBA, length = width * height * 4
) !void {
    const scanline: u32 = 1 + width * 4;
    const raw_len: u32 = scanline * height;

    // Build raw filtered scanlines in a temp buffer
    var raw = try std.ArrayList(u8).initCapacity(alloc, raw_len);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        raw.appendAssumeCapacity(0); // filter: None
        const src: usize = @intCast(y * width * 4);
        raw.appendSliceAssumeCapacity(pixels[src .. src + width * 4]);
    }

    // Build IDAT content: deflate blocks interleaved with data
    const max_block: u32 = 65535;
    var idat = try std.ArrayList(u8).initCapacity(alloc, raw_len + (raw_len / max_block + 1) * 5);
    var offset: u32 = 0;
    while (offset < raw_len) {
        const block_len: u16 = @intCast(@min(raw_len - offset, max_block));
        const is_final: u8 = if (offset + block_len >= raw_len) 0x01 else 0x00;
        idat.appendSliceAssumeCapacity(&[_]u8{ is_final, @truncate(block_len), @truncate(block_len >> 8), @truncate(~block_len), @truncate(~block_len >> 8) });
        idat.appendSliceAssumeCapacity(raw.items[offset..][0..block_len]);
        offset += block_len;
    }

    // Calculate total IDAT chunk size
    const idat_data_len: u32 = @intCast(idat.items.len);

    const ihdr = [_]u8{
        @truncate(width >> 24), @truncate(width >> 16), @truncate(width >> 8), @truncate(width),
        @truncate(height >> 24), @truncate(height >> 16), @truncate(height >> 8), @truncate(height),
        8, 6, 0, 0, 0,
    };

    // Reserve space
    const total = 8 + 12 + 13 + 4 + 12 + idat_data_len + 4 + 12;
    try buf.ensureTotalCapacity(alloc, buf.items.len + total);

    // Signature
    buf.appendSliceAssumeCapacity(&[_]u8{ 137, 80, 78, 71, 13, 10, 26, 10 });

    // IHDR
    {
        const len: u32 = 13;
        buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(len >> 24), @truncate(len >> 16), @truncate(len >> 8), @truncate(len) });
        buf.appendSliceAssumeCapacity("IHDR");
        buf.appendSliceAssumeCapacity(&ihdr);
        var c = try std.ArrayList(u8).initCapacity(alloc, 4 + 13);
        c.appendSliceAssumeCapacity("IHDR");
        c.appendSliceAssumeCapacity(&ihdr);
        const crc = crc32(c.items);
        buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(crc >> 24), @truncate(crc >> 16), @truncate(crc >> 8), @truncate(crc) });
    }

    // IDAT
    {
        buf.appendSliceAssumeCapacity(&[_]u8{ @truncate(idat_data_len >> 24), @truncate(idat_data_len >> 16), @truncate(idat_data_len >> 8), @truncate(idat_data_len) });
        buf.appendSliceAssumeCapacity("IDAT");
        buf.appendSliceAssumeCapacity(idat.items);
        var c = try std.ArrayList(u8).initCapacity(alloc, 4 + idat.items.len);
        c.appendSliceAssumeCapacity("IDAT");
        c.appendSliceAssumeCapacity(idat.items);
        const crc = crc32(c.items);
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
