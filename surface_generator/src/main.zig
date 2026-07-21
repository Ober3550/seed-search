const std = @import("std");
const surfacegen = @import("surface_generator");

/// Map colors from Factorio's base/prototypes/entity/resources.lua
const MapColors = struct {
    // RGBA (0-255)
    const iron_ore = [4]u8{ 106, 134, 148, 255 }; // {0.415, 0.525, 0.580}
    const copper_ore = [4]u8{ 205, 99, 55, 255 }; // {0.803, 0.388, 0.215}
    const coal = [4]u8{ 0, 0, 0, 255 }; // {0, 0, 0}
    const stone = [4]u8{ 176, 156, 109, 255 }; // {0.690, 0.611, 0.427}
    const uranium_ore = [4]u8{ 0, 179, 0, 255 }; // {0, 0.7, 0}
    const crude_oil = [4]u8{ 199, 51, 196, 255 }; // {0.78, 0.2, 0.77}

    fn get(name: []const u8) [4]u8 {
        if (std.mem.eql(u8, name, "iron-ore")) return iron_ore;
        if (std.mem.eql(u8, name, "copper-ore")) return copper_ore;
        if (std.mem.eql(u8, name, "coal")) return coal;
        if (std.mem.eql(u8, name, "stone")) return stone;
        if (std.mem.eql(u8, name, "uranium-ore")) return uranium_ore;
        if (std.mem.eql(u8, name, "crude-oil")) return crude_oil;
        return .{ 128, 128, 128, 255 };
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
            \\Usage: surfacegen <seed> [resource] [--radius R] [--freq F] [--size S] [--rich R] [--png FILE]
            \\
            \\Resources: iron-ore, copper-ore, coal, stone, uranium-ore, crude-oil, all
            \\--png writes a PNG map using Factorio's exact map colors
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
    var png_filename: ?[]const u8 = null;
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
        } else if (std.mem.eql(u8, args[i], "--png")) {
            i += 1;
            if (i < args.len) png_filename = args[i];
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

    const r: i32 = @intFromFloat(radius);
    std.debug.print("# Seed {d}, radius {d}, resources: {s}\n", .{ seed, r, resource_name });
    std.debug.print("# Controls: freq={d:.1} size={d:.1} rich={d:.1}\n", .{ controls.frequency, controls.size, controls.richness });

    var ores = try surfacegen.ore.computeOresInRect(a, seed, -r, -r, r, r, configs.items, names.items, controls);
    defer ores.deinit(a);

    std.debug.print("# Found {} ore entities\n", .{ores.items.len});

    // PNG output
    if (png_filename) |filename| {
        const size: u32 = @intCast(r * 2);

        // Build a spatial index: grid[y*size + x] = index into ores, or max
        // Simple: for each ore, write to pixel grid
        var pixels = try a.alloc(u8, size * size * 4);
        @memset(pixels, 0); // black background

        for (ores.items) |ore| {
            const px: u32 = @intCast(ore.x + r);
            const py: u32 = @intCast(ore.y + r);
            if (px < size and py < size) {
                const idx: usize = @intCast((py * size + px) * 4);
                const color = MapColors.get(ore.resource_name);
                // Blend: use max brightness (multiple ores can overlap)
                if (pixels[idx + 3] == 0) {
                    @memcpy(pixels[idx..][0..4], &color);
                } else {
                    // Blend: take max of each channel
                    for (0..3) |ch| {
                        if (color[ch] > pixels[idx + ch]) pixels[idx + ch] = color[ch];
                    }
                }
            }
        }

        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);

        // Write PNG directly to a buffer then write to file
        var png_buf: std.ArrayList(u8) = .empty;
        try surfacegen.png.writePng(a, &png_buf, size, size, pixels);
        try file.writePositionalAll(init.io, png_buf.items, 0);
        std.debug.print("# Wrote PNG: {s} ({d}x{d})\n", .{ filename, size, size });
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

    const sample_count = @min(ores.items.len, 20);
    std.debug.print("# Sample ({d}):\n", .{sample_count});
    for (ores.items[0..sample_count]) |ore| {
        std.debug.print("  {s} @ ({d}, {d}) amount={d}\n", .{ ore.resource_name, ore.x, ore.y, ore.amount });
    }
}
