const std = @import("std");
const surfacegen = @import("surface_generator");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const args = try init.minimal.args.toSlice(a);
    if (args.len < 2) {
        std.debug.print(
            \\surfacegen — Factorio surface generator (ore-first)
            \\
            \\Usage: surfacegen <seed> [resource] [--radius R] [--freq F] [--size S] [--rich R]
            \\
            \\Resources: iron-ore, copper-ore, coal, stone, uranium-ore, crude-oil, all
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
    var controls = surfacegen.ore.AutoplaceControls{};

    // Parse optional args
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
        } else if (!std.mem.startsWith(u8, args[i], "--")) {
            resource_name = args[i];
        }
    }

    // Select resources
    var configs: std.ArrayList(surfacegen.ore.ResourceAutoplaceConfig) = .empty;
    var names: std.ArrayList([]const u8) = .empty;

    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "iron-ore")) {
        try configs.append(a, surfacegen.ore.iron_ore_default);
        try names.append(a, "iron-ore");
    }
    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "copper-ore")) {
        try configs.append(a, surfacegen.ore.copper_ore_default);
        try names.append(a, "copper-ore");
    }
    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "coal")) {
        try configs.append(a, surfacegen.ore.coal_default);
        try names.append(a, "coal");
    }
    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "stone")) {
        try configs.append(a, surfacegen.ore.stone_default);
        try names.append(a, "stone");
    }
    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "uranium-ore")) {
        try configs.append(a, surfacegen.ore.uranium_ore_default);
        try names.append(a, "uranium-ore");
    }
    if (std.mem.eql(u8, resource_name, "all") or std.mem.eql(u8, resource_name, "crude-oil")) {
        try configs.append(a, surfacegen.ore.crude_oil_default);
        try names.append(a, "crude-oil");
    }

    const r: i32 = @intFromFloat(radius);
    std.debug.print("# Seed {d}, radius {d}, resource(s): {s}\n", .{ seed, r, resource_name });
    std.debug.print("# Controls: freq={d:.1} size={d:.1} rich={d:.1}\n", .{ controls.frequency, controls.size, controls.richness });

    var ores = try surfacegen.ore.computeOresInRect(a, seed, -r, -r, r, r, configs.items, names.items, controls);
    defer ores.deinit(a);

    std.debug.print("# Found {} ore entities\n", .{ores.items.len});

    // Count by resource
    const resources_list = [_][]const u8{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil" };
    for (resources_list) |rname| {
        var count: u32 = 0;
        for (ores.items) |ore| {
            if (std.mem.eql(u8, ore.resource_name, rname)) count += 1;
        }
        if (count > 0) {
            std.debug.print("#   {s}: {d}\n", .{ rname, count });
        }
    }

    // Print first few entities as sample
    const sample_count = @min(ores.items.len, 20);
    std.debug.print("# Sample ({d}):\n", .{sample_count});
    for (ores.items[0..sample_count]) |ore| {
        std.debug.print("  {s} @ ({d}, {d}) amount={d}\n", .{ ore.resource_name, ore.x, ore.y, ore.amount });
    }
}
