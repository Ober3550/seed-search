//! sa_main.zig — native CLI for the Space Age planet surface generator (P0:
//! property-expression evaluation). Validates the expression engine against
//! live-game probes tile by tile before the WASM/GUI integration.
//!
//! Usage:
//!   sa_main <planet> <property|entry> <x0> <y0> <x1> <y1> [step] [seed] <out>
//!     planet   = vulcanus|fulgora|gleba|aquilo
//!     property = map-gen property key ("elevation", "moisture", "aux", …) or
//!                a closure entry name
//!     out      = file to write "x y value" lines (%.9g)
//!   sa_main <planet> --names
const std = @import("std");
const sa_data = @import("sa_data.zig");
const sa_expr = @import("sa_expr.zig");

fn ctrlLookup(_: *const anyopaque, _: []const u8, _: []const u8) f64 {
    return 1.0; // default autoplace controls (frequency/size/richness = 1)
}
const defaultControls = sa_expr.Controls{ .lookup = ctrlLookup };

pub fn main(init: std.process.Init) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();
    const args = try init.minimal.args.toSlice(a);

    if (args.len < 2) {
        std.debug.print("usage: sa_main <planet> <property|x0 y0 x1 y1> ... | --names <planet>\n", .{});
        return;
    }
    const planetName: sa_data.PlanetName = blk: {
        if (std.mem.eql(u8, args[1], "vulcanus")) break :blk .vulcanus;
        if (std.mem.eql(u8, args[1], "fulgora")) break :blk .fulgora;
        if (std.mem.eql(u8, args[1], "gleba")) break :blk .gleba;
        if (std.mem.eql(u8, args[1], "aquilo")) break :blk .aquilo;
        if (std.mem.eql(u8, args[1], "nauvis")) break :blk .nauvis;
        std.debug.print("unknown planet {s}\n", .{args[1]});
        return;
    };
    const planet = try sa_data.load(a, planetName);
    const closure = &planet.closure;

    if (args.len >= 3 and std.mem.eql(u8, args[2], "--names")) {
        std.debug.print("== {s}: {d} closure entries, property names:\n", .{ planetName.asStr(), closure.entries.len });
        for (planet.properties) |p| std.debug.print("   {s} → {s}\n", .{ p.key, p.entry });
        std.debug.print("controls: ", .{});
        for (planet.controls) |c| std.debug.print("{s} ", .{c});
        std.debug.print("\n", .{});
        return;
    }
    if (args.len < 9) {
        std.debug.print("usage: sa_main <planet> <property> <x0> <y0> <x1> <y1> <step> <seed> <out>\n", .{});
        return;
    }
    const property = args[2];
    const entryName = planet.prop(property) orelse blk: {
        if (closure.find(args[2]) != null) break :blk args[2];
        std.debug.print("no property/entry {s}\n", .{property});
        return;
    };
    const x0 = try std.fmt.parseFloat(f64, args[3]);
    const y0 = try std.fmt.parseFloat(f64, args[4]);
    const x1 = try std.fmt.parseFloat(f64, args[5]);
    const y1 = try std.fmt.parseFloat(f64, args[6]);
    const step: i64 = try std.fmt.parseInt(i64, args[7], 10);
    const seed: u32 = try std.fmt.parseInt(u32, args[8], 10);
    const outPath = args[9];

    var buf: std.ArrayList(u8) = .empty;
    var line: [64]u8 = undefined;
    var xi: i64 = @intFromFloat(x0);
    while (@as(f64, @floatFromInt(xi)) <= x1) : (xi += step) {
        var yi: i64 = @intFromFloat(y0);
        while (@as(f64, @floatFromInt(yi)) <= y1) : (yi += step) {
            const x: f64 = @floatFromInt(xi);
            const y: f64 = @floatFromInt(yi);
            const s = sa_expr.Scalars{ .x = x, .y = y, .seed = seed, .x_from_start = x, .y_from_start = y };
            const v = sa_expr.evalRoot(closure, s, defaultControls, a, entryName) catch |e| {
                std.debug.print("eval fail at ({d},{d}) {s}: {s}\n", .{ xi, yi, entryName, @errorName(e) });
                return;
            };
            const n = (try std.fmt.bufPrint(&line, "{d} {d} {d:.9}\n", .{ xi, yi, v })).len;
            try buf.appendSlice(a, line[0..n]);
        }
    }
    const file = try std.Io.Dir.createFile(.cwd(), init.io, outPath, .{});
    defer file.close(init.io);
    try file.writePositionalAll(init.io, buf.items, 0);
    std.debug.print("# wrote {s} ({d} bytes)\n", .{ outPath, buf.items.len });
}
