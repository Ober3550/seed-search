const std = @import("std");
const surfacegen = @import("surface_generator");

/// Map colors from Factorio's base/prototypes/entity/resources.lua
const MapColors = struct {
    // RGB (0-255)
    const iron_ore = [3]u8{ 106, 134, 148 }; // {0.415, 0.525, 0.580}
    const copper_ore = [3]u8{ 205, 99, 55 }; // {0.803, 0.388, 0.215}
    const coal = [3]u8{ 60, 60, 60 }; // {0, 0, 0} visual — use dark gray
    const stone = [3]u8{ 176, 156, 109 }; // {0.690, 0.611, 0.427}
    const uranium_ore = [3]u8{ 0, 179, 0 }; // {0, 0.7, 0}
    const crude_oil = [3]u8{ 199, 51, 196 }; // {0.78, 0.2, 0.77}

    fn get(name: []const u8) [3]u8 {
        if (std.mem.eql(u8, name, "iron-ore")) return iron_ore;
        if (std.mem.eql(u8, name, "copper-ore")) return copper_ore;
        if (std.mem.eql(u8, name, "coal")) return coal;
        if (std.mem.eql(u8, name, "stone")) return stone;
        if (std.mem.eql(u8, name, "uranium-ore")) return uranium_ore;
        if (std.mem.eql(u8, name, "crude-oil")) return crude_oil;
        return .{ 128, 128, 128 };
    }
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const args = try init.minimal.args.toSlice(a);
    if (args.len < 2) {
        std.debug.print(
            \\surfacegen — Factorio ore placement map generator
            \\
            \\Usage: surfacegen <seed> [resource] [--radius R] [--freq F] [--size S] [--rich R] [--bmp FILE]
            \\
            \\Resources: iron-ore, copper-ore, coal, stone, uranium-ore, crude-oil, all
            \\--bmp writes a BMP map using Factorio's exact map colors
            \\
        , .{});
        return;
    }

    const seed = std.fmt.parseInt(u32, args[1], 10) catch {
        std.debug.print("Invalid seed: {s}\n", .{args[1]});
        return;
    };

    var resource_name: []const u8 = "all";
    var radius: f64 = 200;
    var bmp_filename: ?[]const u8 = null;
    var jsonl_filename: ?[]const u8 = null;
    var probe_in: ?[]const u8 = null;
    var probe_out: ?[]const u8 = null;
    var lake_x: ?f64 = null;
    var lake_y: ?f64 = null;
    var controls = surfacegen.ore.AutoplaceControls{};

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--radius")) {
            i += 1;
            if (i < args.len) radius = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--freq")) {
            i += 1;
            if (i < args.len) controls.frequency = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--size")) {
            i += 1;
            if (i < args.len) controls.size = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--rich")) {
            i += 1;
            if (i < args.len) controls.richness = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--bmp")) {
            i += 1;
            if (i < args.len) bmp_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--jsonl")) {
            i += 1;
            if (i < args.len) jsonl_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--spot-rng")) {
            i += 1;
            if (i < args.len) surfacegen.noise.spot_size_rng_variant = try std.fmt.parseInt(u8, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "--lake")) {
            i += 1;
            lake_x = try std.fmt.parseFloat(f64, args[i]);
            i += 1;
            lake_y = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--probe")) {
            i += 1;
            probe_in = args[i];
            i += 1;
            probe_out = args[i];
        } else if (!std.mem.startsWith(u8, args[i], "--")) {
            resource_name = args[i];
        }
    }

    var configs: std.ArrayList(surfacegen.ore.ResourceAutoplaceConfig) = .empty;
    var names: std.ArrayList([]const u8) = .empty;

    inline for (.{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil" }) |rname| {
        if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, rname)) {
            const cfg = if (std.mem.eql(u8, rname, "iron-ore")) surfacegen.ore.iron_ore_default
                else if (std.mem.eql(u8, rname, "copper-ore")) surfacegen.ore.copper_ore_default
                else if (std.mem.eql(u8, rname, "coal")) surfacegen.ore.coal_default
                else if (std.mem.eql(u8, rname, "stone")) surfacegen.ore.stone_default
                else if (std.mem.eql(u8, rname, "uranium-ore")) surfacegen.ore.uranium_ore_default
                else surfacegen.ore.crude_oil_default;
            try configs.append(a, cfg);
            try names.append(a, rname);
        }
    }

    // --probe <in> <out>: evaluate raw all_patches at "x y" lines for a single
    // resource, one value per output line (oracle comparison, see
    // calibration/vanilla-sweep/probe_field.py).
    if (probe_in) |pin| {
        const raw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, pin, a, .unlimited);
        var xs: std.ArrayList(f64) = .empty;
        var ys: std.ArrayList(f64) = .empty;
        var it = std.mem.tokenizeAny(u8, raw, "\r\n");
        while (it.next()) |line| {
            var ft = std.mem.tokenizeAny(u8, line, " \t");
            const sx = ft.next() orelse continue;
            const sy = ft.next() orelse continue;
            try xs.append(a, try std.fmt.parseFloat(f64, sx));
            try ys.append(a, try std.fmt.parseFloat(f64, sy));
        }
        const vals = try a.alloc(f64, xs.items.len);
        if (std.mem.eql(u8, resource_name, "elevation-lakes")) {
            var el = surfacegen.terrain.ElevationLakes.init(seed, controls.frequency, controls.size);
            if (lake_x) |lx| el.addStartingLake(lx, lake_y.?);
            for (xs.items, ys.items, vals) |x, y, *v| v.* = el.at(x, y);
        } else if (std.mem.eql(u8, resource_name, "elevation")) {
            // Nauvis elevation (terrain.Elevation) instead of an ore field —
            // for oracle comparison against calculate_tile_properties('elevation').
            var el = surfacegen.terrain.Elevation.init(seed, controls.frequency, controls.size);
            if (lake_x) |lx| el.addStartingLake(lx, lake_y.?);
            for (xs.items, ys.items, vals) |x, y, *v| v.* = el.at(x, y);
        } else {
            var lakes_probe = surfacegen.terrain.ElevationLakes.init(seed, 1.0, 1.0);
            if (lake_x) |lx| lakes_probe.addStartingLake(lx, lake_y.?);
            try surfacegen.ore.probeAllPatches(a, seed, configs.items[0], controls, &lakes_probe, xs.items, ys.items, vals);
        }
        var buf: std.ArrayList(u8) = .empty;
        for (vals) |v| {
            var line: [64]u8 = undefined;
            const s = try std.fmt.bufPrint(&line, "{d:.9}\n", .{v});
            try buf.appendSlice(a, s);
        }
        const file = try std.Io.Dir.createFile(.cwd(), init.io, probe_out.?, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, buf.items, 0);
        std.debug.print("# Probed {d} positions -> {s}\n", .{ vals.len, probe_out.? });
        return;
    }

    const r: i32 = @intFromFloat(radius);
    std.debug.print("# Seed {d}, radius {d}, resources: {s}\n", .{ seed, r, resource_name });
    std.debug.print("# Controls: freq={d:.1} size={d:.1} rich={d:.1}\n", .{ controls.frequency, controls.size, controls.richness });

    // Terrain context: Nauvis elevation for the water gate + elevation_lakes for
    // starting patches. Water controls default (freq=1,size=1); --lake registers
    // the engine-chosen starting lake (exactness near origin needs it).
    var elev_gate = surfacegen.terrain.Elevation.init(seed, 1.0, 1.0);
    var lakes_gate = surfacegen.terrain.ElevationLakes.init(seed, 1.0, 1.0);
    if (lake_x) |lx| {
        elev_gate.addStartingLake(lx, lake_y.?);
        lakes_gate.addStartingLake(lx, lake_y.?);
    }
    const tctx = surfacegen.ore.TerrainCtx{ .elev = &elev_gate, .lakes = &lakes_gate };

    var ores = try surfacegen.ore.computeOresInRect(a, seed, -r, -r, r, r, configs.items, names.items, controls, tctx);
    defer ores.deinit(a);

    std.debug.print("# Found {} ore entities\n", .{ores.items.len});

    // PNG output
    if (bmp_filename) |filename| {
        const scale: u32 = 1; // 1:1 pixel mapping
        const size: u32 = @intCast(r * 2);
        const img_size: u32 = size * scale;

        // Build pixel grid at 1x first, then scale up
        var pixels = try a.alloc(u8, img_size * img_size * 3);
        @memset(pixels, 30); // dark gray background (not black, so coal is visible)

        for (ores.items) |ore| {
            const px: i32 = ore.x + r;
            const py: i32 = ore.y + r;
            if (px >= 0 and px < size and py >= 0 and py < size) {
                const color = MapColors.get(ore.resource_name);
                // Fill a scale×scale block
                var dy: u32 = 0;
                while (dy < scale) : (dy += 1) {
                    var dx: u32 = 0;
                    while (dx < scale) : (dx += 1) {
                        const sx: u32 = @as(u32, @intCast(px)) * scale + dx;
                        const sy: u32 = @as(u32, @intCast(py)) * scale + dy;
                        const idx: usize = @intCast((sy * img_size + sx) * 3);
                        @memcpy(pixels[idx..][0..3], &color);
                    }
                }
            }
        }

        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);

        // Write PNG directly to a buffer then write to file
        var bmp_buf: std.ArrayList(u8) = .empty;
        try surfacegen.bmp.writeBmp(a, &bmp_buf, img_size, img_size, pixels);
        try file.writePositionalAll(init.io, bmp_buf.items, 0);
        std.debug.print("# Wrote BMP: {s} ({d}x{d})\n", .{ filename, img_size, img_size });
    }

    // Count by resource
    const resources_list = [_][]const u8{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil" };
    for (resources_list) |rname| {
        var count: u32 = 0;
        for (ores.items) |ore| {
            if (std.mem.eql(u8, ore.resource_name, rname)) count += 1;
        }
        if (count > 0) std.debug.print("#   {s}: {d}\n", .{ rname, count });
    }

    // JSONL output
    if (jsonl_filename) |filename| {
        var buf: std.ArrayList(u8) = .empty;
        for (ores.items) |ore| {
            var line: [256]u8 = undefined;
            const s = try std.fmt.bufPrint(&line, "{{\"x\":{d},\"y\":{d},\"n\":\"{s}\",\"a\":{d}}}\n", .{ ore.x, ore.y, ore.resource_name, ore.amount });
            try buf.appendSlice(a, s);
        }
        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, buf.items, 0);
        std.debug.print("# Wrote JSONL: {s}\n", .{filename});
    }

    const sample_count = @min(ores.items.len, 20);
    std.debug.print("# Sample ({d}):\n", .{sample_count});
    for (ores.items[0..sample_count]) |ore| {
        std.debug.print("  {s} @ ({d}, {d}) amount={d}\n", .{ ore.resource_name, ore.x, ore.y, ore.amount });
    }
}
