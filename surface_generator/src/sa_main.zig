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
//!
//! Environment:
//!   SA_DATA=<file>   another data file (scripts/sa-build-data.py --out)
//!   SA_MGS=<file>    a surface's map_gen_settings from the game (see main)
//!   SA_COLUMN=1      probe: evaluate the grid as one column, as the game's
//!                    calculate_tile_properties does (random_penalty draws
//!                    from one stream per column)
//!   SA_TILE_OFFSET=1 multioctave offsets as map generation applies them
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


fn jnum(v: ?std.json.Value, default: f64) f64 {
    const x = v orelse return default;
    return switch (x) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => default,
    };
}

/// control:<name>:<field> from the dumped autoplace_controls.
fn mgsControl(ctx: *const anyopaque, name: []const u8, field: []const u8) f64 {
    const mgs: *const std.json.ObjectMap = @ptrCast(@alignCast(ctx));
    const default: f64 = if (std.mem.eql(u8, field, "bias")) 0 else 1;
    if (std.mem.eql(u8, name, "starting-area")) return jnum(mgs.get("starting_area"), 1);
    const ac = mgs.get("autoplace_controls") orelse return default;
    const c = ac.object.get(name) orelse return default;
    return jnum(c.object.get(field), default);
}

/// The planet with the dumped cliff settings, and only the entities the
/// surface lets spawn (its entity list, minus those of a size-0 control).
fn mgsPlanet(a: std.mem.Allocator, base: *const sa_data.Planet, mgs: *const std.json.ObjectMap) !*const sa_data.Planet {
    const p = try a.create(sa_data.Planet);
    p.* = base.*;
    if (mgs.get("cliff_settings")) |cv| {
        const c = cv.object;
        p.cliff_richness = jnum(c.get("richness"), p.cliff_richness);
        p.cliff_elevation_0 = jnum(c.get("cliff_elevation_0"), p.cliff_elevation_0);
        p.cliff_elevation_interval = jnum(c.get("cliff_elevation_interval"), p.cliff_elevation_interval);
        p.cliff_smoothing = jnum(c.get("cliff_smoothing"), p.cliff_smoothing);
        // the cliff control scales them (CliffPlacementSettings::
        // getModifiedElevationInterval / getModifiedRichness): the interval
        // is divided by its frequency, the richness multiplied by its size
        if (c.get("control")) |ctl| {
            if (ctl == .string) {
                p.cliff_richness *= mgsControl(mgs, ctl.string, "size");
                const f = mgsControl(mgs, ctl.string, "frequency");
                if (f != 0) p.cliff_elevation_interval /= f;
            }
        }
    }
    var allowed: ?std.json.ObjectMap = null;
    if (mgs.get("autoplace_settings")) |as| {
        if (as.object.get("entity")) |e| {
            if (e.object.get("settings")) |st| allowed = st.object;
        }
    }
    var kept: std.ArrayList(sa_data.Entity) = .empty;
    for (base.placed) |e| {
        if (allowed) |al| {
            if (al.get(e.name) == null) continue;
        }
        if (e.control.len > 0 and mgsControl(mgs, e.control, "size") == 0) continue;
        try kept.append(a, e);
    }
    p.placed = kept.items;
    return p;
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

    // SA_DATA=<file>: use another data file from scripts/sa-build-data.py
    // (e.g. built from a Space Exploration dump) instead of the embedded one
    const data = if (init.environ_map.get("SA_DATA")) |path|
        try sa_data.loadFrom(a, try std.Io.Dir.readFileAlloc(.cwd(), init.io, path, a, .unlimited))
    else
        try sa_data.load(a);
    var planet = data.planet(args[1]) orelse {
        std.debug.print("unknown planet '{s}'; known:", .{args[1]});
        for (data.planets) |p| std.debug.print(" {s}", .{p.name});
        std.debug.print("\n", .{});
        return;
    };
    // SA_MGS=<file>: a surface's map_gen_settings as the game reports them
    // (the "map_gen_settings" of calibration/sa-probe/probe_se_zone.py's
    // output, or the table itself): its autoplace controls, cliff settings,
    // starting area and entity list replace the planet's defaults. This is
    // how a Space Exploration zone is checked against the game with the
    // game's own settings.
    var controls: prog.Controls = .{};
    if (init.environ_map.get("SA_MGS")) |path| {
        const text = try std.Io.Dir.readFileAlloc(.cwd(), init.io, path, a, .unlimited);
        const parsed = try std.json.parseFromSliceLeaky(std.json.Value, a, text, .{});
        const mgs = try a.create(std.json.ObjectMap);
        mgs.* = if (parsed.object.get("map_gen_settings")) |m| m.object else parsed.object;
        // the engine gives every surface a starting lake, placed from the
        // surface's own seed
        const lake_seed = try std.fmt.parseInt(u32, if (args.len > 3) args[3] else "0", 10);
        controls = .{ .starting_lake = sg.terrain.startingLakeCenter(lake_seed), .ctx = mgs, .lookup = mgsControl };
        // SA_TILE_OFFSET=1: multioctave_noise offsets the way map generation
        // applies them (needed for alien-biomes tiles; see noise.exact)
        if (init.environ_map.get("SA_TILE_OFFSET") != null) sg.noise.exact.tile_space_offset = true;
        planet = try mgsPlanet(a, planet, mgs);
    }
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

    if (std.mem.eql(u8, cmd, "stats")) {
        // what the entity program costs per position: instructions by kind,
        // and the basis-noise evaluations behind the noise instructions
        var msg: []const u8 = "";
        const seed = if (args.len > 3) try std.fmt.parseInt(u32, args[3], 10) else 0;
        const w = surface.World.initWith(a, &data, planet, seed, controls, .{ .external_tiles = true, .entities = true }, &msg) catch |e| {
            std.debug.print("cannot compile: {s}: {s}\n", .{ @errorName(e), msg });
            return;
        };
        const p = w.program;
        var counts = std.mem.zeroes([64]u32);
        var octaves: u32 = 0;
        for (p.insts) |inst| {
            counts[@intFromEnum(inst.tag)] += 1;
            switch (inst.tag) {
                .basis => octaves += 1,
                .multioctave => octaves += p.payloads[inst.aux].multi.m.n,
                .quick_multioctave => octaves += p.payloads[inst.aux].quick.octaves,
                .var_persistence => octaves += 6,
                else => {},
            }
        }
        std.debug.print("{s}: {d} entities, {d} instructions, {d} basis evaluations per position\n", .{ planet.name, w.n_placed, p.insts.len, octaves });
        inline for (@typeInfo(prog.Tag).@"enum".fields) |f| {
            if (counts[f.value] > 0) std.debug.print("  {s:18} {d}\n", .{ f.name, counts[f.value] });
        }
        for (p.spots, 0..) |sp, i| std.debug.print("  spot {d}: sub-program {d} instructions\n", .{ i, sp.sub.insts.len });
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
        var w = surface.World.init(a, &data, planet, map_seed, controls, &msg) catch |e| {
            std.debug.print("cannot compile {s}: {s}: {s}\n", .{ planet.name, @errorName(e), msg });
            return;
        };
        const n: usize = @intCast(2 * radius);
        const terrain = try a.alloc(u8, n * n * 4);
        const overlay = try a.alloc(u8, n * n * 4);
        const totals = try a.alloc(surface.World.Totals, planet.resources.len);
        @memset(totals, .{});
        var timer = std.Io.Clock.Timestamp.now(init.io, .awake);
        _ = w.render(-radius, -radius, n, n, terrain, overlay, null, null, totals, null);
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
        var tiles_from: ?[]const u8 = null;
        var names: std.ArrayList([]const u8) = .empty;
        for (args[6..]) |n| {
            if (std.mem.eql(u8, n, "--tiles")) want_tiles = true else if (std.mem.eql(u8, n, "--entities")) want_entities = true else if (std.mem.startsWith(u8, n, "--tiles-from=")) tiles_from = n["--tiles-from=".len..] else try names.append(a, n);
        }
        // --tiles-from=<game.json>: place entities on the GAME's tiles (a
        // step-1 probe_surface.py --tiles dump) instead of the generated
        // ones, to separate placement differences from tile differences
        var game_tiles: ?[]u16 = null;
        var gt_grid: [4]i32 = undefined;
        if (tiles_from) |path| {
            const text = try std.Io.Dir.readFileAlloc(.cwd(), init.io, path, a, .unlimited);
            const parsed = try std.json.parseFromSliceLeaky(std.json.Value, a, text, .{});
            const gg = parsed.object.get("grid").?.array.items;
            for (0..4) |k| gt_grid[k] = @intCast(gg[k].integer);
            if (gg[4].integer != 1) return error.TilesFromNeedsStep1;
            const arr = parsed.object.get("tiles").?.array.items;
            const gt = try a.alloc(u16, arr.len);
            for (arr, 0..) |v, k| {
                gt[k] = std.math.maxInt(u16);
                for (planet.tiles, 0..) |t, ti| {
                    if (std.mem.eql(u8, t.name, v.string)) gt[k] = @intCast(ti);
                }
            }
            game_tiles = gt;
        }
        var out: std.ArrayList(u8) = .empty;
        try out.print(a, "{{\"planet\":\"{s}\",\"seed\":{d},\"grid\":[{d},{d},{d},{d},{d}],\"values\":{{", .{ planet.name, map_seed, g[0], g[1], g[2], g[3], g[4] });
        var errors: std.ArrayList(u8) = .empty;
        var first = true;
        for (names.items) |nm| {
            var c = try prog.Compiler.init(a, &data, planet, map_seed, controls);
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
            if (init.environ_map.get("SA_COLUMN") != null) {
                // the whole grid as ONE column, the way the game's
                // calculate_tile_properties evaluates its list of positions:
                // random_penalty then draws from a single stream
                var cxs: std.ArrayList(f32) = .empty;
                var cys: std.ArrayList(f32) = .empty;
                var yy = g[2];
                while (yy <= g[3]) : (yy += g[4]) {
                    var xx = g[0];
                    while (xx <= g[1]) : (xx += g[4]) {
                        try cxs.append(a, @as(f32, @floatFromInt(xx)) + surface.SAMPLE_OFFSET);
                        try cys.append(a, @as(f32, @floatFromInt(yy)) + surface.SAMPLE_OFFSET);
                    }
                }
                var cws = try p.workspaceN(a, cxs.items.len);
                cws.column_rng = true;
                p.eval(&cws, cxs.items, cys.items);
                for (p.out(&cws, 0)[0..cxs.items.len], 0..) |v, i| {
                    if (i > 0) try out.append(a, ',');
                    if (std.math.isFinite(v)) try out.print(a, "{e}", .{v}) else try out.appendSlice(a, if (v > 0) "1e999" else if (v < 0) "-1e999" else "null");
                }
                try out.append(a, ']');
                continue;
            }
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
            if (surface.Surface.init(a, &data, planet, map_seed, controls, &msg)) |s0| {
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
            if (surface.World.initWith(a, &data, planet, map_seed, controls, .{ .entities = true }, &msg)) |w0| {
                var w = w0;
                try out.appendSlice(a, ",\"entities\":[");
                var chunk: surface.ChunkData = undefined;
                var k: usize = 0;
                var cy = @divFloor(g[2], surface.CHUNK);
                while (cy * surface.CHUNK <= g[3]) : (cy += 1) {
                    var cx = @divFloor(g[0], surface.CHUNK);
                    while (cx * surface.CHUNK <= g[1]) : (cx += 1) {
                        w.chunk(cx, cy, &chunk);
                        if (game_tiles) |gt| {
                            var tiles = chunk.tile;
                            const gw: i32 = gt_grid[1] - gt_grid[0] + 1;
                            for (0..surface.CHUNK * surface.CHUNK) |i| {
                                const tx = cx * surface.CHUNK + @as(i32, @intCast(i % surface.CHUNK));
                                const ty = cy * surface.CHUNK + @as(i32, @intCast(i / surface.CHUNK));
                                if (tx < gt_grid[0] or tx > gt_grid[1] or ty < gt_grid[2] or ty > gt_grid[3]) continue;
                                const v = gt[@intCast((ty - gt_grid[2]) * gw + (tx - gt_grid[0]))];
                                if (v != std.math.maxInt(u16)) tiles[i] = v;
                            }
                            w.chunkWith(cx, cy, &tiles, &chunk);
                        }
                        if (planet.cliff) |cl| {
                            for (chunk.cliffs[0..chunk.n_cliffs]) |pc| {
                                const fx = @as(f64, @floatFromInt(pc.x)) / 256.0;
                                const fy = @as(f64, @floatFromInt(pc.y)) / 256.0;
                                if (fx < @as(f64, @floatFromInt(g[0])) or fx >= @as(f64, @floatFromInt(g[1] + 1)) or fy < @as(f64, @floatFromInt(g[2])) or fy >= @as(f64, @floatFromInt(g[3] + 1))) continue;
                                if (k > 0) try out.append(a, ',');
                                k += 1;
                                try out.print(a, "{{\"n\":\"{s}@{s}\",\"x\":{d:.2},\"y\":{d:.2},\"a\":0}}", .{ cl.name, cl.orientations[pc.orient], fx, fy });
                            }
                        }
                        for (chunk.ents[0..chunk.n_ents]) |pe| {
                            const fx = @as(f64, @floatFromInt(pe.x)) / 256.0;
                            const fy = @as(f64, @floatFromInt(pe.y)) / 256.0;
                            if (fx < @as(f64, @floatFromInt(g[0])) or fx >= @as(f64, @floatFromInt(g[1] + 1)) or fy < @as(f64, @floatFromInt(g[2])) or fy >= @as(f64, @floatFromInt(g[3] + 1))) continue;
                            if (k > 0) try out.append(a, ',');
                            k += 1;
                            try out.print(a, "{{\"n\":\"{s}\",\"x\":{d:.2},\"y\":{d:.2},\"a\":0}}", .{ planet.placed[pe.ent].name, fx, fy });
                        }
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
