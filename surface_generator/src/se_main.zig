const std = @import("std");
const surfacegen = @import("surface_generator");
const se = surfacegen.se_ore;
const universe = @import("universe_gen");

/// Factorio/SE/K2 map colors (RGB), matching the ground-truth renderer
/// calibration/mod-dump/convert_jsonl.py so generated images are directly
/// comparable to Horaerratum.png. Unknown -> grey; se-core-fragment-* inherits
/// its base resource's color.
const MapColors = struct {
    fn get(name: []const u8) [3]u8 {
        // Authoritative resource map_color (dumped live -> calibration/mod-dump/ore-colors.json).
        // Vanilla
        if (std.mem.eql(u8, name, "iron-ore")) return .{ 105, 133, 147 };
        if (std.mem.eql(u8, name, "copper-ore")) return .{ 204, 98, 54 };
        if (std.mem.eql(u8, name, "coal")) return .{ 0, 0, 0 };
        if (std.mem.eql(u8, name, "stone")) return .{ 175, 155, 108 };
        if (std.mem.eql(u8, name, "uranium-ore")) return .{ 0, 178, 0 };
        if (std.mem.eql(u8, name, "crude-oil")) return .{ 255, 153, 0 };
        // Krastorio 2
        if (std.mem.eql(u8, name, "kr-rare-metal-ore")) return .{ 153, 76, 255 };
        if (std.mem.eql(u8, name, "kr-imersite")) return .{ 255, 127, 255 };
        if (std.mem.eql(u8, name, "kr-mineral-water")) return .{ 89, 127, 191 };
        // Space Exploration
        if (std.mem.eql(u8, name, "se-water-ice")) return .{ 198, 241, 245 };
        if (std.mem.eql(u8, name, "se-methane-ice")) return .{ 245, 231, 198 };
        if (std.mem.eql(u8, name, "se-beryllium-ore")) return .{ 144, 222, 184 };
        if (std.mem.eql(u8, name, "se-cryonite")) return .{ 35, 164, 255 };
        if (std.mem.eql(u8, name, "se-holmium-ore")) return .{ 135, 96, 109 };
        if (std.mem.eql(u8, name, "se-iridium-ore")) return .{ 244, 202, 85 };
        if (std.mem.eql(u8, name, "se-naquium-ore")) return .{ 137, 113, 214 };
        if (std.mem.eql(u8, name, "se-vulcanite")) return .{ 224, 40, 10 };
        if (std.mem.eql(u8, name, "se-vitamelange")) return .{ 173, 206, 54 };
        // Core fragments inherit their base resource's color.
        const prefix = "se-core-fragment-";
        if (std.mem.startsWith(u8, name, prefix)) return get(name[prefix.len..]);
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

// Total number of placeable resource patch sets in the "default" autoplace set
// (base + K2 + SE). All resources share one metaset and stride across a common
// candidate-point list: skip_span = this count, skip_offset = per-resource index.
// Captured from the live game via calibration/mod-dump/patchset-dump.json
// (patchset-dump mod, data-final-fixes). This is what makes spot POSITIONS match.
const SE_REGULAR_PATCH_SET_COUNT: u32 = 18;

const SE_STARTING_PATCH_SET_COUNT: u32 = 14; // starting_patch_set_count (patchset-dump)

fn mkEntry(name: []const u8, idx: u32, bd: f64, bspk: f64, rqm: f64, rp: f64, add: f64, smin: f64, smax: f64, cf: f64, cs: f64, cr: f64, si: i32, srq: f64) Entry {
    // (name, regular_patch_set_index, base_density, base_spots_per_km2, rq_mult,
    //  random_probability, additional_richness, spot_size_min, spot_size_max,
    //  freq_control, size_control, richness_control,
    //  starting_patch_set_index (-1 = no starting patches), starting_rq_mult)
    return .{
        .name = name,
        .cfg = .{
            .base_density = bd,
            .base_spots_per_km2 = bspk,
            .regular_rq_factor_multiplier = rqm,
            .random_probability = rp,
            .additional_richness = add,
            .random_spot_size_minimum = smin,
            .random_spot_size_maximum = smax,
            .regular_patch_set_index = idx,
            .regular_patch_set_count = SE_REGULAR_PATCH_SET_COUNT,
            .has_starting_area_placement = si >= 0,
            .starting_patch_set_index = if (si >= 0) @intCast(si) else 0,
            .starting_patch_set_count = SE_STARTING_PATCH_SET_COUNT,
            .starting_rq_factor_multiplier = srq,
        },
        .ctrl = .{ .frequency = cf, .size = cs, .richness = cr },
    };
}

const N_BASE_RESOURCES = 9;
// Each resource strides the shared candidate list from its data-load index
// (regular_patch_set_index, from patchset-dump.json) by SE_REGULAR_PATCH_SET_COUNT.
// Controls (last 3 args) are the ACTUAL post-zone-modifier values the game
// applied (SE multiplies zone-control frequency by a per-moon factor ~4.8x).
// The last 3 (Krastorio 2) are gated behind --k2. K2 params from SE's K2 compat
// (prototypes/phase-1/compatibility/krastorio2/resource-gen.lua); controls dumped
// live from Horaerratum.
const RESOURCE_ENTRIES = [_]Entry{
    mkEntry("iron-ore", 0, 14, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.72599, 1.43847, 1.46655, 0, 1.5),
    mkEntry("copper-ore", 1, 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 2.08951, 0.58708, 0.65773, 1, 1.5),
    mkEntry("uranium-ore", 5, 1, 2.0, 1.1, 1.0, 0, 2.0, 4.0, 3.45809, 1.29909, 1.33414, -1, 1.0),
    mkEntry("coal", 2, 9, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 1.46945, 0.26449, 0.35127, 2, 1.5),
    mkEntry("crude-oil", 4, 8, 2.5, 1.2, 1.0 / 24.0, 220000, 1.0, 1.0, 2.50998, 0.80584, 0.86554, 4, 1.5),
    mkEntry("stone", 3, 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.04810, 1.08579, 1.13150, 3, 1.5),
    mkEntry("se-vulcanite", 16, 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 4.36720, 1.77206, 1.78346, 12, 1.0),
    mkEntry("se-cryonite", 12, 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 4.52532, 1.85433, 1.86161, 8, 1.0),
    mkEntry("se-vitamelange", 17, 10, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 8.02342, 3.67423, 3.59052, 13, 1.0),
    // --- Krastorio 2 (--k2) --- (has_starting_area_placement = false)
    mkEntry("kr-rare-metal-ore", 8, 8, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.97694, 1.56903, 1.59058, -1, 1.5),
    mkEntry("kr-mineral-water", 7, 8, 2.0, 1.0, 1.0 / 24.0, 120000, 1.0, 1.0, 3.33011, 1.23251, 1.27089, -1, 1.0),
    mkEntry("kr-imersite", 6, 1, 0.05, 1.0, 1.0 / 4.0, 250000, 0.01, 0.1, 3.59600, 1.37084, 1.40230, -1, 1.0),
    // --- remaining SE ores (live-dump params; controls come from the zone driver,
    //     size 0 here means "skipped unless a zone provides controls") ---
    mkEntry("se-water-ice", 9, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 5, 1.0),
    mkEntry("se-methane-ice", 10, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 6, 1.0),
    mkEntry("se-beryllium-ore", 11, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 7, 1.0),
    mkEntry("se-holmium-ore", 13, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 9, 1.0),
    mkEntry("se-iridium-ore", 14, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 10, 1.0),
    mkEntry("se-naquium-ore", 15, 1, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 11, 1.0),
};

const N_ALL_RESOURCES = RESOURCE_ENTRIES.len;

fn entries(k2: bool) []const Entry {
    return if (k2) RESOURCE_ENTRIES[0..] else RESOURCE_ENTRIES[0..N_BASE_RESOURCES];
}

/// Zone driver: read a seeds jsonl (universe summary), pick a world by seed and
/// zones by name, compute each zone's surface autoplace controls via the
/// universe generator port, generate ore, and write results into
/// <out>/<world_seed>/<zone_name>/ore.jsonl (+ ore.bmp with --bmp).
fn runZoneDriver(
    a: std.mem.Allocator,
    init: std.process.Init,
    zones_path: []const u8,
    world_seed: u64,
    zone_csv: ?[]const u8,
    out_dir: []const u8,
    ores_only: bool,
    write_bmp: bool,
) !void {
    const raw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, zones_path, a, .unlimited);
    var world: ?std.json.Value = null;
    var lines = std.mem.tokenizeAny(u8, raw, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const parsed = std.json.parseFromSlice(std.json.Value, a, line, .{}) catch continue;
        const obj = parsed.value.object;
        const sv = obj.get("s") orelse continue;
        const sval: u64 = switch (sv) {
            .integer => |v| @intCast(v),
            else => continue,
        };
        if (sval == world_seed) {
            world = parsed.value;
            break;
        }
    }
    const w = world orelse {
        std.debug.print("world seed {d} not found in {s}\n", .{ world_seed, zones_path });
        return;
    };
    const wobj = w.object;
    const has_k2 = if (wobj.get("k")) |kv| (kv == .bool and kv.bool) else false;
    const zarr = (wobj.get("z") orelse {
        std.debug.print("world has no zones array\n", .{});
        return;
    }).array;

    var wanted = std.StringHashMapUnmanaged(bool).empty;
    const all_zones = zone_csv == null or std.mem.eql(u8, zone_csv.?, "all");
    if (!all_zones) {
        var it = std.mem.tokenizeAny(u8, zone_csv.?, ",");
        while (it.next()) |zn| try wanted.put(a, zn, true);
    }

    for (zarr.items) |zv| {
        const z = zv.object;
        const name = (z.get("n") orelse continue).string;
        if (!all_zones and wanted.get(name) == null) continue;
        const ztype_str = (z.get("t") orelse continue).string;
        const ztype: universe.data.ZoneType = blk: {
            inline for (@typeInfo(universe.data.ZoneType).@"enum".fields) |fld| {
                if (std.mem.eql(u8, ztype_str, fld.name)) break :blk @enumFromInt(fld.value);
            }
            std.debug.print("zone {s}: unsupported type {s}, skipping\n", .{ name, ztype_str });
            continue;
        };
        if (ztype != .planet and ztype != .moon) {
            std.debug.print("zone {s}: type {s} not surface-generatable, skipping\n", .{ name, ztype_str });
            continue;
        }
        const zone_seed: u32 = @intCast((z.get("s") orelse continue).integer);
        const radius: f64 = switch (z.get("r") orelse continue) {
            .integer => |v| @floatFromInt(v),
            .float => |v| v,
            else => continue,
        };
        const primary: ?[]const u8 = if (z.get("p")) |pv| (if (pv == .string) pv.string else null) else null;

        // tags (strings, optional)
        const tags = universe.Tags{
            .temperature = tagOf(universe.data.Temperature, z, "temperature"),
            .water = tagOf(universe.data.Water, z, "water"),
            .moisture = tagOf(universe.data.Moisture, z, "moisture"),
            .trees = tagOf(universe.data.Trees, z, "trees"),
            .aux = tagOf(universe.data.Aux, z, "aux"),
            .cliff = tagOf(universe.data.Cliff, z, "cliff"),
            .enemy = tagOf(universe.data.Enemy, z, "enemy"),
        };
        const controls = universe.computeZoneMapgenControls(zone_seed, ztype, primary, tags, radius, false);
        for (universe.resource_order, 0..) |rn, ri| {
            const c = controls[ri];
            if (c.present) std.debug.print("   ctrl {s}: f={d:.4} s={d:.4} r={d:.4}\n", .{ rn, c.frequency, c.size, c.richness });
        }

        // build resource inputs: our config table + the zone's controls
        var inputs_buf: [RESOURCE_ENTRIES.len]se.ResourceInput = undefined;
        var ninputs: usize = 0;
        for (RESOURCE_ENTRIES) |e| {
            if (!has_k2 and std.mem.startsWith(u8, e.name, "kr-")) continue;
            if (ores_only and e.cfg.random_probability < 1.0) continue;
            var ctrl = se.Controls{ .frequency = 0, .size = 0, .richness = 0 };
            for (universe.resource_order, 0..) |rn, ri| {
                if (std.mem.eql(u8, rn, e.name)) {
                    const c = controls[ri];
                    if (c.present) ctrl = .{ .frequency = c.frequency, .size = c.size, .richness = c.richness };
                    break;
                }
            }
            if (ctrl.size <= 0) continue;
            inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = ctrl };
            ninputs += 1;
        }
        const inputs = inputs_buf[0..ninputs];

        // terrain: water tag "none" => no water gate; otherwise approximate the
        // SE water control (freq 1, size 1.5 — the calibrated Horaerratum point).
        const has_water = if (tags.water) |wt| wt != .none else false;
        var elev: ?surfacegen.terrain.Elevation = null;
        var zt: ?surfacegen.terrain.ZoneTerrain = null;
        var classifier: ?surfacegen.biome.Classifier = null;
        if (has_water) elev = surfacegen.terrain.Elevation.init(zone_seed, 1.0, 1.5);
        const fm = universe.zoneFrequencyMultiplier(radius);
        zt = surfacegen.terrain.ZoneTerrain.init(.{
            .map_seed = zone_seed,
            .moisture_frequency = 1.0,
            .moisture_bias = 0.0,
            .aux_frequency = 1.0,
            .aux_bias = 0.0,
            .cold_size = 6.0,
            .hot_size = 6.0,
            .cold_frequency = fm,
            .hot_frequency = fm,
            .water_frequency = 1.0,
            .water_size = if (has_water) 1.5 else 0.0,
        });
        classifier = surfacegen.biome.Classifier.init(zone_seed);

        const r: i32 = @intFromFloat(radius);
        std.debug.print("== zone {s} (seed {d}, r {d}, {d} resources)\n", .{ name, zone_seed, r, ninputs });
        var ores = try se.computeSEOresInRect(
            a,
            zone_seed,
            radius,
            -r,
            -r,
            r,
            r,
            inputs,
            1,
            if (elev) |*e| e else null,
            if (zt) |*t| t else null,
            if (classifier) |*c| c else null,
        );
        defer ores.deinit(a);

        // per-resource counts
        {
            for (inputs) |inp| {
                var cnt: u64 = 0;
                var amount: u64 = 0;
                for (ores.items) |o| {
                    if (std.mem.eql(u8, o.resource_name, inp.name)) {
                        cnt += 1;
                        amount += o.amount;
                    }
                }
                if (cnt > 0) std.debug.print("   {s}: {d} tiles, {d} total\n", .{ inp.name, cnt, amount });
            }
        }

        // write outputs
        var dirbuf: [512]u8 = undefined;
        const zdir = try std.fmt.bufPrint(&dirbuf, "{s}/{d}/{s}", .{ out_dir, world_seed, name });
        try std.Io.Dir.createDirPath(.cwd(), init.io, zdir);
        var pathbuf: [512]u8 = undefined;
        const jpath = try std.fmt.bufPrint(&pathbuf, "{s}/ore.jsonl", .{zdir});
        {
            var buf: std.ArrayList(u8) = .empty;
            for (ores.items) |ore| {
                var line: [256]u8 = undefined;
                const sl = try std.fmt.bufPrint(&line, "{{\"x\":{d},\"y\":{d},\"n\":\"{s}\",\"a\":{d}}}\n", .{ ore.x, ore.y, ore.resource_name, ore.amount });
                try buf.appendSlice(a, sl);
            }
            const file = try std.Io.Dir.createFile(.cwd(), init.io, jpath, .{});
            defer file.close(init.io);
            try file.writePositionalAll(init.io, buf.items, 0);
        }
        std.debug.print("   wrote {s} ({d} entities)\n", .{ jpath, ores.items.len });
        if (write_bmp) {
            var bpathbuf: [512]u8 = undefined;
            const bpath = try std.fmt.bufPrint(&bpathbuf, "{s}/ore.bmp", .{zdir});
            const size: u32 = @intCast(r * 2);
            var pixels = try a.alloc(u8, @as(usize, size) * size * 3);
            defer a.free(pixels);
            @memset(pixels, 20);
            for (ores.items) |ore| {
                const px: i64 = @as(i64, ore.x) + r;
                const py: i64 = @as(i64, ore.y) + r;
                if (px < 0 or py < 0 or px >= size or py >= size) continue;
                const color = MapColors.get(ore.resource_name);
                const idx: usize = (@as(usize, @intCast(py)) * size + @as(usize, @intCast(px))) * 3;
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
            }
            var bbuf: std.ArrayList(u8) = .empty;
            try surfacegen.bmp.writeBmp(a, &bbuf, size, size, pixels);
            const bfile = try std.Io.Dir.createFile(.cwd(), init.io, bpath, .{});
            defer bfile.close(init.io);
            try bfile.writePositionalAll(init.io, bbuf.items, 0);
            std.debug.print("   wrote {s}\n", .{bpath});
        }
    }
}

fn tagOf(comptime E: type, z: std.json.ObjectMap, key: []const u8) ?E {
    const v = z.get(key) orelse return null;
    if (v != .string) return null;
    // seeds jsonl stores bare enum names ("very_high"), while tagStr() returns
    // the prefixed prototype tags ("aux_very_high") — match field names.
    inline for (@typeInfo(E).@"enum".fields) |fld| {
        if (std.mem.eql(u8, v.string, fld.name)) return @enumFromInt(fld.value);
    }
    return universe.parseTagEnum(E, v.string);
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const args = try init.minimal.args.toSlice(a);
    var bmp_filename: ?[]const u8 = null;
    var jsonl_filename: ?[]const u8 = null;
    var sample_step: i32 = 1;
    var override_radius: ?i32 = null;
    var spot_stats: bool = false;
    var probe: bool = false;
    var terrain_probe: bool = false;
    var elev_grid: bool = false;
    var nauvis_water: bool = false;
    var mo_fit: bool = false;
    var nauvis_elev: bool = false;
    var nauvis_diag: bool = false;
    var nauvis_biome: bool = false;
    var horaerratum_biome: bool = false;
    var water_exclude: bool = false;
    var biome_bg: bool = false;
    var k2_enable: bool = false;
    var ores_only: bool = false;
    var zones_file: ?[]const u8 = null;
    var world_seed: ?u64 = null;
    var zone_names: ?[]const u8 = null;
    var out_dir: []const u8 = "output";
    var field_probe_res: ?[]const u8 = null;
    var field_probe_in: ?[]const u8 = null;
    var field_probe_out: ?[]const u8 = null;
    var ctrl_override: ?se.Controls = null;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--bmp")) {
            i += 1;
            if (i < args.len) bmp_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--jsonl")) {
            i += 1;
            if (i < args.len) jsonl_filename = args[i];
        } else if (std.mem.eql(u8, args[i], "--sample")) {
            i += 1;
            if (i < args.len) sample_step = try std.fmt.parseInt(i32, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "--radius")) {
            i += 1;
            if (i < args.len) override_radius = try std.fmt.parseInt(i32, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "--spot-stats")) {
            spot_stats = true;
        } else if (std.mem.eql(u8, args[i], "--probe")) {
            probe = true;
        } else if (std.mem.eql(u8, args[i], "--ctrl")) {
            i += 1;
            const cf = try std.fmt.parseFloat(f64, args[i]);
            i += 1;
            const cs = try std.fmt.parseFloat(f64, args[i]);
            i += 1;
            const cr = try std.fmt.parseFloat(f64, args[i]);
            ctrl_override = .{ .frequency = cf, .size = cs, .richness = cr };
        } else if (std.mem.eql(u8, args[i], "--field-probe")) {
            i += 1;
            field_probe_res = args[i];
            i += 1;
            field_probe_in = args[i];
            i += 1;
            field_probe_out = args[i];
        } else if (std.mem.eql(u8, args[i], "--terrain-probe")) {
            terrain_probe = true;
        } else if (std.mem.eql(u8, args[i], "--elev-grid")) {
            elev_grid = true;
        } else if (std.mem.eql(u8, args[i], "--nauvis-water")) {
            nauvis_water = true;
        } else if (std.mem.eql(u8, args[i], "--mo-fit")) {
            mo_fit = true;
        } else if (std.mem.eql(u8, args[i], "--nauvis-elev")) {
            nauvis_elev = true;
        } else if (std.mem.eql(u8, args[i], "--nauvis-diag")) {
            nauvis_diag = true;
        } else if (std.mem.eql(u8, args[i], "--nauvis-biome")) {
            nauvis_biome = true;
        } else if (std.mem.eql(u8, args[i], "--horaerratum-biome")) {
            horaerratum_biome = true;
        } else if (std.mem.eql(u8, args[i], "--biome-bg")) {
            biome_bg = true;
        } else if (std.mem.eql(u8, args[i], "--ores-only")) {
            ores_only = true;
        } else if (std.mem.eql(u8, args[i], "--zones")) {
            i += 1;
            zones_file = args[i];
        } else if (std.mem.eql(u8, args[i], "--world-seed")) {
            i += 1;
            world_seed = try std.fmt.parseInt(u64, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "--zone")) {
            i += 1;
            zone_names = args[i];
        } else if (std.mem.eql(u8, args[i], "--out")) {
            i += 1;
            out_dir = args[i];
        } else if (std.mem.eql(u8, args[i], "--k2")) {
            k2_enable = true;
        } else if (std.mem.eql(u8, args[i], "--water")) {
            water_exclude = true;
        }
    }

    if (nauvis_elev) {
        // Dump vanilla-Nauvis (seed 123456) elevation on a grid for correlation
        // vs the game (RCON calculate_tile_properties elevation).
        const el = surfacegen.terrain.Elevation.init(123456, 1.0, 1.0);
        var gy: i32 = -500;
        while (gy <= 500) : (gy += 25) {
            var gx: i32 = -500;
            while (gx <= 500) : (gx += 25) {
                std.debug.print("{d} {d} {d:.3}\n", .{ gx, gy, el.at(@floatFromInt(gx), @floatFromInt(gy)) });
            }
        }
        return;
    }

    if (mo_fit) {
        // Fit the multioctave octave-combination to the game's raw probe values
        // (noise-probe mod: seed1=42, input_scale=1/50, persistence=0.5).
        const pts = [_][2]f64{ .{ 137, 251 }, .{ 613, -89 }, .{ -329, 405 }, .{ 88, -467 }, .{ 450, 50 }, .{ -300, 300 } };
        const g2 = [_]f64{ -0.9139, 0.2761, -0.6067, -0.2191, -0.5369, -0.1195 };
        const g3 = [_]f64{ 0.4380, 0.5460, 0.0527, -0.3079, -0.8474, 0.5673 };
        const g4 = [_]f64{ 1.0946, 0.1644, 0.4123, 0.7852, 0.7155, 0.8683 };
        const gen = surfacegen.noise.BasisNoiseGen.init(123456, 42);
        const is: f64 = 1.0 / 50.0;
        // basis at octave-k noise-space coord (already scaled): eval with input_scale=1
        const mo = struct {
            fn f(g: *const surfacegen.noise.BasisNoiseGen, x: f64, y: f64, iscale: f64, N: u32, r: f64, off: f64, ampm: f64, norm_kind: u8) f64 {
                var value: f64 = 0;
                var amp: f64 = 1;
                var rk: f64 = 1; // r^k
                var sq: f64 = 0;
                var absum: f64 = 0;
                var k: f64 = 0;
                var kk: u32 = 0;
                while (kk < N) : (kk += 1) {
                    const cx = x * iscale * rk + off * k;
                    const cy = y * iscale * rk;
                    value += g.eval(cx, cy, 1.0, 1.0) * amp;
                    sq += amp * amp;
                    absum += @abs(amp);
                    rk *= r;
                    amp *= ampm;
                    k += 1.0;
                }
                const nrm: f64 = switch (norm_kind) {
                    0 => @sqrt(sq),
                    1 => absum,
                    else => 1.0,
                };
                return value / nrm;
            }
        }.f;
        // Verify my basis == game mo1 first.
        std.debug.print("basis check (should equal g1): ", .{});
        for (pts) |p| std.debug.print("{d:.4} ", .{gen.eval(p[0], p[1], is, 1.0)});
        std.debug.print("\n  game g1: -0.3872 -0.3460 -0.3317 0.0857 0.0000 0.0000\n\n", .{});
        const rs = [_]f64{ 2.0, 0.5 };
        const offs = [_]f64{ 0.0, 17.17, 8.585 };
        const amps = [_]f64{ 0.5, 2.0 };
        const norms = [_]u8{ 0, 2 }; // rms, none
        for (rs) |r| for (offs) |off| for (amps) |ampm| for (norms) |nk| {
            var mse: f64 = 0;
            for (pts, 0..) |p, j| {
                const v2 = mo(&gen, p[0], p[1], is, 2, r, off, ampm, nk);
                const v3 = mo(&gen, p[0], p[1], is, 3, r, off, ampm, nk);
                const v4 = mo(&gen, p[0], p[1], is, 4, r, off, ampm, nk);
                mse += (v2 - g2[j]) * (v2 - g2[j]) + (v3 - g3[j]) * (v3 - g3[j]) + (v4 - g4[j]) * (v4 - g4[j]);
            }
            std.debug.print("r={d:.1} off={d:>5.2} amp={d:.1} norm={d}: mse={d:.4}\n", .{ r, off, ampm, nk, mse });
        };
        return;
    }

    if (nauvis_biome) {
        // Dump temperature/moisture/aux over [-512,512) for a visual compare vs
        // the game. Each field: 1024 rows of 1024 chars; char = 33 + level(0..93),
        // level = round(clamp((v-lo)/(hi-lo),0,1)*93). Fields separated by a "=name"
        // header line. Ranges: temperature -20..50, moisture 0..1, aux 0..1.
        const zt = surfacegen.terrain.ZoneTerrain.init(.{
            .map_seed = 123456,
            .moisture_frequency = 1.0, .moisture_bias = 0.0,
            .aux_frequency = 1.0, .aux_bias = 0.0,
            .temperature_frequency = 1.0, .temperature_bias = 0.0,
            .cold_size = 1.0, .hot_size = 1.0, .cold_frequency = 1.0, .hot_frequency = 1.0,
            .water_frequency = 1.0, .water_size = 1.0,
            .starting_moisture_bias = 0.0, .starting_moisture_frequency = 1.0,
        });
        const R: i32 = 512;
        const Field = struct { name: []const u8, lo: f64, hi: f64 };
        const fields = [_]Field{
            .{ .name = "temperature", .lo = -20.0, .hi = 50.0 },
            .{ .name = "moisture", .lo = 0.0, .hi = 1.0 },
            .{ .name = "aux", .lo = 0.0, .hi = 1.0 },
        };
        for (fields) |fl| {
            std.debug.print("={s}\n", .{fl.name});
            var row: [1024]u8 = undefined;
            var iy: i32 = -R;
            while (iy < R) : (iy += 1) {
                var ix: i32 = -R;
                while (ix < R) : (ix += 1) {
                    const fx: f64 = @floatFromInt(ix);
                    const fy: f64 = @floatFromInt(iy);
                    const v = if (std.mem.eql(u8, fl.name, "temperature"))
                        zt.temperature(fx, fy)
                    else if (std.mem.eql(u8, fl.name, "moisture"))
                        zt.moisture(fx, fy)
                    else
                        zt.aux(fx, fy);
                    const t = std.math.clamp((v - fl.lo) / (fl.hi - fl.lo), 0.0, 1.0);
                    const lvl: u8 = @intFromFloat(@round(t * 93.0));
                    row[@intCast(ix + R)] = 33 + lvl;
                }
                std.debug.print("{s}\n", .{row[0..]});
            }
        }
        return;
    }

    if (horaerratum_biome) {
        // Classify every tile of Horaerratum via the alien-biomes tile placement
        // (temperature/moisture/aux/elevation -> winning tile -> map_color) and
        // render to a BMP to diff against the ground truth
        // (calibration/mod-dump/tile-bmp-Horaerratum.bmp). Water where elevation<0.
        const r: i32 = if (override_radius) |or2| or2 else @intFromFloat(HORAERRATUM_RADIUS);
        const zone_r: f64 = @floatFromInt(r);
        const zt = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
        // Use the moon's calibrated water_size (~40.9% water on the live surface).
        const elev = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, surfacegen.terrain.HORAERRATUM.water_frequency, surfacegen.terrain.HORAERRATUM.water_size);
        const classifier = surfacegen.biome.Classifier.init(surfacegen.terrain.HORAERRATUM.map_seed);

        const size: u32 = @intCast(r * 2);
        var pixels = try a.alloc(u8, size * size * 3);
        @memset(pixels, 20); // disk background (matches the mod)
        var iy: i32 = -r;
        while (iy < r) : (iy += 1) {
            var ix: i32 = -r;
            while (ix < r) : (ix += 1) {
                const dx: f64 = @floatFromInt(ix);
                const dy: f64 = @floatFromInt(iy);
                if (dx * dx + dy * dy > zone_r * zone_r) continue;
                const fx: f64 = @floatFromInt(ix);
                const fy: f64 = @floatFromInt(iy);
                const e = elev.at(fx, fy);
                const color: [3]u8 = if (e < 0.0)
                    (if (e < -5.0) surfacegen.biome.deepwater else surfacegen.biome.water)
                else
                    classifier.classifyColor(fx, fy, zt.temperature(fx, fy), zt.moisture(fx, fy), zt.aux(fx, fy), e);
                // Orientation matches the tile-dump mod's BMP after bmp2png.
                const x_arr: usize = @intCast(ix + r);
                const y_arr: usize = @intCast((r - 1) - iy);
                const idx: usize = (y_arr * size + x_arr) * 3;
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
            }
        }
        const filename = bmp_filename orelse "horaerratum-biome.bmp";
        const file = try std.Io.Dir.createFile(.cwd(), init.io, filename, .{});
        defer file.close(init.io);
        var buf: std.ArrayList(u8) = .empty;
        try surfacegen.bmp.writeBmp(a, &buf, size, size, pixels);
        try file.writePositionalAll(init.io, buf.items, 0);
        std.debug.print("# Wrote biome BMP: {s} ({d}x{d})\n", .{ filename, size, size });
        return;
    }

    if (nauvis_diag) {
        // Verify starting_lake_noise (quick_multioctave_noise_persistence{seed1=14,
        // is=1/8, os=0.8, oct=4, oism=0.5, persistence=0.68}) vs game probe.
        // Verify ZoneTerrain temperature/aux/moisture vs vanilla-Nauvis ground truth.
        const zt = surfacegen.terrain.ZoneTerrain.init(.{
            .map_seed = 123456,
            .moisture_frequency = 1.0,   .moisture_bias = 0.0,
            .aux_frequency = 1.0,        .aux_bias = 0.0,
            .temperature_frequency = 1.0, .temperature_bias = 0.0,
            .cold_size = 1.0, .hot_size = 1.0, .cold_frequency = 1.0, .hot_frequency = 1.0,
            .water_frequency = 1.0, .water_size = 1.0,
            .starting_moisture_bias = 0.0, .starting_moisture_frequency = 1.0,
        });
        const pts = [_][2]f64{ .{ 0, 0 }, .{ 137, 251 }, .{ 613, -89 }, .{ -329, 405 }, .{ 88, -467 }, .{ 450, 50 }, .{ -300, 300 }, .{ 700, 700 }, .{ -800, -200 }, .{ 1200, -600 } };
        std.debug.print("# x y temperature aux moisture plateaus\n", .{});
        for (pts) |p| {
            std.debug.print("{d:.0} {d:.0} {d:.5} {d:.5} {d:.5} {d:.5}\n", .{ p[0], p[1], zt.temperature(p[0], p[1]), zt.aux(p[0], p[1]), zt.moisture(p[0], p[1]), zt.elev.nauvisPlateaus(p[0], p[1]) });
        }
        return;
    }

    if (nauvis_water) {
        // Vanilla Nauvis water mask (elevation<0) for seed 123456, default water
        // controls (frequency=1, size=1 -> water_level=0). Region [-512,512),
        // one row per y, '0'/'1' per x — matches the game dump format.
        // Vanilla Nauvis (base only). Compare vs a game dump generated with
        // seed 123456: RCON `calculate_tile_properties({"elevation"},...)`.
        var el = surfacegen.terrain.Elevation.init(123456, 1.0, 1.0);
        el.addStartingLake(45, -59); // engine-chosen starting lake for seed 123456
        const R: i32 = 512;
        var row: [1024]u8 = undefined;
        var iy: i32 = -R;
        while (iy < R) : (iy += 1) {
            var ix: i32 = -R;
            while (ix < R) : (ix += 1) {
                row[@intCast(ix + R)] = if (el.isWater(@floatFromInt(ix), @floatFromInt(iy))) '1' else '0';
            }
            std.debug.print("{s}\n", .{row[0..]});
        }
        return;
    }

    if (elev_grid) {
        // Dump elevation over a disk grid for water-mask comparison vs the oracle.
        const el = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, 1.0, 1.5);
        const step: i32 = if (override_radius) |o2| o2 else 40;
        const R: i32 = 1040;
        var yy: i32 = -R;
        while (yy <= R) : (yy += step) {
            var xx: i32 = -R;
            while (xx <= R) : (xx += step) {
                const fx: f64 = @floatFromInt(xx);
                const fy: f64 = @floatFromInt(yy);
                if (fx * fx + fy * fy > @as(f64, R) * @as(f64, R)) continue;
                std.debug.print("{d} {d} {d:.2}\n", .{ xx, yy, el.at(fx, fy) });
            }
        }
        return;
    }

    if (terrain_probe) {
        const zt = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
        const el = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, 1.0, 1.5);
        const pts = [_][2]f64{ .{ 0, 0 }, .{ 100, 100 }, .{ -500, -535 }, .{ 200, -300 }, .{ -200, 400 }, .{ 600, 100 }, .{ 300, 300 }, .{ -400, -400 }, .{ 700, -200 }, .{ -100, 800 } };
        std.debug.print("x y moisture aux elevation\n", .{});
        for (pts) |p| {
            std.debug.print("{d:.0} {d:.0} {d:.5} {d:.5} {d:.3}\n", .{ p[0], p[1], zt.moisture(p[0], p[1]), zt.aux(p[0], p[1]), el.at(p[0], p[1]) });
        }
        return;
    }

    if (probe) {
        // Decompose iron-ore value along y=-535, x in [-525,-475].
        const e = entries(false)[0]; // iron-ore
        var st = se.makeResourceState(a, HORAERRATUM_SEED, e.name, e.cfg, e.ctrl);
        defer st.spot.deinit();
        const yq: f64 = -535;
        std.debug.print("x spot_v blobs0 basis64 vein_raw blob amp value\n", .{});
        var xq: f64 = -525;
        while (xq <= -475) : (xq += 1) {
            const p = try se.probeAt(&st, xq, yq);
            std.debug.print("{d:.0} {d:.1} {d:.3} {d:.3} {d:.3} {d:.3} {d:.1} {d:.1}\n", .{ xq, p.spot_v, p.blobs0, p.basis64, p.vein_raw, p.blob, p.amp, p.value });
        }
        return;
    }

    const es = entries(k2_enable);
    // --ores-only: skip fluid resources (random_probability < 1: crude-oil,
    // kr-mineral-water, kr-imersite) — they don't affect solid ore placement
    // (separate order groups, lower probability) and cost a penalty column +
    // extra field evaluations per chunk. Fast path for ore-quantity surveys.
    var inputs_buf: [RESOURCE_ENTRIES.len]se.ResourceInput = undefined;
    var ninputs: usize = 0;
    for (es) |e| {
        if (ores_only and e.cfg.random_probability < 1.0) continue;
        inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = e.ctrl };
        ninputs += 1;
    }
    const inputs = inputs_buf[0..ninputs];

    if (zones_file) |zf| {
        const ws = world_seed orelse {
            std.debug.print("--zones requires --world-seed\n", .{});
            return;
        };
        try runZoneDriver(a, init, zf, ws, zone_names, out_dir, ores_only, bmp_filename != null);
        return;
    }

    const r: i32 = if (override_radius) |or2| or2 else @intFromFloat(HORAERRATUM_RADIUS);
    const zone_r: f64 = if (override_radius) |or2| @floatFromInt(or2) else HORAERRATUM_RADIUS;
    std.debug.print("# SE zone Horaerratum (world 57374), map_seed={d}, radius={d}, sample={d}\n", .{ HORAERRATUM_SEED, r, sample_step });

    // --field-probe <resource> <in> <out>: raw all_patches at "x y" lines, for
    // oracle comparison vs the live game (probe_live.py, default-<res>-patches).
    if (field_probe_res) |rname| {
        const raw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, field_probe_in.?, a, .unlimited);
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
        var entry: ?Entry = null;
        for (es) |e| {
            if (std.mem.eql(u8, e.name, rname)) entry = e;
        }
        const e = entry orelse {
            std.debug.print("unknown resource {s}\n", .{rname});
            return;
        };
        const elev_p = surfacegen.terrain.Elevation.init(HORAERRATUM_SEED, 1.0, 1.42);
        const vals = try a.alloc(f64, xs.items.len);
        const use_ctrl = ctrl_override orelse e.ctrl;
        try se.probeSEAllPatches(a, HORAERRATUM_SEED, e.name, e.cfg, use_ctrl, &elev_p, xs.items, ys.items, vals);
        var buf: std.ArrayList(u8) = .empty;
        for (vals) |v| {
            var line: [64]u8 = undefined;
            const sl = try std.fmt.bufPrint(&line, "{d:.9}\n", .{v});
            try buf.appendSlice(a, sl);
        }
        const file = try std.Io.Dir.createFile(.cwd(), init.io, field_probe_out.?, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, buf.items, 0);
        std.debug.print("# Probed {d} -> {s}\n", .{ vals.len, field_probe_out.? });
        return;
    }

    if (spot_stats) {
        // Just print spot-level statistics without tile evaluation.
        for (es) |e| {
            var st = se.makeResourceState(a, HORAERRATUM_SEED, e.name, e.cfg, e.ctrl);
            defer st.spot.deinit();
            // Count spots in the relevant regions.
            const rsize: i32 = @intFromFloat(se.SE_REGION_SIZE);
            const rmin: i32 = @divTrunc(-r - @as(i32, @intFromFloat(se.SE_MAX_BASEMENT_RADIUS)), rsize);
            const rmax: i32 = @divTrunc(r + @as(i32, @intFromFloat(se.SE_MAX_BASEMENT_RADIUS)), rsize);
            var total_spots: u32 = 0;
            var total_q: f64 = 0;
            var rx: i32 = rmin;
            while (rx <= rmax) : (rx += 1) {
                var ry: i32 = rmin;
                while (ry <= rmax) : (ry += 1) {
                    const spots = try st.spot.spotsForRegion(rx, ry);
                    for (spots) |s| {
                        // Dump the actual spot centers for the central region so
                        // they can be diffed against the game's patch centroids.
                        if (rx == 0 and ry == 0) {
                            const rad = if (s.slope != 0) s.peak / s.slope else 0;
                            std.debug.print("SPOT {s} {d:.2} {d:.2} r={d:.2} peak={d:.1}\n", .{ e.name, s.x, s.y, rad, s.peak });
                        }
                        if (s.x * s.x + s.y * s.y <= zone_r * zone_r) {
                            total_spots += 1;
                            total_q += (std.math.pi * s.slope * s.peak * s.peak) / 3.0;
                        }
                    }
                }
            }
            std.debug.print("  {s}: spots={d} total_q={d:.1} density={d:.4} qbase={d:.1} rq={d:.4} blob_amp={d:.5}\n",
                .{ e.name, total_spots, total_q, st.density, st.quantity_base, st.rq, st.blob_amplitude });
        }
        return;
    }

    const elev = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, surfacegen.terrain.HORAERRATUM.water_frequency, surfacegen.terrain.HORAERRATUM.water_size);
    const zt_gate = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
    const classifier_gate = surfacegen.biome.Classifier.init(surfacegen.terrain.HORAERRATUM.map_seed);
    // `--water` turns on terrain gating: exclude ore on water and restrict
    // se-vulcanite/cryonite/vitamelange to their biome tiles. Terrain is only
    // evaluated where an ore candidate exists (ore is sparse).
    const water_pred: ?*const surfacegen.terrain.Elevation = if (water_exclude) &elev else null;
    const zt_ptr: ?*const surfacegen.terrain.ZoneTerrain = if (water_exclude) &zt_gate else null;
    const cls_ptr: ?*const surfacegen.biome.Classifier = if (water_exclude) &classifier_gate else null;
    var ores = try se.computeSEOresInRect(a, HORAERRATUM_SEED, zone_r, -r, -r, r, r, inputs, sample_step, water_pred, zt_ptr, cls_ptr);
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
        @memset(pixels, 20); // background — matches ore-counter dump
        if (biome_bg) {
            // Fill each disk tile with its simplified biome-category color so the
            // ore patches show which terrain they sit on. Same orientation as ore.
            var iy: i32 = -r;
            while (iy < r) : (iy += 1) {
                var ix: i32 = -r;
                while (ix < r) : (ix += 1) {
                    const bx: f64 = @floatFromInt(ix);
                    const by: f64 = @floatFromInt(iy);
                    if (bx * bx + by * by > zone_r * zone_r) continue;
                    const e = elev.at(bx, by);
                    const color: [3]u8 = if (e < 0.0)
                        surfacegen.biome.CatBg.water
                    else
                        surfacegen.biome.categoryBg(classifier_gate.classifyIndex(bx, by, zt_gate.temperature(bx, by), zt_gate.moisture(bx, by), zt_gate.aux(bx, by), e));
                    const bpx: usize = @intCast(ix + r);
                    const bpy: usize = @intCast((r - 1) - iy);
                    const bidx: usize = (bpy * size + bpx) * 3;
                    pixels[bidx] = color[0];
                    pixels[bidx + 1] = color[1];
                    pixels[bidx + 2] = color[2];
                }
            }
        }
        for (ores.items) |ore| {
            const px: i32 = ore.x + r;
            // Orientation matches the ore-counter / tile-dump BMP after bmp2png.
            const py: i32 = (r - 1) - ore.y;
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
