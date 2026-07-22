const std = @import("std");
const surfacegen = @import("surface_generator");

const MapColors = struct {
    const iron_ore = [3]u8{ 106, 134, 148 };
    const copper_ore = [3]u8{ 205, 99, 55 };
    const coal = [3]u8{ 60, 60, 60 };
    const stone = [3]u8{ 176, 156, 109 };
    const uranium_ore = [3]u8{ 0, 179, 0 };
    fn get(name: []const u8) [3]u8 {
        if (std.mem.eql(u8, name, "iron-ore")) return iron_ore;
        if (std.mem.eql(u8, name, "copper-ore")) return copper_ore;
        if (std.mem.eql(u8, name, "coal")) return coal;
        if (std.mem.eql(u8, name, "stone")) return stone;
        if (std.mem.eql(u8, name, "uranium-ore")) return uranium_ore;
        return .{ 128, 128, 128 };
    }
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    if (args.len < 2) {
        std.debug.print("surfacegen <seed> [--radius R] [--bmp FILE] [--noise] [--jsonl FILE]\n", .{});
        return;
    }

    const seed = std.fmt.parseInt(u32, args[1], 10) catch { return; };
    var radius: f64 = 200;
    var bmp_filename: ?[]const u8 = null;
    var jsonl_filename: ?[]const u8 = null;
    var noise_mode: bool = false;
    var controls = surfacegen.ore.AutoplaceControls{};

    var i: usize = 2;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--radius")) {
            i += 1; if (i < args.len) radius = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--freq")) {
            i += 1; if (i < args.len) controls.frequency = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--size")) {
            i += 1; if (i < args.len) controls.size = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--rich")) {
            i += 1; if (i < args.len) controls.richness = try std.fmt.parseFloat(f64, args[i]);
        } else if (std.mem.eql(u8, args[i], "--bmp")) {
            i += 1; if (i < args.len) bmp_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--jsonl")) {
            i += 1; if (i < args.len) jsonl_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--noise")) {
            noise_mode = true;
        }
    }

    const r: i32 = @intFromFloat(radius);
    std.debug.print("# Seed {d}, radius {d}\n", .{ seed, r });

    if (noise_mode and bmp_filename != null) {
        // Raw noise field as greyscale BMP
        const size: u32 = @intCast(r * 2);
        const config = surfacegen.ore.iron_ore_default;

        var pixels = try a.alloc(u8, size * size * 3);
        var min_val: f64 = 1e100;
        var max_val: f64 = -1e100;

        // Pass 1: range
        var py: i32 = -r;
        while (py < r) : (py += 1) {
            var px: i32 = -r;
            while (px < r) : (px += 1) {
                const fx: f64 = @floatFromInt(px);
                const fy: f64 = @floatFromInt(py);
                const d = @sqrt(fx * fx + fy * fy);
                const v = try surfacegen.ore.computeRawNoise(a, seed, fx, fy, d, config, controls);
                if (v < min_val) min_val = v;
                if (v > max_val) max_val = v;
            }
        }

        const range = max_val - min_val;
        std.debug.print("# Noise range: {d:.0} to {d:.0}\n", .{ min_val, max_val });
        if (range <= 0) return;

        // Pass 2: fill
        py = -r;
        while (py < r) : (py += 1) {
            var px: i32 = -r;
            while (px < r) : (px += 1) {
                const fx: f64 = @floatFromInt(px);
                const fy: f64 = @floatFromInt(py);
                const d = @sqrt(fx * fx + fy * fy);
                const v = try surfacegen.ore.computeRawNoise(a, seed, fx, fy, d, config, controls);
                const b: u8 = @intFromFloat(@min(255, @max(0, (v - min_val) / range * 255)));
                const idx: usize = @intCast((@as(u32, @intCast(py + r)) * size + @as(u32, @intCast(px + r))) * 3);
                pixels[idx] = b;
                pixels[idx + 1] = b;
                pixels[idx + 2] = b;
            }
        }

        var bmp_buf: std.ArrayList(u8) = .empty;
        try surfacegen.bmp.writeBmp(a, &bmp_buf, size, size, pixels);
        const file = try std.Io.Dir.createFile(.cwd(), init.io, bmp_filename.?, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, bmp_buf.items, 0);
        std.debug.print("# Wrote noise BMP: {s}\n", .{bmp_filename.?});
        return;
    }

    // Normal ore entity generation
    var configs: std.ArrayList(surfacegen.ore.ResourceAutoplaceConfig) = .empty;
    var names: std.ArrayList([]const u8) = .empty;
    inline for (.{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore" }) |rname| {
        const cfg = if (std.mem.eql(u8, rname, "iron-ore")) surfacegen.ore.iron_ore_default
            else if (std.mem.eql(u8, rname, "copper-ore")) surfacegen.ore.copper_ore_default
            else if (std.mem.eql(u8, rname, "coal")) surfacegen.ore.coal_default
            else if (std.mem.eql(u8, rname, "stone")) surfacegen.ore.stone_default
            else surfacegen.ore.uranium_ore_default;
        try configs.append(a, cfg);
        try names.append(a, rname);
    }

    var ores = try surfacegen.ore.computeOresInRect(a, seed, -r, -r, r, r, configs.items, names.items, controls);
    defer ores.deinit(a);
    std.debug.print("# Found {} ore entities\n", .{ores.items.len});

    const resources_list = [_][]const u8{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore" };
    for (resources_list) |rname| {
        var count: u32 = 0;
        for (ores.items) |ore| { if (std.mem.eql(u8, ore.resource_name, rname)) count += 1; }
        if (count > 0) std.debug.print("#   {s}: {d}\n", .{ rname, count });
    }

    if (bmp_filename) |filename| {
        const size: u32 = @intCast(r * 2);
        var pixels = try a.alloc(u8, size * size * 3);
        @memset(pixels, 30);
        for (ores.items) |ore| {
            const px: i32 = ore.x + r;
            const py: i32 = ore.y + r;
            if (px >= 0 and px < r * 2 and py >= 0 and py < r * 2) {
                const color = MapColors.get(ore.resource_name);
                for (0..3) |dy| {
                    for (0..3) |dx| {
                        const sx: u32 = @as(u32, @intCast(px)) * 3 + @as(u32, @intCast(dx));
                        const sy: u32 = @as(u32, @intCast(py)) * 3 + @as(u32, @intCast(dy));
                        if (sx < size * 3 and sy < size) {
                            const idx: usize = @intCast((sy * size + sx) * 3);
                            @memcpy(pixels[idx..][0..3], &color);
                        }
                    }
                }
            }
        }
        var bmp_buf: std.ArrayList(u8) = .empty;
        try surfacegen.bmp.writeBmp(a, &bmp_buf, size * 3, size * 3, pixels);
        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, bmp_buf.items, 0);
    }

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
    }
}
