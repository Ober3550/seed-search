//! WebAssembly entry for the Space Age planet surface generator: renders a
//! planet's terrain property (elevation by default) over a square disk around
//! the spawn, entirely in the browser. Same exported-buffer protocol as
//! se_wasm.zig (inputPtr/growInput/resultPtr/pixelsPtr/generate), so it plugs
//! into the same gen-worker plumbing.
//!
//! Build (install.mjs):
//!   zig build-exe -target wasm32-freestanding -O ReleaseFast -fno-entry
//!     -rdynamic -femit-bin=public/sa.wasm -Mroot=src/sa_wasm.zig
//!
//! Request JSON:
//!   { "seed": <u32 map seed>, "planet": "vulcanus|fulgora|gleba|aquilo",
//!     "property": "elevation" (default) | moisture | aux | temperature,
//!     "radius": <tiles half-extent, default 128> }
//! Response: summary JSON via resultPtr/resultLen + RGBA8 pixels via
//! pixelsPtr/pixelsLen (width = height = 2*radius+1, tile per pixel,
//! top-left = (-radius, -radius)).

const std = @import("std");
const sa_data = @import("sa_data.zig");
const json = @import("sa_json.zig");
const sa_expr = @import("sa_expr.zig");
const noise = @import("noise.zig");

var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var g_result: []u8 = &.{};
var g_pixels: []u8 = &.{};
var input_buf: []u8 = &.{};

export fn inputPtr() [*]u8 {
    return input_buf.ptr;
}
export fn inputCap() usize {
    return input_buf.len;
}
export fn growInput(cap: usize) bool {
    const a = std.heap.page_allocator;
    const nb = a.realloc(input_buf, cap) catch return false;
    input_buf = nb;
    return true;
}
export fn resultPtr() [*]const u8 {
    return g_result.ptr;
}
export fn resultLen() usize {
    return g_result.len;
}
export fn pixelsPtr() [*]const u8 {
    return g_pixels.ptr;
}
export fn pixelsLen() usize {
    return g_pixels.len;
}

/// Per (seed0, seed1) basis-noise cache — building the perm tables dominates
/// cost, and every multioctave in a render reuses the same few seeds.
const GenCache = struct {
    keys: [32]u64 = undefined,
    gens: [32]noise.BasisNoiseGen = undefined,
    n: usize = 0,

    fn get(self: *GenCache, s0: u32, s1: u32) *const noise.BasisNoiseGen {
        const key = (@as(u64, s0) << 32) | s1;
        for (0..self.n) |i| {
            if (self.keys[i] == key) return &self.gens[i];
        }
        if (self.n < self.keys.len) {
            const i = self.n;
            self.n += 1;
            self.keys[i] = key;
            self.gens[i] = noise.BasisNoiseGen.init(s0, s1);
            return &self.gens[i];
        }
        // evict oldest (ring)
        const i = self.n % self.keys.len;
        self.n += 1;
        self.keys[i] = key;
        self.gens[i] = noise.BasisNoiseGen.init(s0, s1);
        return &self.gens[i];
    }
};

fn ctrlLookup(_: *const anyopaque, _: []const u8, _: []const u8) f64 {
    return 1.0; // default autoplace controls (frequency/size/richness = 1)
}
const defaultControls = sa_expr.Controls{ .lookup = ctrlLookup };

var g_gen_cache: sa_expr.GenCache = .{};

export fn generate(len: usize) void {
    _ = arena_state.reset(.retain_capacity);
    const a = arena_state.allocator();
    g_pixels = &.{};
    sa_expr.globalGenCache = &g_gen_cache;
    g_result = run(a, if (len <= input_buf.len) input_buf[0..len] else &.{}) catch |e| blk: {
        g_pixels = &.{};
        break :blk std.fmt.allocPrint(a, "{{\"ok\":false,\"error\":\"{s}\"}}", .{@errorName(e)}) catch &.{};
    };
}

fn run(a: std.mem.Allocator, req: []const u8) ![]u8 {
    const root = try json.parse(a, req);
    if (root != .object) return error.BadRequest;
    const o = root.object;
    const seed: u32 = blk: {
        const v = json.get(o, "seed") orelse return error.NoSeed;
        if (v != .number) return error.BadSeed;
        break :blk @intFromFloat(v.number);
    };
    const planetName: sa_data.PlanetName = blk: {
        const p = json.get(o, "planet") orelse return error.NoPlanet;
        if (p != .string) return error.BadPlanet;
        if (std.mem.eql(u8, p.string, "vulcanus")) break :blk .vulcanus;
        if (std.mem.eql(u8, p.string, "fulgora")) break :blk .fulgora;
        if (std.mem.eql(u8, p.string, "gleba")) break :blk .gleba;
        if (std.mem.eql(u8, p.string, "aquilo")) break :blk .aquilo;
        return error.UnsupportedPlanet;
    };
    const property: []const u8 = blk: {
        if (json.get(o, "property")) |v| {
            if (v == .string) break :blk v.string;
        }
        break :blk "elevation";
    };
    const radius: i32 = blk: {
        if (json.get(o, "radius")) |v| {
            if (v == .number) {
                const r: i32 = @intFromFloat(v.number);
                break :blk @max(@min(r, 1024), 8);
            }
        }
        break :blk 128;
    };

    const planet = try sa_data.load(a, planetName);
    const closure = &planet.closure;
    const entry = planet.prop(property) orelse return error.NoSuchProperty;
    var memo = try sa_expr.Memo.init(a, closure.node_count);

    // ---- evaluate + colour each tile ----
    const n = @as(usize, @intCast(2 * radius + 1));
    const pixels = try a.alloc(u8, n * n * 4);
    g_pixels = pixels;
    var idx: usize = 0;
    var yi: i32 = -radius;
    while (yi <= radius) : (yi += 1) {
        var xi: i32 = -radius;
        while (xi <= radius) : (xi += 1) {
            const x: f64 = @floatFromInt(xi);
            const y: f64 = @floatFromInt(yi);
            const s = sa_expr.Scalars{ .x = x, .y = y, .seed = seed, .x_from_start = x, .y_from_start = y };
            const v = try sa_expr.evalRootMemoed(closure, s, defaultControls, a, &memo, entry);
            const rgba = colour(v, planetName);
            pixels[idx] = rgba[0];
            pixels[idx + 1] = rgba[1];
            pixels[idx + 2] = rgba[2];
            pixels[idx + 3] = rgba[3];
            idx += 4;
        }
    }

    // summary JSON (braces written literally; fmt used per number only)
    var sb: std.ArrayList(u8) = .empty;
    try sb.appendSlice(a, "{\"ok\":true,\"planet\":\"");
    try sb.appendSlice(a, planetName.asStr());
    try sb.appendSlice(a, "\",\"property\":\"");
    try sb.appendSlice(a, entry);
    try sb.appendSlice(a, "\",\"seed\":");
    var numbuf: [32]u8 = undefined;
    try sb.appendSlice(a, try std.fmt.bufPrint(&numbuf, "{d}", .{seed}));
    try sb.appendSlice(a, ",\"radius\":");
    try sb.appendSlice(a, try std.fmt.bufPrint(&numbuf, "{d}", .{radius}));
    try sb.appendSlice(a, ",\"width\":");
    try sb.appendSlice(a, try std.fmt.bufPrint(&numbuf, "{d}", .{n}));
    try sb.appendSlice(a, ",\"height\":");
    try sb.appendSlice(a, try std.fmt.bufPrint(&numbuf, "{d}", .{n}));
    try sb.append(a, '}');
    g_result = sb.items;
    return g_result;
}

/// Terrain-preview colour ramp. Generic for now (refined once each planet's
/// elevation is bit-exact and the tile/layer extraction lands): elevation ≤ 0
/// is ocean (deeper = darker); above 0, low coastal = sand, mid = green,
/// high = rock; the exact thresholds are placeholders.
fn colour(e: f64, planet: sa_data.PlanetName) [4]u8 {
    _ = planet;
    const ef: f32 = @floatCast(e);
    if (ef <= 0.0) {
        // water: depth 0..-40 -> shoreline blue .. deep navy
        const d: f32 = @max(@min(-ef / 40.0, 1.0), 0.0);
        const r: f32 = 30 + 90 * d;
        const g: f32 = 60 + 100 * d;
        const b: f32 = 150 + 40 * (1 - d);
        return .{ @intFromFloat(r), @intFromFloat(g), @intFromFloat(b), 255 };
    }
    // land ramp 0..~150
    const t: f32 = @min(ef / 150.0, 1.0);
    // 0-0.25 sand → 0.25-0.7 green → 0.7+ rock
    const sand: [3]f32 = .{ 194, 178, 128 };
    const green: [3]f32 = .{ 96, 140, 70 };
    const rock: [3]f32 = .{ 120, 118, 112 };
    const stop = [_]struct { t: f32, c: [3]f32 }{
        .{ .t = 0.0, .c = sand },
        .{ .t = 0.22, .c = green },
        .{ .t = 0.7, .c = rock },
        .{ .t = 1.0, .c = rock },
    };
    var k: usize = 1;
    while (k < stop.len and t > stop[k].t) : (k += 1) {}
    const lo = stop[k - 1];
    const hi = stop[k];
    const u: f32 = if (hi.t == lo.t) 0 else @min((t - lo.t) / (hi.t - lo.t), 1);
    var out: [3]u8 = undefined;
    for (0..3) |c| {
        const vv: f32 = lo.c[c] + (hi.c[c] - lo.c[c]) * u;
        out[c] = @intFromFloat(@max(@min(vv, 255), 0));
    }
    return .{ out[0], out[1], out[2], 255 };
}

test "colour ramp is sane" {
    const c = colour(-20, .fulgora);
    try std.testing.expectEqual(@as(u8, 255), c[3]);
    const l = colour(60, .fulgora);
    try std.testing.expect(l[1] >= l[0] or l[2] >= l[0]); // greenish somewhere
}
