//! Minimal SHA-1 for region RNG seeding (16-byte input).
//! Factorio uses standard SHA-1 to hash (rx, ry) as int64_le.

const std = @import("std");

/// SHA-1 hash of exactly 16 bytes. Returns full 20-byte digest.
pub fn hash16(input: *const [16]u8, digest: *[20]u8) void {
    // Build one 64-byte block: input + 0x80 padding + length
    var block: [64]u8 = undefined;
    @memcpy(block[0..16], input);
    @memset(block[16..64], 0);
    block[16] = 0x80;
    // Length in bits: 16 * 8 = 128 = 0x80, big-endian at end
    block[62] = 0x00;
    block[63] = 0x80;

    // Initial hash values
    var h: [5]u32 = .{ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0 };

    // Message schedule
    var w: [80]u32 = undefined;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        w[i] = (@as(u32, block[i * 4]) << 24) |
            (@as(u32, block[i * 4 + 1]) << 16) |
            (@as(u32, block[i * 4 + 2]) << 8) |
            @as(u32, block[i * 4 + 3]);
    }
    while (i < 80) : (i += 1) {
        w[i] = std.math.rotl(u32, w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    }

    var a = h[0];
    var b = h[1];
    var c = h[2];
    var d = h[3];
    var e = h[4];

    i = 0;
    while (i < 80) : (i += 1) {
        if (i < 20) {
            const f0 = (b & c) | (~b & d);
            const k0: u32 = 0x5a827999;
            const temp = std.math.rotl(u32, a, 5) +% f0 +% e +% k0 +% w[i];
            e = d;
            d = c;
            c = std.math.rotl(u32, b, 30);
            b = a;
            a = temp;
        } else if (i < 40) {
            const f0 = b ^ c ^ d;
            const k0: u32 = 0x6ed9eba1;
            const temp = std.math.rotl(u32, a, 5) +% f0 +% e +% k0 +% w[i];
            e = d;
            d = c;
            c = std.math.rotl(u32, b, 30);
            b = a;
            a = temp;
        } else if (i < 60) {
            const f0 = (b & c) | (b & d) | (c & d);
            const k0: u32 = 0x8f1bbcdc;
            const temp = std.math.rotl(u32, a, 5) +% f0 +% e +% k0 +% w[i];
            e = d;
            d = c;
            c = std.math.rotl(u32, b, 30);
            b = a;
            a = temp;
        } else {
            const f0 = b ^ c ^ d;
            const k0: u32 = 0xca62c1d6;
            const temp = std.math.rotl(u32, a, 5) +% f0 +% e +% k0 +% w[i];
            e = d;
            d = c;
            c = std.math.rotl(u32, b, 30);
            b = a;
            a = temp;
        }
    }

    h[0] +%= a;
    h[1] +%= b;
    h[2] +%= c;
    h[3] +%= d;
    h[4] +%= e;

    // Output as big-endian bytes (matching standard SHA-1)
    for (0..5) |j| {
        const v = h[j];
        digest[j * 4] = @intCast((v >> 24) & 0xff);
        digest[j * 4 + 1] = @intCast((v >> 16) & 0xff);
        digest[j * 4 + 2] = @intCast((v >> 8) & 0xff);
        digest[j * 4 + 3] = @intCast(v & 0xff);
    }
}

test "sha1 matches Python for region coords" {
    // Test: rx=-1, ry=0 as int64_le
    var input: [16]u8 = undefined;
    std.mem.writeInt(i64, input[0..8], -1, .little);
    std.mem.writeInt(i64, input[8..16], 0, .little);
    var digest: [20]u8 = undefined;
    hash16(&input, &digest);
    // From Python: SHA1 of ffffffffffffffff0000000000000000 = f7fd9f0c0324c172...
    try std.testing.expectEqual(@as(u8, 0xf7), digest[0]);
    try std.testing.expectEqual(@as(u8, 0xfd), digest[1]);
    try std.testing.expectEqual(@as(u8, 0x9f), digest[2]);
    try std.testing.expectEqual(@as(u8, 0x0c), digest[3]);
}
