//! Factorio's triple-LFSR random number generator.
//!
//! Factorio uses a 96-bit state split into three 32-bit LFSRs:
//!   s1 = ((s1 & 0xFFFFFFFE) << 12) ^ (((s1 << 13) ^ s1) >> 19)
//!   s2 = ((s2 & 0xFFFFFFF8) <<  4) ^ (((s2 <<  2) ^ s2) >> 25)
//!   s3 = ((s3 & 0xFFFFFFF0) << 17) ^ (((s3 <<  3) ^ s3) >> 11)
//!
//! Seeds below 341 are clamped to 341. The RNG is seeded with (seed, seed, seed).
//! Each call to next() increments an internal draw counter.

pub const Rng = struct {
    s1: u32,
    s2: u32,
    s3: u32,
    draw: u32 = 0,

    /// Initialize with a Factorio-compatible seed.
    pub fn init(seed: u32) Rng {
        const s = if (seed < 341) @as(u32, 341) else seed;
        return .{ .s1 = s, .s2 = s, .s3 = s };
    }

    /// Advance the RNG and return the next u32.
    pub fn next(self: *Rng) u32 {
        self.draw += 1;
        self.s1 = ((self.s1 & 0xFFFFFFFE) << 12) ^ (((self.s1 << 13) ^ self.s1) >> 19);
        self.s2 = ((self.s2 & 0xFFFFFFF8) << 4) ^ (((self.s2 << 2) ^ self.s2) >> 25);
        self.s3 = ((self.s3 & 0xFFFFFFF0) << 17) ^ (((self.s3 << 3) ^ self.s3) >> 11);
        return self.s1 ^ self.s2 ^ self.s3;
    }

    /// Return a uniform f64 in [0, 1).
    pub fn float(self: *Rng) f64 {
        return @as(f64, @floatFromInt(self.next())) * 2.3283064365386963e-10;
    }

    /// Return a random integer in [1, n] — or 0 on a degenerate draw.
    ///
    /// When the draw is small enough that `float * n < 1e-7`, the reference
    /// expression `floor(float * n - 0.0000001) + 1` evaluates to 0. Lua returns
    /// that happily, but converting the intermediate -1.0 to u32 is illegal in
    /// Zig and silently produced a garbage index under ReleaseFast. See the long
    /// explanation on `Rng.int1` in universe_generator/zig/gen.zig; callers must
    /// treat 0 as "no index".
    pub fn int1(self: *Rng, n: u32) u32 {
        const v = @floor(self.float() * @as(f64, @floatFromInt(n)) - 0.0000001);
        if (v < 0) return 0;
        return @as(u32, @intFromFloat(v)) + 1;
    }

    /// Return a random integer in [lo, hi] (inclusive). Same degenerate case as
    /// int1, where the reference yields `lo - 1`.
    pub fn intRange(self: *Rng, lo: u32, hi: u32) u32 {
        const v = @floor(self.float() * @as(f64, @floatFromInt(hi - lo + 1)) - 0.0000001);
        if (v < 0) return lo -| 1;
        return lo + @as(u32, @intFromFloat(v));
    }
};

test "Rng produces known values" {
    var r = Rng.init(341);
    // First raw value at seed 341, confirmed against the validated
    // universe_generator RNG (same triple-LFSR seeded (s,s,s)).
    try std.testing.expectEqual(@as(u32, 45438212), r.next());
}

test "Rng is deterministic" {
    var r1 = Rng.init(12345);
    var r2 = Rng.init(12345);
    for (0..100) |_| {
        try std.testing.expectEqual(r1.next(), r2.next());
    }
}

test "Rng clamps seeds below 341" {
    var r = Rng.init(100);
    var expected = Rng.init(341);
    try std.testing.expectEqual(expected.next(), r.next());
}

const std = @import("std");
