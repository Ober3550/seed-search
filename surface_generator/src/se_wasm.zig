// WebAssembly entry for the SE surface generator: generate one zone's surface
// (biome/terrain/water tiles + ore placement) entirely in the browser, so the
// "Analyze seed" page can render a zone's surface client-side with no backend.
//
// Reuses the SAME pure modules as the native segen CLI (se_ore_placement.zig,
// terrain.zig, biome.zig, asteroid.zig + universe gen.zig for the zone mapgen
// controls) and the SHARED calibration in se_resources.zig, so spot positions,
// amounts and colors are identical to a native `segen` run for the same zone /
// radius. Only the plumbing differs: the request arrives as JSON in linear
// memory instead of argv, and the output is an RGBA pixel buffer (+ ore summary
// JSON) instead of PNG files.
//
// Build (install.mjs): zig build-exe se_wasm.zig -target wasm32-freestanding
//   -O ReleaseFast -fno-entry -rdynamic -femit-bin=public/surface.wasm
//
// Request JSON (written into the exported input buffer):
//   { "seed": <world seed u32>,
//     "k2": <bool>,
//     "zone": { ...one universe z-array element (n,t,s,r,p,tags, nauvis?)... },
//     "radius": <render half-extent in tiles, optional>,
//     "layer": <0=terrain+ore (default), 1=terrain only, 2=ore only> }
//
// Response: resultPtr()/resultLen() = UTF-8 JSON
//   { "ok": true, "zone", "zone_seed", "type", "radius", "width", "height",
//     "layer", "resources": { name: { amount, display, tiles } } }
//   plus pixelsPtr()/pixelsLen() = width*height*4 RGBA8 (top-left origin,
//   north-up like the native cell render). Valid until the next call.
const std = @import("std");
const se = @import("se_ore_placement.zig");
const terrain = @import("terrain.zig");
const biome = @import("biome.zig");
const asteroid = @import("asteroid.zig");
const universe = @import("universe_gen");
const data = universe.data;
const res = @import("se_resources.zig");

var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var g_result: []u8 = &.{};
var g_pixels: []u8 = &.{};
var input_buf: []u8 = &.{};

export fn inputPtr() [*]u8 {
    return input_buf.ptr;
}
export fn inputCap() usize {
    return input_buf.len;
}
export fn growInput(cap: usize) bool {
    const a = std.heap.page_allocator;
    const nb = a.realloc(input_buf, cap) catch return false;
    input_buf = nb;
    return true;
}
export fn resultPtr() [*]const u8 {
    return g_result.ptr;
}
export fn resultLen() usize {
    return g_result.len;
}
export fn pixelsPtr() [*]const u8 {
    return g_pixels.ptr;
}
export fn pixelsLen() usize {
    return g_pixels.len;
}

export fn generateSurface(len: usize) void {
    _ = arena_state.reset(.retain_capacity);
    const a = arena_state.allocator();
    g_pixels = &.{};
    const req = if (len <= input_buf.len) input_buf[0..len] else &.{};
    g_result = run(a, req) catch |e| blk: {
        g_pixels = &.{};
        break :blk std.fmt.allocPrint(a, "{{\"ok\":false,\"error\":\"{s}\"}}", .{@errorName(e)}) catch &.{};
    };
}

/// Parse the request and generate the zone surface. Writes g_pixels (RGBA) and
/// returns the summary JSON. Mirrors se_main.zig's runZoneDriver per-zone path
/// (the pure part) — keep the two in sync when the algorithm changes.
fn run(a: std.mem.Allocator, req: []const u8) ![]u8 {
    const parsed = try std.json.parseFromSlice(std.json.Value, a, req, .{});
    const obj = parsed.value.object;

    const seed: u64 = switch (obj.get("seed") orelse return error.NoSeed) {
        .integer => |v| @intCast(v),
        .float => |v| @intFromFloat(v),
        else => return error.BadSeed,
    };
    const k2 = if (obj.get("k2")) |v| (v == .bool and v.bool) else false;
    const layer: i32 = if (obj.get("layer")) |v| blk: {
        break :blk switch (v) {
            .integer => |i| @intCast(@min(@max(i, 0), 2)),
            else => 0,
        };
    } else 0;
    const override_radius: ?i32 = if (obj.get("radius")) |v| blk: {
        break :blk switch (v) {
            .integer => |i| @intCast(i),
            .float => |f| @intFromFloat(f),
            else => null,
        };
    } else null;
    const z = (obj.get("zone") orelse return error.NoZone).object;
    // palette: "vanilla" renders Nauvis ground with the base-game look for the
    // base / Space Age configs (alien-biomes tiles are SE-only). Default "se".
    const vanilla_ground = if (obj.get("palette")) |v| blk: {
        break :blk (v == .string and std.mem.eql(u8, v.string, "vanilla"));
    } else false;
    // Optional absolute tile rectangle {x0,y0,x1,y1} (half-open). When given,
    // render exactly that rect instead of the centered radius disk — used for
    // chunked/parallel big-map rendering. Semantics are otherwise identical
    // (same disk clip / ore pass), so a union of chunks == one whole call.
    // terrainless: compute + return ore pixels only (inputs still the full
    // terrain+ore set). Lets the JS chunk terrain into parallel bands while one
    // worker does the whole-rect ore pass — ore placement is rect-dependent
    // (starting-area enrichment), so ores can't be split across band calls.
    const terrainless = if (obj.get("terrainless")) |v| (v == .bool and v.bool) else false;
    const rect: ?[4]i32 = if (obj.get("rect")) |v| blk: {
        const o = v.object;
        const gv = struct { fn g(oo: std.json.ObjectMap, k: []const u8) !i32 {
            const f = oo.get(k) orelse return error.BadRect;
            return switch (f) {
                .integer => |i| @intCast(i),
                .float => |fl| @intFromFloat(fl),
                else => error.BadRect,
            };
        } }.g;
        break :blk .{ try gv(o, "x0"), try gv(o, "y0"), try gv(o, "x1"), try gv(o, "y1") };
    } else null;
    const g_pixels_ptr: *[]u8 = &g_pixels;

    return generateZone(a, seed, k2, z, override_radius, rect, layer, terrainless, vanilla_ground, g_pixels_ptr);
}

/// The pure zone driver — same math as segen's runZoneDriver for one zone.
fn generateZone(
    a: std.mem.Allocator,
    world_seed: u64,
    has_k2: bool,
    z: std.json.ObjectMap,
    override_radius: ?i32,
    rect: ?[4]i32,
    layer: i32,
    terrainless: bool,
    vanilla_ground: bool,
    out_pixels: *[]u8,
) ![]u8 {
    _ = world_seed; // output paths only in the native CLI
    const name = (z.get("n") orelse return error.NoZoneName).string;
    const ztype_str = (z.get("t") orelse return error.NoZoneType).string;
    const ztype: data.ZoneType = blk: {
        inline for (@typeInfo(data.ZoneType).@"enum".fields) |fld| {
            if (std.mem.eql(u8, ztype_str, fld.name)) break :blk @enumFromInt(fld.value);
        }
        return error.UnsupportedZoneType;
    };
    if (ztype != .planet and ztype != .moon and ztype != .@"asteroid-field") return error.NotGeneratable;
    const is_field = ztype == .@"asteroid-field";
    const zone_seed: u32 = @intCast((z.get("s") orelse return error.NoZoneSeed).integer);
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
        return error.NoZoneRadius;
    };
    const primary: ?[]const u8 = if (z.get("p")) |pv| (if (pv == .string) pv.string else null) else null;

    // Synthetic Nauvis entry (the universe generator never emits it): the home
    // planet uses the GAME's default map-gen settings — vanilla autoplace at
    // default 1/1/1 controls, map seed = world seed, default water (size 1.0).
    const is_nauvis = if (z.get("nauvis")) |v| (v == .bool and v.bool) else false;

    // tags (strings, optional — bare enum names, like universe.wasm emits)
    const tags = universe.Tags{
        .temperature = tagOf(data.Temperature, z, "temperature"),
        .water = tagOf(data.Water, z, "water"),
        .moisture = tagOf(data.Moisture, z, "moisture"),
        .trees = tagOf(data.Trees, z, "trees"),
        .aux = tagOf(data.Aux, z, "aux"),
        .cliff = tagOf(data.Cliff, z, "cliff"),
        .enemy = tagOf(data.Enemy, z, "enemy"),
    };
    // Build resource inputs: our shared config table + the zone's controls.
    const ores_only = layer == 2 and !terrainless; // ore-only layer skips fluids (matches --ores-only)
    var inputs_buf: [res.RESOURCE_ENTRIES.len]se.ResourceInput = undefined;
    var ninputs: usize = 0;
    if (is_nauvis) {
        // Nauvis under SE: SE's data stage re-derives EVERY base ore with the SE
        // autoplace function (verified in-game). Base ores only, default 1/1/1
        // controls (plus K2 rare-metal under K2), r=5000 → frequency mult 1.
        const nauvis_ores = [_][]const u8{ "iron-ore", "copper-ore", "coal", "stone", "uranium-ore" };
        for (res.RESOURCE_ENTRIES) |e| {
            var is_base = false;
            for (nauvis_ores) |nm| {
                if (std.mem.eql(u8, e.name, nm)) {
                    is_base = true;
                    break;
                }
            }
            if (has_k2 and std.mem.eql(u8, e.name, "kr-rare-metal-ore")) is_base = true;
            if (!is_base) continue;
            if (ores_only and e.cfg.random_probability < 1.0) continue;
            var ctrl = se.Controls{ .frequency = 1.0, .size = 1.0, .richness = 1.0 };
            if (res.fsrOverride(z, e.name)) |ov| ctrl = .{ .frequency = ov[0], .size = ov[1], .richness = ov[2] };
            inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = ctrl };
            ninputs += 1;
        }
    } else {
        const controls = universe.computeZoneMapgenControls(zone_seed, ztype, primary, tags, radius, false);
        for (res.RESOURCE_ENTRIES) |e| {
            if (!has_k2 and std.mem.startsWith(u8, e.name, "kr-")) continue;
            // K2 resources carry SE field controls but K2 never places them in
            // space — the live game has 0 kr-* entities on asteroid fields.
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
            if (res.fsrOverride(z, e.name)) |ov| ctrl = .{ .frequency = ov[0], .size = ov[1], .richness = ov[2] };
            if (ctrl.size <= 0) continue;
            inputs_buf[ninputs] = .{ .name = e.name, .config = e.cfg, .controls = ctrl };
            ninputs += 1;
        }
    }
    const inputs = inputs_buf[0..ninputs];

    // terrain: water tag "none" => no water gate; otherwise approximate the SE
    // water control (freq 1, size 1.5 — the calibrated Horaerratum point).
    // Nauvis always has water at the game DEFAULT size 1.0.
    // (Elevation/ZoneTerrain/Classifier are large — heap-allocated so the wasm
    // stack stays small; the arena owns them for the duration of the call.)
    const has_water = if (is_nauvis) true else if (tags.water) |wt| wt != .none else false;
    const water_size: f64 = if (is_nauvis) 1.0 else 1.5;
    var elev: ?*terrain.Elevation = null;
    if (has_water) {
        const e = try a.create(terrain.Elevation);
        e.* = terrain.Elevation.init(zone_seed, 1.0, water_size);
        elev = e;
    }

    // Per-zone temperature control from the SE tag (midrange→0.65, extreme→6).
    const tc = (tags.temperature orelse data.Temperature.midrange).controlSettings();
    const fm = universe.zoneFrequencyMultiplier(radius);
    const zt = try a.create(terrain.ZoneTerrain);
    zt.* = terrain.ZoneTerrain.init(.{
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
    const classifier = try a.create(biome.Classifier);
    classifier.* = biome.Classifier.init(zone_seed);
    // Base (vanilla) Nauvis ground for the base/Space Age configs — a separate
    // tile competition + palette from the SE alien-biomes classifier above.
    var base_nauvis: ?*biome.BaseNauvis = null;
    if (vanilla_ground) {
        const bc = try a.create(biome.BaseNauvis);
        bc.* = biome.BaseNauvis.init(zone_seed);
        base_nauvis = bc;
    }

    // The render/ore RECT half-extent. --radius caps it (so we can generate
    // just the inner disk) while `radius` above stays the zone's true radius
    // for the resource-control + frequency math.
    const r: i32 = if (override_radius) |o| o else @intFromFloat(radius);

    // Render bounds: centered square [-r,r) by default, or an absolute rect for
    // chunked/parallel renders. The disk clip below is identical either way so
    // chunk unions match a single whole-image call bit-for-bit.
    const bounds = rect orelse [_]i32{ -r, -r, r, r };
    const xa = bounds[0];
    const ya = bounds[1];
    const xb = bounds[2];
    const yb = bounds[3];

    var ores: std.ArrayList(se.OreEntity) = .empty;
    defer ores.deinit(a);

    // terrain-only renders don't touch ore at all.
    const need_ores = layer != 1;
    if (need_ores) {
        ores = try se.computeSEOresInRect(
            a,
            zone_seed,
            radius,
            xa,
            ya,
            xb,
            yb,
            inputs,
            1,
            if (elev) |e| e else null,
            zt,
            classifier,
        );

        // Asteroid fields place resources only on se-asteroid tiles; drop
        // everything that landed on space.
        if (is_field) {
            const field = asteroid.AsteroidField.initField(zone_seed);
            var kept: usize = 0;
            for (ores.items) |oe| {
                if (field.tileAt(@floatFromInt(oe.x), @floatFromInt(oe.y)) == .asteroid) {
                    ores.items[kept] = oe;
                    kept += 1;
                }
            }
            ores.shrinkRetainingCapacity(kept);
        }
    }

    // Render a disk (grid=1) into an RGBA buffer: terrain/biome/water tiles
    // (opaque), ore overlay (opaque), everything outside the zone's disk fully
    // transparent so the browser canvas shows just the disk.
    const cw: u32 = @intCast(xb - xa);
    const ch: u32 = @intCast(yb - ya);
    const pixels = try a.alloc(u8, @as(usize, cw) * ch * 4);
    @memset(pixels, 0); // transparent
    var el_s = terrain.Elevation.init(zone_seed, 1.0, if (has_water) water_size else 1.0);
    if (!terrainless and layer != 2) {
        var iy: i32 = ya;
        while (iy < yb) : (iy += 1) {
            var ix: i32 = xa;
            while (ix < xb) : (ix += 1) {
                const fx: f64 = @floatFromInt(ix);
                const fy: f64 = @floatFromInt(iy);
                if (fx * fx + fy * fy > radius * radius) continue;
                const e = if (has_water) el_s.at(fx, fy) else 1.0;
                const color: [3]u8 = if (vanilla_ground)
                    biome.nauvis_base_palette[base_nauvis.?.classify(fx, fy, e, zt.moisture(fx, fy), zt.aux(fx, fy))].color
                else if (has_water and e < 0.0)
                    (if (e < -5.0) biome.deepwater else biome.water)
                else
                    classifier.classifyColor(fx, fy, zt.temperature(fx, fy), zt.moisture(fx, fy), zt.aux(fx, fy), e);
                const lpx: usize = @intCast(ix - xa);
                const lpy: usize = @intCast(iy - ya);
                const idx = (lpy * cw + lpx) * 4;
                pixels[idx] = color[0];
                pixels[idx + 1] = color[1];
                pixels[idx + 2] = color[2];
                pixels[idx + 3] = 255;
            }
        }
    }
    if (layer != 1) {
        for (ores.items) |ore| {
            if (ore.x < xa or ore.x >= xb or ore.y < ya or ore.y >= yb) continue;
            const lpx: usize = @intCast(ore.x - xa);
            const lpy: usize = @intCast(ore.y - ya);
            const oc = res.MapColors.get(ore.resource_name);
            const idx = (lpy * cw + lpx) * 4;
            pixels[idx] = oc[0];
            pixels[idx + 1] = oc[1];
            pixels[idx + 2] = oc[2];
            pixels[idx + 3] = 255;
        }
    }
    out_pixels.* = pixels;

    // per-resource totals (matches segen summary.json; "display" is the
    // human-readable amount).
    var summary: std.ArrayList(u8) = .empty;
    try summary.appendSlice(a, "{\"ok\":true");
    try appendFmt(a, &summary, ",\"zone\":\"{s}\",\"zone_seed\":{d},\"type\":\"{s}\"", .{ name, zone_seed, ztype_str });
    try appendFmt(a, &summary, ",\"radius\":{d},\"width\":{d},\"height\":{d},\"layer\":{d}", .{ r, cw, ch, layer });
    try appendFmt(a, &summary, ",\"palette\":\"{s}\"", .{if (vanilla_ground) "nauvis-base" else "se-alien-biomes"});
    if (rect != null)
        try appendFmt(a, &summary, ",\"x0\":{d},\"y0\":{d}", .{ xa, ya });
    try summary.appendSlice(a, ",\"resources\":{");
    {
        var first = true;
        for (inputs) |inp| {
            var cnt: u64 = 0;
            var amount: u64 = 0;
            for (ores.items) |o| {
                if (std.mem.eql(u8, o.resource_name, inp.name)) {
                    cnt += 1;
                    amount += o.amount;
                }
            }
            if (cnt == 0) continue;
            var abuf: [32]u8 = undefined;
            const disp = fmtAmount(&abuf, amount);
            if (!first) try summary.appendSlice(a, ",");
            first = false;
            try appendFmt(a, &summary, "\"{s}\":{{\"amount\":{d},\"display\":\"{s}\",\"tiles\":{d}}}", .{ inp.name, amount, disp, cnt });
        }
    }
    try summary.appendSlice(a, "}}");
    return summary.toOwnedSlice(a);
}

/// Parse a tag string into the SE enum. Accepts both bare enum names ("vcold",
/// "max" — what universe.wasm emits) and prefixed prototype tags
/// ("temperature_vcold", "aux_very_high").
fn tagOf(comptime E: type, z: std.json.ObjectMap, key: []const u8) ?E {
    const v = z.get(key) orelse return null;
    if (v != .string) return null;
    inline for (@typeInfo(E).@"enum".fields) |fld| {
        if (std.mem.eql(u8, v.string, fld.name)) return @enumFromInt(fld.value);
    }
    return universe.parseTagEnum(E, v.string);
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
