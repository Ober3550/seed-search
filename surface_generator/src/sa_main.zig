//! sa_main.zig — native CLI for the data-driven planet surface generator.
//!
//!   sa_main <planet> info
//!       planet wiring (seed offset, property names, tiles, controls)
//!   sa_main <planet> probe <map-seed> <x0:x1:y0:y1:step> <out.json> [names...] [--tiles] [--entities]
//!       evaluate named expressions (and/or the winning tiles, and/or the
//!       resource entities placed in the grid's area) over a grid;
//!       same JSON layout as calibration/sa-probe/probe_surface.py so the two
//!       can be diffed (calibration/sa-probe/diff_surface.py)
//!   sa_main <planet> render <map-seed> <radius> <out.png>
//!       tile map, one tile per pixel, plus <out>-resources.png: the placed
//!       resources on a transparent background
//!   sa_main <planet> deps
//!       names of every expression the planet's tiles depend on
//!   sa_main <planet> check
//!       compile every expression the planet's tiles/properties need and
//!       report what is not supported
//!
//! `map-seed` is the MAP seed; the planet's surface-seed offset is applied
//! internally.
const std = @import("std");
const sg = @import("surface_generator");
const sa_data = sg.sa_data;
const prog = sg.sa_program;
const surface = sg.sa_surface;
const png = sg.png;

fn usage() void {
    std.debug.print(
        \\usage: sa_main <planet> info
        \\       sa_main <planet> probe <map-seed> <x0:x1:y0:y1:step> <out.json> [names...] [--tiles] [--entities]
        \\       sa_main <planet> render <map-seed> <radius> <out.png>
        \\       sa_main <planet> check
        \\
    , .{});
}

fn writeFile(init: std.process.Init, path: []const u8, bytes: []const u8) !void {
    const file = try std.Io.Dir.createFile(.cwd(), init.io, path, .{});
    defer file.close(init.io);
    try file.writePositionalAll(init.io, bytes, 0);
}

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len < 3) return usage();

    const data = try sa_data.load(a);
    const planet = data.planet(args[1]) orelse {
        std.debug.print("unknown planet '{s}'; known:", .{args[1]});
        for (data.planets) |p| std.debug.print(" {s}", .{p.name});
        std.debug.print("\n", .{});
        return;
    };
    const cmd = args[2];

    if (std.mem.eql(u8, cmd, "info")) {
        std.debug.print("{s} (game {s}): seed offset {d}\n", .{ planet.name, data.game_version, planet.seed_offset });
        for (planet.props) |p| switch (p.value) {
            .src => |s| std.debug.print("  {s} -> {s}\n", .{ p.key, s }),
            .num => |n| std.debug.print("  {s} -> {d}\n", .{ p.key, n }),
        };
        std.debug.print("controls:", .{});
        for (planet.controls) |c| std.debug.print(" {s}", .{c});
        std.debug.print("\ntiles:\n", .{});
        for (planet.tiles) |t| std.debug.print("  {d:3} {s}\n", .{ t.layer, t.name });
        return;
    }

    if (std.mem.eql(u8, cmd, "check")) {
        var bad: usize = 0;
        var names: std.ArrayList([]const u8) = .empty;
        for (planet.tiles) |t| try names.append(a, try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name}));
        for (planet.entities) |e| {
            try names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{e}));
            const rich = try std.fmt.allocPrint(a, "entity:{s}:richness", .{e});
            if (data.def(rich) != null) try names.append(a, rich);
        }
        for ([_][]const u8{ "elevation", "moisture", "aux", "temperature", "cliffiness", "cliff_elevation" }) |p| try names.append(a, p);
        for (names.items) |nm| {
            var c = try prog.Compiler.init(a, &data, planet, 0, .{});
            if (c.root(nm)) |_| {
                std.debug.print("  ok   {s} ({d} ops)\n", .{ nm, c.insts.items.len });
            } else |e| {
                bad += 1;
                std.debug.print("  FAIL {s}: {s}: {s}\n", .{ nm, @errorName(e), c.errorMessage() });
            }
        }
        std.debug.print("{s}: {d}/{d} roots compile\n", .{ planet.name, names.items.len - bad, names.items.len });
        return;
    }

    if (std.mem.eql(u8, cmd, "deps")) {
        // every named expression the planet's tiles reach (for oracle probes)
        var c = try prog.Compiler.init(a, &data, planet, 0, .{});
        for (planet.tiles) |t| _ = c.root(try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name})) catch {};
        var out: std.ArrayList(u8) = .empty;
        var it = c.globals.keyIterator();
        while (it.next()) |k| {
            const def: *const sa_data.Def = @ptrFromInt(k.def);
            if (k.ctx == 0 and std.mem.indexOfScalar(u8, def.name, ':') == null) try out.print(a, "{s}\n", .{def.name});
        }
        try std.Io.File.stdout().writeStreamingAll(init.io, out.items);
        return;
    }

    if (args.len < 6) return usage();
    const map_seed = try std.fmt.parseInt(u32, args[3], 10);

    if (std.mem.eql(u8, cmd, "render")) {
        const radius = try std.fmt.parseInt(i32, args[4], 10);
        var msg: []const u8 = "";
        var w = surface.World.init(a, &data, planet, map_seed, .{}, &msg) catch |e| {
            std.debug.print("cannot compile {s}: {s}: {s}\n", .{ planet.name, @errorName(e), msg });
            return;
        };
        const n: usize = @intCast(2 * radius);
        const terrain = try a.alloc(u8, n * n * 4);
        const overlay = try a.alloc(u8, n * n * 4);
        const totals = try a.alloc(surface.World.Totals, planet.resources.len);
        @memset(totals, .{});
        var timer = std.Io.Clock.Timestamp.now(init.io, .awake);
        w.render(-radius, -radius, n, n, terrain, overlay, null, totals);
        const ns = timer.untilNow(init.io).raw.toNanoseconds();
        try writeFile(init, args[5], try png.encodeRgba(a, @intCast(n), @intCast(n), terrain));
        const base = if (std.mem.endsWith(u8, args[5], ".png")) args[5][0 .. args[5].len - 4] else args[5];
        const res_path = try std.fmt.allocPrint(a, "{s}-resources.png", .{base});
        try writeFile(init, res_path, try png.encodeRgba(a, @intCast(n), @intCast(n), overlay));
        std.debug.print("{s}: {d}x{d} tiles, {d} ops, {d} ms ({d:.2} us/tile) -> {s}, {s}\n", .{
            planet.name,              n,                                                                    n,       w.program.insts.len,
            @divTrunc(ns, 1_000_000), @as(f64, @floatFromInt(ns)) / 1000.0 / @as(f64, @floatFromInt(n * n)), args[5], res_path,
        });
        for (planet.resources, totals) |r, t| std.debug.print("  {s}: {d} entities, amount {d}\n", .{ r.name, t.count, t.amount });
        return;
    }

    if (std.mem.eql(u8, cmd, "probe")) {
        var it = std.mem.splitScalar(u8, args[4], ':');
        var g: [5]i32 = undefined;
        for (&g) |*v| v.* = try std.fmt.parseInt(i32, it.next() orelse return usage(), 10);
        var want_tiles = false;
        var want_entities = false;
        var names: std.ArrayList([]const u8) = .empty;
        for (args[6..]) |n| {
            if (std.mem.eql(u8, n, "--tiles")) want_tiles = true else if (std.mem.eql(u8, n, "--entities")) want_entities = true else try names.append(a, n);
        }
        var out: std.ArrayList(u8) = .empty;
        try out.print(a, "{{\"planet\":\"{s}\",\"seed\":{d},\"grid\":[{d},{d},{d},{d},{d}],\"values\":{{", .{ planet.name, map_seed, g[0], g[1], g[2], g[3], g[4] });
        var errors: std.ArrayList(u8) = .empty;
        var first = true;
        for (names.items) |nm| {
            var c = try prog.Compiler.init(a, &data, planet, map_seed, .{});
            const r = c.root(nm) catch |e| {
                if (errors.items.len > 0) try errors.append(a, ',');
                try errors.print(a, "\"{s}\":\"{s}: {s}\"", .{ nm, @errorName(e), c.errorMessage() });
                continue;
            };
            const p = try c.finish(&.{r});
            var ws = try p.workspace(a);
            if (!first) try out.append(a, ',');
            first = false;
            try out.print(a, "\"{s}\":[", .{nm});
            var k: usize = 0;
            var y = g[2];
            while (y <= g[3]) : (y += g[4]) {
                var x = g[0];
                while (x <= g[1]) : (x += g[4]) {
                    const xs = [1]f32{@as(f32, @floatFromInt(x)) + surface.SAMPLE_OFFSET};
                    const ys = [1]f32{@as(f32, @floatFromInt(y)) + surface.SAMPLE_OFFSET};
                    p.eval(&ws, &xs, &ys);
                    if (k > 0) try out.append(a, ',');
                    k += 1;
                    const v = p.out(&ws, 0)[0];
                    if (std.math.isFinite(v)) try out.print(a, "{e}", .{v}) else try out.appendSlice(a, if (v > 0) "1e999" else if (v < 0) "-1e999" else "null");
                }
            }
            try out.append(a, ']');
        }
        try out.append(a, '}');
        if (want_tiles) {
            var msg: []const u8 = "";
            if (surface.Surface.init(a, &data, planet, map_seed, .{}, &msg)) |s0| {
                var s = s0;
                try out.appendSlice(a, ",\"tiles\":[");
                var k: usize = 0;
                var y = g[2];
                while (y <= g[3]) : (y += g[4]) {
                    var x = g[0];
                    while (x <= g[1]) : (x += g[4]) {
                        var t: [1]u16 = undefined;
                        s.tileRow(x, y, &t);
                        if (k > 0) try out.append(a, ',');
                        k += 1;
                        try out.print(a, "\"{s}\"", .{planet.tiles[t[0]].name});
                    }
                }
                try out.append(a, ']');
            } else |e| {
                if (errors.items.len > 0) try errors.append(a, ',');
                try errors.print(a, "\"tiles\":\"{s}: {s}\"", .{ @errorName(e), msg });
            }
        }
        if (want_entities) {
            // every resource entity whose centre tile lies in the grid's area
            var msg: []const u8 = "";
            if (surface.World.init(a, &data, planet, map_seed, .{}, &msg)) |w0| {
                var w = w0;
                try out.appendSlice(a, ",\"entities\":[");
                var chunk: surface.ChunkData = undefined;
                var k: usize = 0;
                var cy = @divFloor(g[2], surface.CHUNK);
                while (cy * surface.CHUNK <= g[3]) : (cy += 1) {
                    var cx = @divFloor(g[0], surface.CHUNK);
                    while (cx * surface.CHUNK <= g[1]) : (cx += 1) {
                        w.chunk(cx, cy, &chunk);
                        for (chunk.amount, 0..) |am, i| {
                            if (am == 0) continue;
                            const tx = cx * surface.CHUNK + @as(i32, @intCast(i % surface.CHUNK));
                            const ty = cy * surface.CHUNK + @as(i32, @intCast(i / surface.CHUNK));
                            if (tx < g[0] or tx > g[1] or ty < g[2] or ty > g[3]) continue;
                            if (k > 0) try out.append(a, ',');
                            k += 1;
                            // entity position = tile centre
                            try out.print(a, "{{\"n\":\"{s}\",\"x\":{d:.1},\"y\":{d:.1},\"a\":{d}}}", .{
                                planet.resources[chunk.resource[i]].name,
                                @as(f64, @floatFromInt(tx)) + 0.5,
                                @as(f64, @floatFromInt(ty)) + 0.5,
                                am,
                            });
                        }
                    }
                }
                try out.append(a, ']');
            } else |e| {
                if (errors.items.len > 0) try errors.append(a, ',');
                try errors.print(a, "\"entities\":\"{s}: {s}\"", .{ @errorName(e), msg });
            }
        }
        try out.print(a, ",\"errors\":{{{s}}}}}\n", .{errors.items});
        try writeFile(init, args[5], out.items);
        std.debug.print("wrote {s}\n", .{args[5]});
        return;
    }
    usage();
}
