// WebAssembly entry for the universe generator: generate one seed's full
// ALL_ZONES universe (zones + tags + primary + FSR scores) entirely in the
// browser, so single-seed analysis needs no backend.
//
// Reuses the SAME pure generation functions as the native seedgen
// (gen.generateUniverse / resolvePrimaries / computeTags / computeZoneResources),
// so the FSR values are bit-identical. Only the serialization lives here; it
// mirrors the `z`-array element format emitted by main.zig (full resource ids).
//
// Build: zig build-exe wasm.zig -target wasm32-freestanding -O ReleaseSmall \
//          -fno-entry -rdynamic -femit-bin=universe.wasm
//
// JS: instantiate, call generate(seed, k2), then read the UTF-8 JSON from
//     linear memory at resultPtr()..resultPtr()+resultLen(). The result is valid
//     until the next generate() call (the arena is reset each time).
const std = @import("std");
const gen = @import("gen.zig");
const data = @import("data.zig");

var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var g_result: []u8 = &.{};

export fn resultPtr() [*]const u8 {
    return g_result.ptr;
}
export fn resultLen() usize {
    return g_result.len;
}

export fn generate(seed: u32, k2i: u32) void {
    _ = arena_state.reset(.retain_capacity);
    const a = arena_state.allocator();
    g_result = build(a, seed, k2i != 0) catch
        (std.fmt.allocPrint(a, "{{\"error\":\"generate failed\",\"s\":{d}}}", .{seed}) catch &.{});
}

fn emitTag(dst: []u8, name: []const u8, val: anytype) []u8 {
    if (val) |v| return std.fmt.bufPrint(dst, ",\"{s}\":\"{s}\"", .{ name, @tagName(v) }) catch dst[0..0];
    return dst[0..0];
}

/// stellar position of the star containing zone z (walk parents; mirrors main.zig).
fn zoneStarStellar(zones: []const gen.Zone, z: gen.Zone) [2]f64 {
    var p = z.parent_index;
    while (p >= 0 and zones[@intCast(p)].ztype != .star) p = zones[@intCast(p)].parent_index;
    if (p >= 0) return .{ zones[@intCast(p)].stellar_x, zones[@intCast(p)].stellar_y };
    return .{ z.stellar_x, z.stellar_y };
}

/// SE Zone.get_travel_delta_v(Nauvis, z) — the Δv the in-game navigation shows
/// (mirrors main.zig deltaVFromNauvis; travel only, caller rounds).
fn deltaVFromNauvis(zones: []const gen.Zone, z: gen.Zone, nauvis_sgw: f64, nauvis_pgw: f64, cx: f64, cy: f64) f64 {
    const sp = zoneStarStellar(zones, z);
    if (sp[0] == cx and sp[1] == cy) {
        return if (@abs(z.star_gravity_well - nauvis_sgw) < 0.01)
            100.0 * @abs(z.planet_gravity_well - nauvis_pgw)
        else
            500.0 * @abs(z.star_gravity_well - nauvis_sgw) + 100.0 * nauvis_pgw + 100.0 * z.planet_gravity_well;
    }
    const dx = sp[0] - cx;
    const dy = sp[1] - cy;
    const dist = @sqrt(dx * dx + dy * dy);
    return 400.0 * dist + 500.0 * (nauvis_sgw + z.star_gravity_well) + 100.0 * (nauvis_pgw + z.planet_gravity_well);
}

fn build(a: std.mem.Allocator, seed: u32, k2: bool) ![]u8 {
    const bodyMap = try gen.buildBodyMap(a);
    var universe = try gen.generateUniverse(a, seed, k2);
    // gravity wells feed the Δv column (same as native main.zig does)
    gen.computeGravityWells(&universe);
    const primaries = try gen.resolvePrimaries(a, universe.zones, bodyMap, k2);
    const field_primaries = try gen.resolveFieldPrimaries(a, universe.zones, k2);

    // Calidus home-system slice (matches main.zig): [calidus_zi, zone_end) ∪
    // [tail_start, end). Drives the per-zone "c" (in-Calidus) flag.
    const calidus_zi = universe.zoneByName.get("Calidus") orelse return error.NoCalidus;
    var zone_end: usize = universe.zones.items.len;
    for (universe.zones.items[calidus_zi + 1 ..], calidus_zi + 1..) |z, si| {
        if (z.ztype == .star or z.ztype == .@"asteroid-field") {
            zone_end = si;
            break;
        }
    }
    var tail_start: usize = universe.zones.items.len;
    {
        var ti = universe.zones.items.len;
        while (ti > 0) {
            ti -= 1;
            if (universe.zones.items[ti].ztype == .@"asteroid-field") {
                tail_start = ti + 1;
                break;
            }
        }
    }

    const buf = try a.alloc(u8, 8 << 20);
    var pos: usize = 0;
    pos += (try std.fmt.bufPrint(buf[pos..], "{{\"s\":{d},\"k\":{},\"z\":[", .{ seed, k2 })).len;

    var zi: u32 = 0;
    // Nauvis params for the Δv column (Nauvis is skipped from output rows).
    var nauvis: ?gen.Zone = null;
    for (universe.zones.items) |zz| {
        if (std.mem.eql(u8, zz.name, "Nauvis")) {
            nauvis = zz;
            break;
        }
    }
    for (universe.zones.items, 0..) |z, si| {
        if (std.mem.eql(u8, z.name, "Nauvis")) continue; // map-gen UI, not universe gen
        if (z.ztype == .orbit or z.ztype == .star) continue; // no resource data
        if (zi > 0) {
            buf[pos] = ',';
            pos += 1;
        }
        zi += 1;
        const in_cal: u8 = if ((si >= calidus_zi and si < zone_end) or si >= tail_start) 1 else 0;
        pos += (try std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d},\"c\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed, in_cal })).len;
        if (z.radius > 0) pos += (try std.fmt.bufPrint(buf[pos..], ",\"r\":{d}", .{z.radius})).len;
        // Δv to Nauvis (same value the in-game navigation column shows).
        if (nauvis) |nz| {
            const ns = zoneStarStellar(universe.zones.items, nz);
            const dv = @as(u32, @intFromFloat(@round(deltaVFromNauvis(universe.zones.items, z, nz.star_gravity_well, nz.planet_gravity_well, ns[0], ns[1]))));
            pos += (try std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv})).len;
        }

        if (z.ztype == .@"asteroid-field" or z.ztype == .planet or z.ztype == .moon) {
            const tags = gen.computeTags(z.seed, z.name, bodyMap);
            pos += emitTag(buf[pos..], "temperature", tags.temperature).len;
            pos += emitTag(buf[pos..], "water", tags.water).len;
            pos += emitTag(buf[pos..], "moisture", tags.moisture).len;
            pos += emitTag(buf[pos..], "trees", tags.trees).len;
            pos += emitTag(buf[pos..], "aux", tags.aux).len;
            pos += emitTag(buf[pos..], "cliff", tags.cliff).len;
            pos += emitTag(buf[pos..], "enemy", tags.enemy).len;

            const primary = primaries.get(z.name) orelse field_primaries.get(z.name);
            if (primary) |prim| {
                // Full resource ids for p/rs (resource_order), matching main.zig.
                pos += (try std.fmt.bufPrint(buf[pos..], ",\"p\":\"{s}\"", .{prim})).len;
                const controls = gen.computeZoneResources(z.seed, z.ztype, prim, tags);
                buf[pos] = ',';
                pos += 1;
                pos += (try std.fmt.bufPrint(buf[pos..], "\"rs\":{{", .{})).len;
                var first = true;
                for (gen.resource_order, controls) |rname, score| {
                    if (!first) {
                        buf[pos] = ',';
                        pos += 1;
                    }
                    first = false;
                    if (score <= 0) {
                        pos += (try std.fmt.bufPrint(buf[pos..], "\"{s}\":0.0", .{rname})).len;
                    } else {
                        pos += (try std.fmt.bufPrint(buf[pos..], "\"{s}\":{d}", .{ rname, score })).len;
                    }
                }
                buf[pos] = '}';
                pos += 1;
            }
        }
        buf[pos] = '}';
        pos += 1;
    }
    buf[pos] = ']';
    pos += 1;
    buf[pos] = '}';
    pos += 1;
    return buf[0..pos];
}
