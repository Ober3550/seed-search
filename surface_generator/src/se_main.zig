const std = @import("std");
const surfacegen = @import("surface_generator");
const se = surfacegen.se_ore;

/// Factorio/SE map colors (RGB).
const MapColors = struct {
    fn get(name: []const u8) [3]u8 {
        if (std.mem.eql(u8, name, "iron-ore")) return .{ 106, 134, 148 };
        if (std.mem.eql(u8, name, "copper-ore")) return .{ 205, 99, 55 };
        if (std.mem.eql(u8, name, "coal")) return .{ 60, 60, 60 };
        if (std.mem.eql(u8, name, "stone")) return .{ 176, 156, 109 };
        if (std.mem.eql(u8, name, "uranium-ore")) return .{ 0, 179, 0 };
        if (std.mem.eql(u8, name, "crude-oil")) return .{ 199, 51, 196 };
        if (std.mem.eql(u8, name, "se-vulcanite")) return .{ 230, 120, 60 };
        if (std.mem.eql(u8, name, "se-cryonite")) return .{ 90, 200, 230 };
        if (std.mem.eql(u8, name, "se-vitamelange")) return .{ 150, 90, 200 };
        return .{ 128, 128, 128 };
    }
};

// ---- Horaerratum target (world 57374), non-K2 resources ----
// config: base_density, base_spots_per_km2, rq_mult, random_probability,
//         additional_richness, spot_size_min, spot_size_max
// controls from output/target-horaerratum.json (computeZoneResourceControls).
const Entry = struct {
    name: []const u8,
    cfg: se.SEResourceConfig,
    ctrl: se.Controls,
};

const HORAERRATUM_SEED: u32 = 2035207183;
const HORAERRATUM_RADIUS: f64 = 1041.0;

fn entries() [9]Entry {
    // patch-set indices are placeholders (data-stage order unknown) — positions
    // won't match the game yet, but counts/sizes will. Count = 9 non-K2 resources.
    var i: u32 = 0;
    const mk = struct {
        fn f(idx: *u32, name: []const u8, bd: f64, bspk: f64, rqm: f64, rp: f64, add: f64, smin: f64, smax: f64, cf: f64, cs: f64, cr: f64) Entry {
            const e = Entry{
                .name = name,
                .cfg = .{
                    .base_density = bd,
                    .base_spots_per_km2 = bspk,
                    .regular_rq_factor_multiplier = rqm,
                    .random_probability = rp,
                    .additional_richness = add,
                    .random_spot_size_minimum = smin,
                    .random_spot_size_maximum = smax,
                    .regular_patch_set_index = idx.*,
                    .regular_patch_set_count = 9,
                },
                .ctrl = .{ .frequency = cf, .size = cs, .richness = cr },
            };
            idx.* += 1;
            return e;
        }
    }.f;
    return .{
        mk(&i, "iron-ore", 14, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0.8208, 1.5519, 1.5743),
        mk(&i, "copper-ore", 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0.4688, 0.6721, 0.7385),
        mk(&i, "uranium-ore", 1, 2.0, 1.1, 1.0, 0, 2.0, 4.0, 0.7635, 1.4088, 1.4384),
        mk(&i, "coal", 9, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0.3323, 0.3307, 0.4141),
        mk(&i, "crude-oil", 8, 2.5, 1.2, 1.0 / 24.0, 220000, 1.0, 1.0, 0.5600, 0.8999, 0.9549),
        mk(&i, "stone", 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0.6757, 1.1893, 1.2299),
        mk(&i, "se-vulcanite", 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 0.2691, 0.1727, 0.2640),
        mk(&i, "se-cryonite", 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 0.2882, 0.2204, 0.3094),
        mk(&i, "se-vitamelange", 10, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 1.6697, 3.6742, 3.5905),
    };
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const args = try init.minimal.args.toSlice(a);
    var bmp_filename: ?[]const u8 = null;
    var jsonl_filename: ?[]const u8 = null;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--bmp")) {
            i += 1;
            if (i < args.len) bmp_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--jsonl")) {
            i += 1;
            if (i < args.len) jsonl_filename = args[i];
        }
    }

    const es = entries();
    var inputs: [9]se.ResourceInput = undefined;
    for (es, 0..) |e, k| inputs[k] = .{ .name = e.name, .config = e.cfg, .controls = e.ctrl };

    const r: i32 = @intFromFloat(HORAERRATUM_RADIUS);
    std.debug.print("# SE zone Horaerratum (world 57374), map_seed={d}, radius={d}\n", .{ HORAERRATUM_SEED, r });

    var ores = try se.computeSEOresInRect(a, HORAERRATUM_SEED, HORAERRATUM_RADIUS, -r, -r, r, r, &inputs);
    defer ores.deinit(a);
    std.debug.print("# Found {} ore entities\n", .{ores.items.len});

    // counts per resource
    for (es) |e| {
        var count: u32 = 0;
        for (ores.items) |ore| if (std.mem.eql(u8, ore.resource_name, e.name)) {
            count += 1;
        };
        if (count > 0) std.debug.print("#   {s}: {d}\n", .{ e.name, count });
    }

    if (bmp_filename) |filename| {
        const size: u32 = @intCast(r * 2);
        var pixels = try a.alloc(u8, size * size * 3);
        @memset(pixels, 20);
        for (ores.items) |ore| {
            const px: i32 = ore.x + r;
            const py: i32 = ore.y + r;
            if (px >= 0 and px < size and py >= 0 and py < size) {
                const color = MapColors.get(ore.resource_name);
                const idx: usize = @intCast((@as(i32, @intCast(size)) * py + px) * 3);
                @memcpy(pixels[idx..][0..3], &color);
            }
        }
        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);
        var buf: std.ArrayList(u8) = .empty;
        try surfacegen.bmp.writeBmp(a, &buf, size, size, pixels);
        try file.writePositionalAll(init.io, buf.items, 0);
        std.debug.print("# Wrote BMP: {s} ({d}x{d})\n", .{ filename, size, size });
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
        std.debug.print("# Wrote JSONL: {s}\n", .{filename});
    }
}
