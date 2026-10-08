//! WebAssembly entry for the data-driven planet surface generator: renders a
//! rectangle of a planet's tile map (or any named noise expression) entirely
//! in the browser. Same exported-buffer protocol as se_wasm.zig
//! (inputPtr/growInput/resultPtr/pixelsPtr/generate), so it plugs into the
//! same gen-worker plumbing.
//!
//! Build (install.mjs):
//!   zig build-exe -target wasm32-freestanding -O ReleaseFast -fno-entry
//!     -rdynamic -femit-bin=public/sa.wasm -Mroot=src/sa_wasm.zig
//!
//! Request JSON:
//!   { "seed": <u32 MAP seed>, "planet": "<any planet in the data file>",
//!     "x0": <left tile>, "y0": <top tile>, "width": w, "height": h,
//!     "property": "tiles" (default) | property key | expression name }
//!   (legacy square form: "cx", "cy", "radius" -> a (2r+1)^2 square)
//! Response: summary JSON via resultPtr/resultLen + RGBA8 pixels via
//! pixelsPtr/pixelsLen, one tile per pixel, row-major from (x0, y0).
//!   summary = { ok, planet, property, seed, surface_seed, x0, y0, width,
//!               height, tiles: [{ name, color: [r,g,b], count }] }
//!
//! The compiled program for a (planet, seed, property) is kept between
//! calls, so rendering a surface cell by cell compiles once.

const std = @import("std");
const sa_data = @import("sa_data.zig");
const json = @import("sa_json.zig");
const prog = @import("sa_program.zig");
const surface = @import("sa_surface.zig");

var data_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var program_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var call_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var g_data: ?sa_data.Data = null;
var g_result: []u8 = &.{};
var g_pixels: []u8 = &.{};
var input_buf: []u8 = &.{};

/// What the cached program was compiled for.
const Compiled = struct {
    planet: *const sa_data.Planet,
    seed: u32,
    property: []const u8, // owned by program_arena
    tiles: ?surface.Surface,
    single: ?struct { program: prog.Program, ws: prog.Program.Workspace },
};
var g_compiled: ?Compiled = null;
var g_error: []const u8 = "";

export fn inputPtr() [*]u8 {
    return input_buf.ptr;
}
export fn inputCap() usize {
    return input_buf.len;
}
export fn growInput(cap: usize) bool {
    const nb = std.heap.page_allocator.realloc(input_buf, cap) catch return false;
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

export fn generate(len: usize) void {
    _ = call_arena.reset(.retain_capacity);
    const a = call_arena.allocator();
    g_pixels = &.{};
    g_error = "";
    g_result = run(a, if (len <= input_buf.len) input_buf[0..len] else &.{}) catch |e| blk: {
        g_pixels = &.{};
        break :blk std.fmt.allocPrint(a, "{{\"ok\":false,\"error\":\"{s}{s}{s}\"}}", .{
            @errorName(e), if (g_error.len > 0) ": " else "", g_error,
        }) catch &.{};
    };
}

fn int(o: json.Object, key: []const u8) ?i32 {
    const v = json.get(o, key) orelse return null;
    return if (v == .number) @intFromFloat(v.number) else null;
}

fn compiled(planet: *const sa_data.Planet, seed: u32, property: []const u8) !*Compiled {
    if (g_compiled) |*c| {
        if (c.planet == planet and c.seed == seed and std.mem.eql(u8, c.property, property)) return c;
    }
    g_compiled = null;
    _ = program_arena.reset(.retain_capacity);
    const pa = program_arena.allocator();
    const data = &g_data.?;
    var c = Compiled{ .planet = planet, .seed = seed, .property = try pa.dupe(u8, property), .tiles = null, .single = null };
    if (std.mem.eql(u8, property, "tiles")) {
        c.tiles = try surface.Surface.init(pa, data, planet, seed, .{}, &g_error);
    } else {
        const p = try prog.compile(pa, data, planet, seed, .{}, &.{c.property}, &g_error);
        c.single = .{ .program = p, .ws = try p.workspace(pa) };
    }
    g_compiled = c;
    return &g_compiled.?;
}

fn run(a: std.mem.Allocator, req: []const u8) ![]u8 {
    if (g_data == null) g_data = try sa_data.load(data_arena.allocator());
    const data = &g_data.?;

    const root = try json.parse(a, req);
    if (root != .object) return error.BadRequest;
    const o = root.object;
    const seed: u32 = blk: {
        const v = json.get(o, "seed") orelse return error.NoSeed;
        if (v != .number) return error.BadSeed;
        break :blk @intFromFloat(v.number);
    };
    const planet = blk: {
        const p = json.get(o, "planet") orelse return error.NoPlanet;
        if (p != .string) return error.BadPlanet;
        break :blk data.planet(p.string) orelse return error.UnknownPlanet;
    };
    const property: []const u8 = blk: {
        if (json.get(o, "property")) |v| {
            if (v == .string) break :blk v.string;
        }
        break :blk "tiles";
    };
    var x0: i32 = 0;
    var y0: i32 = 0;
    var width: usize = 0;
    var height: usize = 0;
    if (int(o, "width")) |w| {
        x0 = int(o, "x0") orelse 0;
        y0 = int(o, "y0") orelse 0;
        width = @intCast(@max(w, 1));
        height = @intCast(@max(int(o, "height") orelse w, 1));
    } else {
        const r = @max(@min(int(o, "radius") orelse 128, 2048), 1);
        x0 = (int(o, "cx") orelse 0) - r;
        y0 = (int(o, "cy") orelse 0) - r;
        width = @intCast(2 * r + 1);
        height = width;
    }
    if (width * height > 4096 * 4096) return error.TooLarge;

    const c = try compiled(planet, seed, property);
    const pixels = try a.alloc(u8, width * height * 4);
    g_pixels = pixels;

    var sb: std.ArrayList(u8) = .empty;
    try sb.print(a, "{{\"ok\":true,\"planet\":\"{s}\",\"property\":\"{s}\",\"seed\":{d},\"surface_seed\":{d},\"x0\":{d},\"y0\":{d},\"width\":{d},\"height\":{d},\"tiles\":[", .{
        planet.name, property, seed, planet.surfaceSeed(seed), x0, y0, width, height,
    });
    if (c.tiles) |*s| {
        const counts = try a.alloc(u32, planet.tiles.len);
        @memset(counts, 0);
        const row = try a.alloc(u16, width);
        for (0..height) |r| {
            s.tileRow(x0, y0 + @as(i32, @intCast(r)), row);
            for (row, 0..) |t, col| {
                counts[t] += 1;
                const rgb = planet.tiles[t].color;
                pixels[(r * width + col) * 4 ..][0..4].* = .{ rgb[0], rgb[1], rgb[2], 255 };
            }
        }
        var first = true;
        for (planet.tiles, counts) |t, n| {
            if (n == 0) continue;
            if (!first) try sb.append(a, ',');
            first = false;
            try sb.print(a, "{{\"name\":\"{s}\",\"color\":[{d},{d},{d}],\"count\":{d}}}", .{ t.name, t.color[0], t.color[1], t.color[2], n });
        }
    } else if (c.single) |*s| {
        // any other expression: a height-map style ramp for inspection
        const B = prog.Program.BATCH;
        var xs: [B]f32 = undefined;
        var ys: [B]f32 = undefined;
        for (0..height) |r| {
            var done: usize = 0;
            while (done < width) {
                const n = @min(B, width - done);
                for (0..n) |j| {
                    xs[j] = @floatFromInt(x0 + @as(i32, @intCast(done + j)));
                    ys[j] = @floatFromInt(y0 + @as(i32, @intCast(r)));
                }
                s.program.eval(&s.ws, xs[0..n], ys[0..n]);
                const vals = s.program.out(&s.ws, 0);
                for (0..n) |j| pixels[(r * width + done + j) * 4 ..][0..4].* = ramp(vals[j]);
                done += n;
            }
        }
    }
    try sb.appendSlice(a, "]}");
    return sb.items;
}

/// Inspection colour ramp for raw expression values: below zero blue
/// (deeper = darker), above zero sand -> green -> rock.
fn ramp(v: f32) [4]u8 {
    if (!(v == v)) return .{ 255, 0, 255, 255 };
    if (v <= 0.0) {
        const d: f32 = @max(@min(-v / 40.0, 1.0), 0.0);
        return .{ @intFromFloat(30 + 90 * (1 - d)), @intFromFloat(60 + 100 * (1 - d)), @intFromFloat(110 + 80 * (1 - d)), 255 };
    }
    const t: f32 = @min(v / 150.0, 1.0);
    if (t < 0.15) return .{ 214, 200, 150, 255 };
    if (t < 0.6) {
        const u = (t - 0.15) / 0.45;
        return .{ @intFromFloat(96 + 40 * u), @intFromFloat(150 - 30 * u), @intFromFloat(70 + 10 * u), 255 };
    }
    const u = (t - 0.6) / 0.4;
    return .{ @intFromFloat(136 + 60 * u), @intFromFloat(120 + 60 * u), @intFromFloat(80 + 90 * u), 255 };
}
