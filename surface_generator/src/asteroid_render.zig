//! Render an asteroid-field surface to a PNG (CPU). Ground-truth check for the
//! asteroid.zig generator vs the tile-dump mod's tile-bmp.
//!
//! Usage: asteroid_render --map-seed N --radius R --out path.png
//! Renders a 2R x 2R image, top-down (row 0 = world y=-R, col 0 = world x=-R),
//! disk-cropped to radius R (grey 20 outside) to match /tile-bmp's disk bound.

const std = @import("std");
const sg = @import("surface_generator");

fn getStr(args: []const [:0]const u8, flag: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i + 1 < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], flag)) return args[i + 1];
    }
    return null;
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    const seed_s = getStr(args, "--map-seed") orelse return usage("missing --map-seed");
    const radius_s = getStr(args, "--radius") orelse "500";
    const out = getStr(args, "--out") orelse "asteroid.png";
    const map_seed = try std.fmt.parseInt(u32, seed_s, 10);

    // --probe "x,y;x,y;..." → print raw mo + margin at each point, then exit.
    if (getStr(args, "--probe")) |pts| {
        const field = sg.asteroid.AsteroidField.initField(map_seed);
        var it = std.mem.tokenizeScalar(u8, pts, ';');
        while (it.next()) |pair| {
            var xy = std.mem.tokenizeScalar(u8, pair, ',');
            const x = try std.fmt.parseFloat(f64, xy.next().?);
            const y = try std.fmt.parseFloat(f64, xy.next().?);
            std.debug.print("({d},{d}) mo={d:.6} |mo|={d:.6} margin={d:.6}\n", .{ x, y, field.moAt(x, y), @abs(field.moAt(x, y)), field.margin(x, y, 1.0) });
        }
        return;
    }
    const R: u32 = try std.fmt.parseInt(u32, radius_s, 10);
    const rf: f64 = @floatFromInt(R);

    const field = sg.asteroid.AsteroidField.initField(map_seed);
    const size = R * 2;
    const pixels = try a.alloc(u8, @as(usize, size) * size * 3);
    const bg = [3]u8{ 20, 20, 20 };
    const rr = rf * rf;
    var na: usize = 0;
    var ns: usize = 0;
    for (0..size) |py| {
        const y = @as(f64, @floatFromInt(py)) - rf; // world y, row 0 = -R
        for (0..size) |px| {
            const x = @as(f64, @floatFromInt(px)) - rf;
            const idx = (py * size + px) * 3;
            const col = if (x * x + y * y > rr) bg else blk: {
                const t = field.tileAt(x, y);
                if (t == .asteroid) na += 1 else if (t == .space) ns += 1;
                break :blk switch (t) {
                    .asteroid => sg.asteroid.ASTEROID_COLOR,
                    .space => sg.asteroid.SPACE_COLOR,
                    .out_of_map => sg.asteroid.OUT_OF_MAP_COLOR,
                };
            };
            pixels[idx] = col[0];
            pixels[idx + 1] = col[1];
            pixels[idx + 2] = col[2];
        }
    }

    const png = try sg.png.encode(a, size, size, pixels);
    const file = try std.Io.Dir.createFile(.cwd(), init.io, out, .{});
    defer file.close(init.io);
    try file.writePositionalAll(init.io, png, 0);
    std.debug.print("asteroid_render: {s} ({d}x{d}) — {d} asteroid, {d} space tiles ({d:.1}% asteroid)\n", .{
        out, size, size, na, ns, 100.0 * @as(f64, @floatFromInt(na)) / @as(f64, @floatFromInt(na + ns)),
    });
}

fn usage(msg: []const u8) error{Usage} {
    std.debug.print("asteroid_render error: {s}\n  usage: asteroid_render --map-seed N --radius R --out path.png\n", .{msg});
    return error.Usage;
}
