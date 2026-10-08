const std = @import("std");
const surfacegen = @import("surface_generator");
const se = surfacegen.se_ore;
const universe = @import("universe_gen");
// Shared calibration (resource configs, map colors, FSR overrides) — the same
// data the browser surface generator (se_wasm.zig → surface.wasm) uses, so the
// two never diverge. Exposed through the surface_generator module (root.zig).
const res = surfacegen.se_resources;

// When set (via --gpu-ore-dump <path>), the ore pass serializes the per-resource
// params + precomputed spots for gpu_ore instead of computing ore on the CPU.
var g_gpu_ore_dump: ?[]const u8 = null;

// --zone-field-probe <points> <out>: for each zone resource, evaluate the RAW
// all_patches noise value (pre-thinning) at the "x y" points in <points> and
// write JSONL {"n":res,"x":x,"y":y,"v":value} to <out>. Uses the zone's real
// seed + computed controls — the dynamic equivalent of the game's
// calculate_tile_properties('default-<res>-patches') oracle, so we can compare
// the value FIELD (not just placed entities) against the live game.
var g_field_probe_pts: ?[]const u8 = null;
var g_field_probe_out: ?[]const u8 = null;

/// Factorio/SE/K2 map colors (RGB), matching the ground-truth renderer
/// calibration/mod-dump/convert_jsonl.py so generated images are directly
/// comparable to Horaerratum.png. Unknown -> grey; se-core-fragment-* inherits
/// its base resource's color.
const MapColors = res.MapColors;

// ---- Horaerratum target (world 57374), non-K2 resources ----
// Resource configs/controls live in se_resources.zig (shared with the browser
// WASM surface generator); Horaerratum itself is the native test-bench target.
const HORAERRATUM_SEED: u32 = 2035207183;
const HORAERRATUM_RADIUS: f64 = 1041.0;

const Entry = res.Entry;
const entries = res.entries;
const RESOURCE_ENTRIES = res.RESOURCE_ENTRIES;
const N_BASE_RESOURCES = res.N_BASE_RESOURCES;
const staticResName = res.staticResName;
const fsrOverride = res.fsrOverride;

// ── Compact ore.jsonl parsing (for --load-ore) ──────────────────────────
// Lines are exactly {"x":<int>,"y":<int>,"n":"<name>","a":<uint>}.

/// Integer that follows `key` (e.g. "\"x\":") in a compact JSON line.
fn intAfter(line: []const u8, key: []const u8) ?i64 {
    const idx = std.mem.indexOf(u8, line, key) orelse return null;
    var p = idx + key.len;
    var neg = false;
    if (p < line.len and line[p] == '-') {
        neg = true;
        p += 1;
    }
    var v: i64 = 0;
    var any = false;
    while (p < line.len and line[p] >= '0' and line[p] <= '9') : (p += 1) {
        v = v * 10 + @as(i64, line[p] - '0');
        any = true;
    }
    if (!any) return null;
    return if (neg) -v else v;
}

/// Quoted string right after `key` (key ends with the opening quote, e.g. "\"n\":\"").
fn strAfter(line: []const u8, key: []const u8) ?[]const u8 {
    const idx = std.mem.indexOf(u8, line, key) orelse return null;
    const start = idx + key.len;
    const rel = std.mem.indexOfScalar(u8, line[start..], '"') orelse return null;
    return line[start .. start + rel];
}

/// Map a parsed resource name to the static RESOURCE_ENTRIES slice (stable
/// lifetime, and matches MapColors), or null if unknown. (definition in
/// se_resources.zig, shared with the browser WASM surface generator)

/// Zone driver: read a seeds jsonl (universe summary), pick a world by seed and
/// zones by name, compute each zone's surface autoplace controls via the
/// universe generator port, generate ore, and write results into
/// <out>/<world_seed>/<zone_name>/ore.jsonl (+ ore.bmp with --bmp).
/// Encode an RGB pixel buffer to PNG (via zigimg) and write it to `path`.
/// Replaces the old write-BMP-then-convert-with-python flow.
fn writePngFile(a: std.mem.Allocator, io: std.Io, path: []const u8, w: u32, h: u32, pixels: []const u8) !void {
    const bytes = try surfacegen.png.encode(a, w, h, pixels);
    defer a.free(bytes);
    const file = try std.Io.Dir.createFile(.cwd(), io, path, .{});
    defer file.close(io);
    try file.writePositionalAll(io, bytes, 0);
}

/// Same as writePngFile but for an RGBA buffer (transparent-background overlays).
fn writePngFileRgba(a: std.mem.Allocator, io: std.Io, path: []const u8, w: u32, h: u32, rgba: []const u8) !void {
    const bytes = try surfacegen.png.encodeRgba(a, w, h, rgba);
    defer a.free(bytes);
    const file = try std.Io.Dir.createFile(.cwd(), io, path, .{});
    defer file.close(io);
    try file.writePositionalAll(io, bytes, 0);
}

/// Write a tiled-surface cell as PNG. Rows are emitted top-down (row 0 = the
/// cell's north edge, tile y0), i.e. north-up — matching the game's map view.
/// The GUI/job-manager stitches the cells into a single north-up image. The
/// `oremap` layer becomes RGBA with its black background keyed transparent, so
/// it overlays terrain.
fn writeCellPng(a: std.mem.Allocator, io: std.Io, path: []const u8, w: u32, h: u32, rgb: []const u8, oremap: bool) !void {
    const wu: usize = w;
    const hu: usize = h;
    if (oremap) {
        const rgba = try a.alloc(u8, wu * hu * 4);
        defer a.free(rgba);
        for (0..hu) |y| {
            for (0..wu) |x| {
                const s = (y * wu + x) * 3;
                const d = (y * wu + x) * 4;
                const rr = rgb[s];
                const gg = rgb[s + 1];
                const bb = rgb[s + 2];
                rgba[d] = rr;
                rgba[d + 1] = gg;
                rgba[d + 2] = bb;
                rgba[d + 3] = if (rr == 0 and gg == 0 and bb == 0) 0 else 255;
            }
        }
        try writePngFileRgba(a, io, path, w, h, rgba);
    } else {
        // RGB rows already in north-up order — write straight through.
        try writePngFile(a, io, path, w, h, rgb);
    }
}

fn runZoneDriver(
    a: std.mem.Allocator,
    init: std.process.Init,
    zones_path: []const u8,
    world_seed: u64,
    zone_csv: ?[]const u8,
    out_dir: []const u8,
    ores_only: bool,
    write_bmp: bool,
    render_surface: bool,
    surface_grid: i32, // NxN grid the surface is split into (1 = whole)
    surface_cell: i32, // which cell (0..grid*grid-1) to render; -1 = all cells
    load_ore: bool, // read ore.jsonl instead of computing (per-cell renders)
    surface_layer: i32, // 0 = both (surface_), 1 = terrain only, 2 = ore only
    override_radius: ?i32, // cap the render/ore rect to this half-extent (null = full disk)
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
        if (ztype != .planet and ztype != .moon and ztype != .@"asteroid-field") {
            std.debug.print("zone {s}: type {s} not surface-generatable, skipping\n", .{ name, ztype_str });
            continue;
        }
        const is_field = ztype == .@"asteroid-field";
        const zone_seed: u32 = @intCast((z.get("s") orelse continue).integer);
        // Asteroid fields carry no radius in the universe data; SE places their
        // resources against the field's effective radius (gen.FIELD_EFFECTIVE_RADIUS).
        const radius: f64 = blk: {
            if (z.get("r")) |rv| {
                switch (rv) {
                    .integer => |v| break :blk @floatFromInt(v),
                    .float => |v| break :blk v,
                    else => {},
                }
            }
            if (is_field) break :blk 5000.0;
            continue;
        };
        const primary: ?[]const u8 = if (z.get("p")) |pv| (if (pv == .string) pv.string else null) else null;

        // Synthetic Nauvis entry (GUI writeSeedZonesFile): the home planet is
        // generated with the GAME's default map-gen settings, not SE zone
        // controls — vanilla autoplace at default freq/size/richness, map seed =
        // world seed, default water (size 1.0, not the SE-calibrated 1.5). The
        // entry carries temperature "balanced" (cold/hot 1/1 = the vanilla
        // default) and r=5000 so the SE frequency multiplier (5000/r) is 1.
        const is_nauvis = if (z.get("nauvis")) |v| (v == .bool and v.bool) else false;

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
        // build resource inputs: our config table + the zone's controls.
        var inputs_buf: [RESOURCE_ENTRIES.len]se.ResourceInput = undefined;
        var ninputs: usize = 0;
        if (is_nauvis) {
            // Nauvis under SE: SE's data stage re-derives EVERY base ore with the
            // SE autoplace function (verified in-game — the field matches SE, not
            // vanilla). So the home planet uses the SE spot-noise path too, over
            // just the base ores (iron/copper/coal/stone/uranium — no SE space
            // resources on Nauvis), with the base-game DEFAULT 1/1/1 controls (not
            // universe zone controls). r=5000 makes the SE frequency multiplier 1.
            const nauvis_ores = [_][]const u8{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore" };
            for (RESOURCE_ENTRIES) |e| {
                var is_base = false;
                for (nauvis_ores) |nm| {
                    if (std.mem.eql(u8, e.name, nm)) {
                        is_base = true;
                        break;
                    }
                }
                // Under K2, Nauvis also carries rare-metal-ore (default 1/1/1
                // controls, like the base ores). K2's other Nauvis addition,
                // mineral-water, is a FLUID — the solid-ore path doesn't place it.
                if (has_k2 and std.mem.eql(u8, e.name, "kr-rare-metal-ore")) is_base = true;
                if (!is_base) continue;
                if (ores_only and e.cfg.random_probability < 1.0) continue;
                var ctrl = se.Controls{ .frequency = 1.0, .size = 1.0, .richness = 1.0 };
                if (fsrOverride(z, e.name)) |ov| ctrl = .{ .frequency = ov[0], .size = ov[1], .richness = ov[2] };
                inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = ctrl };
                ninputs += 1;
            }
        } else {
            const controls = universe.computeZoneMapgenControls(zone_seed, ztype, primary, tags, radius, false);
            for (universe.resource_order, 0..) |rn, ri| {
                const c = controls[ri];
                if (c.present) std.debug.print("   ctrl {s}: f={d:.4} s={d:.4} r={d:.4}\n", .{ rn, c.frequency, c.size, c.richness });
            }
            for (RESOURCE_ENTRIES) |e| {
                if (!has_k2 and std.mem.startsWith(u8, e.name, "kr-")) continue;
                // K2 resources carry SE field controls (kr-rare-metal-ore can even be
                // a field's boosted PRIMARY) but K2 never places them in space — the
                // live game has 0 kr-* entities on asteroid fields. Skip them there.
                if (is_field and std.mem.startsWith(u8, e.name, "kr-")) continue;
                if (ores_only and e.cfg.random_probability < 1.0) continue;
                var ctrl = se.Controls{ .frequency = 0, .size = 0, .richness = 0 };
                for (universe.resource_order, 0..) |rn, ri| {
                    if (std.mem.eql(u8, rn, e.name)) {
                        const c = controls[ri];
                        if (c.present) ctrl = .{ .frequency = c.frequency, .size = c.size, .richness = c.richness };
                        break;
                    }
                }
                // FSR test-bench override: if the zone entry pins this resource's
                // freq/size/richness, use it verbatim (so a size the universe left
                // at 0 can be dialed in from the GUI).
                if (fsrOverride(z, e.name)) |ov| ctrl = .{ .frequency = ov[0], .size = ov[1], .richness = ov[2] };
                if (ctrl.size <= 0) continue;
                inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = ctrl };
                ninputs += 1;
            }
        }
        const inputs = inputs_buf[0..ninputs];

        // terrain: water tag "none" => no water gate; otherwise approximate the
        // SE water control (freq 1, size 1.5 — the calibrated Horaerratum point).
        // Nauvis always has water at the game DEFAULT size 1.0.
        const has_water = if (is_nauvis) true else if (tags.water) |wt| wt != .none else false;
        const water_size: f64 = if (is_nauvis) 1.0 else 1.5;
        var elev: ?surfacegen.terrain.Elevation = null;
        var zt: ?surfacegen.terrain.ZoneTerrain = null;
        var classifier: ?surfacegen.biome.Classifier = null;
        if (has_water) elev = surfacegen.terrain.Elevation.init(zone_seed, 1.0, water_size);
        // Nauvis (base + SE configs) has the engine's starting-area lake.
        if (is_nauvis) {
            const lake = surfacegen.terrain.startingLakeCenter(zone_seed);
            if (elev) |*e| e.addStartingLake(lake[0], lake[1]);
        }

        // --zone-field-probe: raw all_patches value per resource at the given points
        // (the value-field oracle vs the game's calculate_tile_properties). Uses the
        // zone's real seed + the controls built above (SE path only; not Nauvis).
        if (g_field_probe_out) |probe_out| {
            const praw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, g_field_probe_pts.?, a, .unlimited);
            var xs: std.ArrayList(f64) = .empty;
            var ys: std.ArrayList(f64) = .empty;
            var lit = std.mem.tokenizeAny(u8, praw, "\r\n");
            while (lit.next()) |ln| {
                var ft = std.mem.tokenizeAny(u8, ln, " \t,");
                const sx = ft.next() orelse continue;
                const sy = ft.next() orelse continue;
                try xs.append(a, try std.fmt.parseFloat(f64, sx));
                try ys.append(a, try std.fmt.parseFloat(f64, sy));
            }
            var buf: std.ArrayList(u8) = .empty;
            const vals = try a.alloc(f64, xs.items.len);
            const emit = struct {
                fn f(bf: *std.ArrayList(u8), al: std.mem.Allocator, nm: []const u8, xa: []const f64, ya: []const f64, va: []const f64) !void {
                    for (xa, ya, va) |px, py, v| {
                        var line: [128]u8 = undefined;
                        const sl = try std.fmt.bufPrint(&line, "{{\"n\":\"{s}\",\"x\":{d:.0},\"y\":{d:.0},\"v\":{d:.9}}}\n", .{ nm, px, py, v });
                        try bf.appendSlice(al, sl);
                    }
                }
            }.f;
            // SE all_patches field per input resource (Nauvis included now — its
            // base ores use the SE path, so `inputs` carries them).
            const elevptr: ?*const surfacegen.terrain.Elevation = if (elev) |*e| e else null;
            for (inputs) |inp| {
                try se.probeSEAllPatches(a, zone_seed, inp.name, inp.config, inp.controls, elevptr, xs.items, ys.items, vals);
                try emit(&buf, a, inp.name, xs.items, ys.items, vals);
            }
            const f = try std.Io.Dir.createFile(.cwd(), init.io, probe_out, .{});
            defer f.close(init.io);
            try f.writePositionalAll(init.io, buf.items, 0);
            std.debug.print("wrote zone-field-probe {s} ({d} points)\n", .{ probe_out, xs.items.len });
            continue;
        }
        const fm = universe.zoneFrequencyMultiplier(radius);
        // Per-zone temperature control from the SE tag (verified vs the game:
        // midrange→0.65, extreme→6). Was hardcoded to Horaerratum's 6.0, which
        // pushed every non-extreme zone into hot/cold biome extremes. Moisture/
        // aux stay at freq 1 / bias 0: the SE tag bias re-centers to ~0 in the
        // alien-biomes noise var, so those properties match the game as-is (the
        // remaining biome gap is classifier range calibration, not properties).
        const tc = (tags.temperature orelse universe.data.Temperature.midrange).controlSettings();
        zt = surfacegen.terrain.ZoneTerrain.init(.{
            .map_seed = zone_seed,
            .moisture_frequency = 1.0,
            .moisture_bias = 0.0,
            .aux_frequency = 1.0,
            .aux_bias = 0.0,
            .cold_size = tc.cold_size,
            .hot_size = tc.hot_size,
            .cold_frequency = tc.cold_freq * fm,
            .hot_frequency = tc.hot_freq * fm,
            .water_frequency = 1.0,
            .water_size = if (has_water) water_size else 0.0,
        });
        classifier = surfacegen.biome.Classifier.init(zone_seed);

        // The render/ore RECT half-extent. --radius caps it (so we can generate
        // just the inner disk) while `radius` above stays the zone's true radius
        // for the resource-control + frequency math.
        const r: i32 = if (override_radius) |o| o else @intFromFloat(radius);

        // Output dir up-front so --load-ore can read ore.jsonl from it.
        var dirbuf: [512]u8 = undefined;
        const zdir = try std.fmt.bufPrint(&dirbuf, "{s}/seed_{d}/{s}", .{ out_dir, world_seed, name });
        try std.Io.Dir.createDirPath(.cwd(), init.io, zdir);

        var ores: std.ArrayList(se.OreEntity) = .empty;
        defer ores.deinit(a);

        // terrain-only renders don't touch ore at all (no compute, no load, no
        // ore.jsonl/summary write); ore + combined layers do.
        const need_ores = surface_layer != 1;

        if (need_ores and load_ore) {
            // Read the ore overlay from a prior zone-wide pass instead of
            // recomputing it (the expensive step). Keep only entities inside the
            // target cell (or the whole disk when rendering all cells).
            var lx0: i32 = -r;
            var ly0: i32 = -r;
            var lx1: i32 = r;
            var ly1: i32 = r;
            if (surface_cell >= 0 and surface_grid > 1) {
                const grid = surface_grid;
                const full = r * 2;
                const cw2 = @divTrunc(full + grid - 1, grid);
                const gx = @mod(surface_cell, grid);
                const gy = @divTrunc(surface_cell, grid);
                lx0 = -r + gx * cw2;
                lx1 = @min(r, lx0 + cw2);
                ly0 = -r + gy * cw2;
                ly1 = @min(r, ly0 + cw2);
            }
            var opbuf: [512]u8 = undefined;
            const opath = try std.fmt.bufPrint(&opbuf, "{s}/ore.jsonl", .{zdir});
            const oraw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, opath, a, .unlimited);
            defer a.free(oraw);
            var olines = std.mem.tokenizeAny(u8, oraw, "\r\n");
            while (olines.next()) |ln| {
                if (ln.len == 0) continue;
                const ox = intAfter(ln, "\"x\":") orelse continue;
                const oy = intAfter(ln, "\"y\":") orelse continue;
                if (ox < lx0 or ox >= lx1 or oy < ly0 or oy >= ly1) continue;
                const onm = strAfter(ln, "\"n\":\"") orelse continue;
                const sname = staticResName(onm) orelse continue;
                const oa = intAfter(ln, "\"a\":") orelse 0;
                try ores.append(a, .{ .x = @intCast(ox), .y = @intCast(oy), .resource_name = sname, .amount = @intCast(oa) });
            }
            std.debug.print("== zone {s}: loaded {d} cached ore entities (cell {d}/{d})\n", .{ name, ores.items.len, surface_cell, surface_grid * surface_grid });
        } else if (g_gpu_ore_dump) |dp| {
            // GPU ore path: serialize per-resource params + spots for gpu_ore
            // (which does the per-tile eval on the GPU) instead of computing here.
            // Nauvis uses the SE inputs built above (SE autoplace on the base ores),
            // exactly like every other zone.
            const bytes = try se.serializeGpuInput(a, zone_seed, radius, -r, -r, r, r, inputs, is_field);
            defer a.free(bytes);
            const f = try std.Io.Dir.createFile(.cwd(), init.io, dp, .{});
            defer f.close(init.io);
            try f.writePositionalAll(init.io, bytes, 0);
            std.debug.print("wrote gpu-ore-dump {s} ({d} bytes)\n", .{ dp, bytes.len });
            continue;
        } else if (need_ores) {
            // Every generatable zone — including Nauvis (whose base ores now use SE
            // autoplace, matching the live game) — runs the SE spot-noise path.
            std.debug.print("== zone {s} (seed {d}, r {d}, {d} resources)\n", .{ name, zone_seed, r, ninputs });
            ores = try se.computeSEOresInRect(
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

            // Asteroid fields place resources only on se-asteroid tiles (verified
            // vs the game: SE ices are 100% on-asteroid, base ores ~72-86%). The
            // ore pass runs over the whole disk, so drop everything that landed on
            // space. Cheap: filter the entity list in place.
            if (is_field) {
                const field = surfacegen.asteroid.AsteroidField.initField(zone_seed);
                var kept: usize = 0;
                for (ores.items) |oe| {
                    if (field.tileAt(@floatFromInt(oe.x), @floatFromInt(oe.y)) == .asteroid) {
                        ores.items[kept] = oe;
                        kept += 1;
                    }
                }
                const dropped = ores.items.len - kept;
                ores.shrinkRetainingCapacity(kept);
                std.debug.print("   asteroid mask: kept {d} on-asteroid ore, dropped {d} on space\n", .{ kept, dropped });
            }

            // per-resource ORE totals + ore.jsonl + summary.json. Skipped under
            // --load-ore: those files already exist from the zone-wide pass.
            var summary: std.ArrayList(u8) = .empty;
            try summary.appendSlice(a, "{");
            try appendFmt(a, &summary, "\"zone\":\"{s}\",\"zone_seed\":{d},\"radius\":{d},\"resources\":{{", .{ name, zone_seed, r });
            {
                // Names to total: the zone's SE inputs (Nauvis included now).
                var sum_names: [RESOURCE_ENTRIES.len][]const u8 = undefined;
                var nsum: usize = 0;
                for (inputs) |inp| {
                    sum_names[nsum] = inp.name;
                    nsum += 1;
                }
                var first = true;
                for (sum_names[0..nsum]) |rname| {
                    var cnt: u64 = 0;
                    var amount: u64 = 0;
                    for (ores.items) |o| {
                        if (std.mem.eql(u8, o.resource_name, rname)) {
                            cnt += 1;
                            amount += o.amount;
                        }
                    }
                    if (cnt == 0) continue;
                    var abuf: [32]u8 = undefined;
                    const disp = fmtAmount(&abuf, amount);
                    std.debug.print("   {s}: {s} ore ({d} tiles)\n", .{ rname, disp, cnt });
                    if (!first) try summary.appendSlice(a, ",");
                    first = false;
                    try appendFmt(a, &summary, "\"{s}\":{{\"amount\":{d},\"display\":\"{s}\",\"tiles\":{d}}}", .{ rname, amount, disp, cnt });
                }
            }
            try summary.appendSlice(a, "}}");

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
            {
                var spathbuf: [512]u8 = undefined;
                const spath = try std.fmt.bufPrint(&spathbuf, "{s}/summary.json", .{zdir});
                const sfile = try std.Io.Dir.createFile(.cwd(), init.io, spath, .{});
                defer sfile.close(init.io);
                try sfile.writePositionalAll(init.io, summary.items, 0);
            }
        }

        if (write_bmp and !load_ore) {
            var bpathbuf: [512]u8 = undefined;
            const bpath = try std.fmt.bufPrint(&bpathbuf, "{s}/ore.png", .{zdir});
            const size: u32 = @intCast(r * 2);
            // RGBA with a transparent background so the ore map overlays terrain:
            // ore pixels are opaque, everything else is fully transparent.
            var pixels = try a.alloc(u8, @as(usize, size) * size * 4);
            defer a.free(pixels);
            @memset(pixels, 0);
            for (ores.items) |ore| {
                const px: i64 = @as(i64, ore.x) + r;
                const py: i64 = @as(i64, ore.y) + r;
                if (px < 0 or py < 0 or px >= size or py >= size) continue;
                const color = MapColors.get(ore.resource_name);
                const idx: usize = (@as(usize, @intCast(py)) * size + @as(usize, @intCast(px))) * 4;
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
                pixels[idx + 3] = 255;
            }
            try writePngFileRgba(a, init.io, bpath, size, size, pixels);
            std.debug.print("   wrote {s}\n", .{bpath});
        }

        // Full-resolution SURFACE render (biome tile + water, ore overlaid),
        // TILED: the 2r×2r bounds split into a `grid`×`grid` set of cells; each
        // cell is a separate region image so the work parallelizes across jobs
        // and cells fully outside the disk are skipped entirely. Cell (gx,gy)
        // spans tiles [x0,x1)×[y0,y1); rendered top-down (row 0 = y0) into
        // surface_<grid>_<cell>.bmp; the stitcher composes + flips to north-up.
        if (render_surface) {
            const grid: i32 = if (surface_grid > 0) surface_grid else 1;
            const full: i32 = r * 2;
            const cellW: i32 = @divTrunc(full + grid - 1, grid); // ceil
            var el_s = surfacegen.terrain.Elevation.init(zone_seed, 1.0, if (has_water) water_size else 1.0);
            if (is_nauvis) {
                const lake = surfacegen.terrain.startingLakeCenter(zone_seed);
                el_s.addStartingLake(lake[0], lake[1]);
            }
            const zt_s = zt.?;
            const cls_s = classifier.?;

            var cell: i32 = if (surface_cell >= 0) surface_cell else 0;
            const cell_hi: i32 = if (surface_cell >= 0) surface_cell + 1 else grid * grid;
            while (cell < cell_hi) : (cell += 1) {
                const gx = @mod(cell, grid);
                const gy = @divTrunc(cell, grid);
                const x0 = -r + gx * cellW;
                const x1 = @min(r, x0 + cellW);
                const y0 = -r + gy * cellW;
                const y1 = @min(r, y0 + cellW);
                if (x1 <= x0 or y1 <= y0) continue;
                // Skip cells fully outside the disk: nearest rect point to origin.
                const nx: f64 = @floatFromInt(@max(x0, @min(0, x1 - 1)));
                const ny: f64 = @floatFromInt(@max(y0, @min(0, y1 - 1)));
                if (nx * nx + ny * ny > radius * radius) {
                    std.debug.print("   surface cell {d}/{d} outside disk — skipped\n", .{ cell, grid * grid });
                    continue;
                }
                const cw: u32 = @intCast(x1 - x0);
                const ch: u32 = @intCast(y1 - y0);
                var pixels = try a.alloc(u8, @as(usize, cw) * ch * 3);
                defer a.free(pixels);
                // ore-only layer is on a black background so it composites over
                // the dimmed terrain (CSS lighten blend); others use dark grey.
                @memset(pixels, if (surface_layer == 2) @as(u8, 0) else @as(u8, 20));
                // biome + water fill (skip for the ore-only layer)
                if (surface_layer != 2) {
                    var iy: i32 = y0;
                    while (iy < y1) : (iy += 1) {
                        var ix: i32 = x0;
                        while (ix < x1) : (ix += 1) {
                            const fx: f64 = @floatFromInt(ix);
                            const fy: f64 = @floatFromInt(iy);
                            if (fx * fx + fy * fy > radius * radius) continue;
                            const e = if (has_water) el_s.at(fx, fy) else 1.0;
                            const color: [3]u8 = if (has_water and e < 0.0)
                                (if (e < -5.0) surfacegen.biome.deepwater else surfacegen.biome.water)
                            else
                                cls_s.classifyColor(fx, fy, zt_s.temperature(fx, fy), zt_s.moisture(fx, fy), zt_s.aux(fx, fy), e);
                            const lpx: usize = @intCast(ix - x0);
                            const lpy: usize = @intCast(iy - y0);
                            const idx = (lpy * cw + lpx) * 3;
                            pixels[idx] = color[0];
                            pixels[idx + 1] = color[1];
                            pixels[idx + 2] = color[2];
                        }
                    }
                }
                // ore overlay for tiles in this cell (skip for terrain-only)
                if (surface_layer != 1) {
                    for (ores.items) |ore| {
                        if (ore.x < x0 or ore.x >= x1 or ore.y < y0 or ore.y >= y1) continue;
                        const lpx: usize = @intCast(ore.x - x0);
                        const lpy: usize = @intCast(ore.y - y0);
                        const oc = MapColors.get(ore.resource_name);
                        const idx = (lpy * cw + lpx) * 3;
                        pixels[idx] = oc[0];
                        pixels[idx + 1] = oc[1];
                        pixels[idx + 2] = oc[2];
                    }
                }
                const prefix: []const u8 = switch (surface_layer) {
                    1 => "terrain",
                    2 => "oremap",
                    else => "surface",
                };
                var spb: [512]u8 = undefined;
                const sp = if (grid == 1)
                    try std.fmt.bufPrint(&spb, "{s}/{s}.png", .{ zdir, prefix })
                else
                    try std.fmt.bufPrint(&spb, "{s}/{s}_{d}_{d}.png", .{ zdir, prefix, grid, cell });
                // PNG directly — the GUI composes cells in the browser (CSS grid),
                // so no BMP + python cell_png/stitch step. oremap → transparent.
                try writeCellPng(a, init.io, sp, cw, ch, pixels, surface_layer == 2);
                std.debug.print("   wrote {s} ({d}x{d})\n", .{ sp, cw, ch });
            }
        }
    }

    // world-level report: rebuilt from EVERY zone summary on disk (so partial
    // re-runs of single zones never lose previously generated zones).
    {
        var rbuf: [512]u8 = undefined;
        const rdir = try std.fmt.bufPrint(&rbuf, "{s}/seed_{d}", .{ out_dir, world_seed });
        std.Io.Dir.createDirPath(.cwd(), init.io, rdir) catch {};
        var out: std.ArrayList(u8) = .empty;
        try appendFmt(a, &out, "{{\"world_seed\":{d},\"zones\":[", .{world_seed});
        {
            var d = try std.Io.Dir.openDir(.cwd(), init.io, rdir, .{ .iterate = true });
            defer d.close(init.io);
            var it = d.iterate();
            var first = true;
            while (try it.next(init.io)) |entry| {
                if (entry.kind != .directory) continue;
                var spbuf: [512]u8 = undefined;
                const spath = try std.fmt.bufPrint(&spbuf, "{s}/{s}/summary.json", .{ rdir, entry.name });
                const content = std.Io.Dir.readFileAlloc(.cwd(), init.io, spath, a, .unlimited) catch continue;
                if (!first) try out.appendSlice(a, ",");
                first = false;
                try out.appendSlice(a, content);
            }
        }
        try out.appendSlice(a, "]}");
        var rpbuf: [512]u8 = undefined;
        const rpath = try std.fmt.bufPrint(&rpbuf, "{s}/report.json", .{rdir});
        const rfile = try std.Io.Dir.createFile(.cwd(), init.io, rpath, .{});
        defer rfile.close(init.io);
        try rfile.writePositionalAll(init.io, out.items, 0);
        std.debug.print("wrote {s}\n", .{rpath});
    }
}

/// Human-readable ore amount: >=1e9 -> "X.XXB", >=1e6 -> "X.XXM", else raw.
fn fmtAmount(buf: []u8, amount: u64) []const u8 {
    const f: f64 = @floatFromInt(amount);
    if (f >= 1e9) return std.fmt.bufPrint(buf, "{d:.2}B", .{f / 1e9}) catch "?";
    if (f >= 1e6) return std.fmt.bufPrint(buf, "{d:.2}M", .{f / 1e6}) catch "?";
    return std.fmt.bufPrint(buf, "{d}", .{amount}) catch "?";
}

fn appendFmt(a: std.mem.Allocator, list: *std.ArrayList(u8), comptime fmt: []const u8, args: anytype) !void {
    var buf: [1024]u8 = undefined;
    const sl = try std.fmt.bufPrint(&buf, fmt, args);
    try list.appendSlice(a, sl);
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
    var biome_probe: ?[]const u8 = null;
    var biome_names_pts: ?[]const u8 = null;
    var biome_names_out: ?[]const u8 = null;
    var biome_corrected: ?[]const u8 = null;
    var water_exclude: bool = false;
    var biome_bg: bool = false;
    var k2_enable: bool = false;
    var ores_only: bool = false;
    var zones_file: ?[]const u8 = null;
    var render_surface: bool = false;
    var surface_grid: i32 = 1;
    var surface_cell: i32 = -1;
    var load_ore: bool = false;
    var surface_layer: i32 = 0;
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
        } else if (std.mem.eql(u8, args[i], "--gpu-ore-dump")) {
            i += 1;
            if (i < args.len) g_gpu_ore_dump = args[i];
        } else if (std.mem.eql(u8, args[i], "--zone-field-probe")) {
            i += 1;
            if (i < args.len) g_field_probe_pts = args[i];
            i += 1;
            if (i < args.len) g_field_probe_out = args[i];
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
        } else if (std.mem.eql(u8, args[i], "--biome-probe")) {
            i += 1;
            if (i < args.len) biome_probe = args[i];
        } else if (std.mem.eql(u8, args[i], "--biome-names")) {
            i += 1;
            if (i < args.len) biome_names_pts = args[i];
            i += 1;
            if (i < args.len) biome_names_out = args[i];
        } else if (std.mem.eql(u8, args[i], "--biome-corrected")) {
            i += 1;
            if (i < args.len) biome_corrected = args[i];
        } else if (std.mem.eql(u8, args[i], "--biome-bg")) {
            biome_bg = true;
        } else if (std.mem.eql(u8, args[i], "--ores-only")) {
            ores_only = true;
        } else if (std.mem.eql(u8, args[i], "--render-surface")) {
            render_surface = true;
        } else if (std.mem.eql(u8, args[i], "--surface-grid")) {
            i += 1;
            surface_grid = try std.fmt.parseInt(i32, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "--surface-cell")) {
            i += 1;
            surface_cell = try std.fmt.parseInt(i32, args[i], 10);
            render_surface = true;
        } else if (std.mem.eql(u8, args[i], "--load-ore")) {
            // Skip the (expensive) zone-wide ore pass and read the ore overlay
            // from an already-written ore.jsonl. Used for per-cell surface jobs
            // so the ore pass runs once per zone, not once per cell.
            load_ore = true;
        } else if (std.mem.eql(u8, args[i], "--surface-layer")) {
            // terrain = biome+water only (dimmable), ore = ore patches on black
            // (composited over terrain), both = combined (legacy surface_).
            i += 1;
            surface_layer = if (std.mem.eql(u8, args[i], "terrain")) 1 else if (std.mem.eql(u8, args[i], "ore")) 2 else 0;
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

    if (biome_corrected) |bc| {
        // Full-disk classify → tile-correction pass → write "x,y,name". Replicates
        // Factorio's TileCorrectionMapGenerationTask: a higher-layer tile poking
        // into lower-layer neighbours without diagonal support is corrected down
        // (see se-biome-groundtruth memory + ghidra/export/tile_gen.c).
        const comma = std.mem.indexOfScalar(u8, bc, ',') orelse return;
        const r: i32 = try std.fmt.parseInt(i32, bc[0..comma], 10);
        const of = bc[comma + 1 ..];
        const zone_r: f64 = @floatFromInt(r);
        const zt = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
        const elev = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, surfacegen.terrain.HORAERRATUM.water_frequency, surfacegen.terrain.HORAERRATUM.water_size);
        const classifier = surfacegen.biome.Classifier.init(surfacegen.terrain.HORAERRATUM.map_seed);
        const size: usize = @intCast(r * 2);
        const grid = try a.alloc(u16, size * size);
        @memset(grid, surfacegen.biome.IDX_BG);
        // classify every in-disk tile → unified index
        var iy: i32 = -r;
        while (iy < r) : (iy += 1) {
            var ix: i32 = -r;
            while (ix < r) : (ix += 1) {
                const dx: f64 = @floatFromInt(ix);
                const dy: f64 = @floatFromInt(iy);
                if (dx * dx + dy * dy > zone_r * zone_r) continue;
                const gi: usize = @intCast((iy + r) * (r * 2) + (ix + r));
                grid[gi] = classifier.classifyIdx(dx, dy, zt.temperature(dx, dy), zt.moisture(dx, dy), zt.aux(dx, dy), elev.at(dx, dy));
            }
        }
        surfacegen.biome.correctTiles(a, grid, size);
        // write names
        var outbuf: std.ArrayList(u8) = .empty;
        iy = -r;
        while (iy < r) : (iy += 1) {
            var ix: i32 = -r;
            while (ix < r) : (ix += 1) {
                const gi: usize = @intCast((iy + r) * (r * 2) + (ix + r));
                if (grid[gi] == surfacegen.biome.IDX_BG) continue;
                try outbuf.appendSlice(a, try std.fmt.allocPrint(a, "{d},{d},{s}\n", .{ ix, iy, surfacegen.biome.idxName(grid[gi]) }));
            }
        }
        const file = try std.Io.Dir.createFile(.cwd(), init.io, of, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, outbuf.items, 0);
        std.debug.print("# Wrote {s} (corrected)\n", .{of});
        return;
    }

    if (biome_probe) |bp| {
        // Dump the fitness breakdown at one world point (Horaerratum config) so a
        // ground-truth disagreement can be traced to a specific term.
        const comma = std.mem.indexOfScalar(u8, bp, ',') orelse {
            std.debug.print("--biome-probe expects \"x,y\"\n", .{});
            return;
        };
        const px = try std.fmt.parseFloat(f64, bp[0..comma]);
        const py = try std.fmt.parseFloat(f64, bp[comma + 1 ..]);
        const zt = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
        const elev = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, surfacegen.terrain.HORAERRATUM.water_frequency, surfacegen.terrain.HORAERRATUM.water_size);
        const classifier = surfacegen.biome.Classifier.init(surfacegen.terrain.HORAERRATUM.map_seed);
        const t = zt.temperature(px, py);
        const m = zt.moisture(px, py);
        const av = zt.aux(px, py);
        const e = elev.at(px, py);
        std.debug.print("probe ({d},{d}): t={d:.4} m={d:.4} a={d:.4} e={d:.4}\n", .{ px, py, t, m, av, e });
        classifier.probe(px, py, t, m, av, e);
        return;
    }

    if (biome_names_pts) |pf| {
        // Classify a list of "x,y" points (Horaerratum config) and emit "x,y,name"
        // so placement can be diffed by TILE NAME against the live game oracle
        // (surface.get_tile) — colours collide, names don't.
        const zt = surfacegen.terrain.ZoneTerrain.init(surfacegen.terrain.HORAERRATUM);
        const elev = surfacegen.terrain.Elevation.init(surfacegen.terrain.HORAERRATUM.map_seed, surfacegen.terrain.HORAERRATUM.water_frequency, surfacegen.terrain.HORAERRATUM.water_size);
        const classifier = surfacegen.biome.Classifier.init(surfacegen.terrain.HORAERRATUM.map_seed);
        const raw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, pf, a, .unlimited);
        var outbuf: std.ArrayList(u8) = .empty;
        var lines = std.mem.tokenizeAny(u8, raw, "\r\n");
        while (lines.next()) |line| {
            const comma = std.mem.indexOfScalar(u8, line, ',') orelse continue;
            const px = std.fmt.parseFloat(f64, line[0..comma]) catch continue;
            const py = std.fmt.parseFloat(f64, line[comma + 1 ..]) catch continue;
            const e = elev.at(px, py);
            const name = classifier.classifyTile(px, py, zt.temperature(px, py), zt.moisture(px, py), zt.aux(px, py), e).name;
            try outbuf.appendSlice(a, try std.fmt.allocPrint(a, "{d},{d},{s}\n", .{ px, py, name }));
        }
        const of = biome_names_out orelse "biome-names-gen.csv";
        const file = try std.Io.Dir.createFile(.cwd(), init.io, of, .{});
        defer file.close(init.io);
        try file.writePositionalAll(init.io, outbuf.items, 0);
        std.debug.print("# Wrote {s}\n", .{of});
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
                const color: [3]u8 = classifier.classifyTile(fx, fy, zt.temperature(fx, fy), zt.moisture(fx, fy), zt.aux(fx, fy), e).color;
                // Orientation matches the tile-dump mod's BMP after bmp2png.
                const x_arr: usize = @intCast(ix + r);
                const y_arr: usize = @intCast((r - 1) - iy);
                const idx: usize = (y_arr * size + x_arr) * 3;
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
            }
        }
        const filename = bmp_filename orelse "horaerratum-biome.png";
        try writePngFile(a, init.io, filename, size, size, pixels);
        std.debug.print("# Wrote biome PNG: {s} ({d}x{d})\n", .{ filename, size, size });
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
        try runZoneDriver(a, init, zf, ws, zone_names, out_dir, ores_only, bmp_filename != null, render_surface, surface_grid, surface_cell, load_ore, surface_layer, override_radius);
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
