/// SE seed finder — batch runner for gen.zig.
///
/// Environment variables:
///   START_SEED   First seed to generate (default: 341)
///   COUNT        Number of seeds to generate (default: 1)
///   SE_K2        Set to "1" or "true" to enable Krastorio2
///
/// Output (stderr): one JSONL line per seed, plus #-prefixed progress lines.
///   ./seedgen 2> output.jsonl
///   grep '^{' output.jsonl          # data only

const std = @import("std");
const gen = @import("gen.zig");

fn getEnvU32(comptime name: [:0]const u8, default: u32) u32 {
    const val = std.c.getenv(name) orelse return default;
    const slice = std.mem.sliceTo(val, 0);
    return std.fmt.parseInt(u32, slice, 10) catch default;
}

fn getEnvBool(comptime name: [:0]const u8) bool {
    const val = std.c.getenv(name) orelse return false;
    const slice = std.mem.sliceTo(val, 0);
    return std.mem.eql(u8, slice, "1") or std.mem.eql(u8, slice, "true");
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const start_seed = getEnvU32("START_SEED", 341);
    const count = getEnvU32("COUNT", 1);
    const k2_enabled = getEnvBool("SE_K2");

    std.debug.print("# Generating {d} seeds from {d} (K2={})\n", .{ count, start_seed, k2_enabled });

    var seed = start_seed;
    var generated: u32 = 0;
    while (generated < count) : (generated += 1) {
        if (generated > 0) _ = arena.reset(.retain_capacity);

        var universe = gen.generateUniverse(a, seed, k2_enabled) catch |err| {
            std.debug.print("# ERROR seed {d}: {}\n", .{ seed, err });
            seed += 2;
            continue;
        };

        std.debug.print("# {d} z={d} d={d}\n", .{ seed, universe.zones.items.len, universe.draws });

        // JSONL: one compact JSON object per seed.
        // {"s":341,"d":5192,"k":true,"l":"PESPS","z":[{"i":1,"n":"Foo","t":"star","s":123,"r":5000},...]}
        var buf: [524288]u8 = undefined;
        var pos: usize = 0;

        // Opening: {"s":SEED,"d":DRAWS,"k":K2,"l":"LOOT","z":[
        const open = std.fmt.bufPrint(buf[pos..], "{{\"s\":{d},\"d\":{d},\"k\":{},\"l\":\"{s}\",\"z\":[", .{ seed, universe.draws, k2_enabled, universe.vault_loot }) catch unreachable;
        pos += open.len;

        const primaries = gen.resolvePrimaries(a, universe.zones) catch unreachable;
        gen.computeGravityWells(&universe.zones, universe.calidus_children);

        // Find Nauvis for delta-v reference
        var nauvis_sgw: f64 = 0;
        var nauvis_pgw: f64 = 0;
        for (universe.zones.items) |nz| {
            if (std.mem.eql(u8, nz.name, "Nauvis")) { nauvis_sgw = nz.star_gravity_well; nauvis_pgw = nz.planet_gravity_well; break; }
        }

        for (universe.zones.items, 0..) |z, i| {
            if (i > 0) {
                buf[pos] = ',';
                pos += 1;
            }

            // Base zone fields
            const open_brace = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d}", .{ i + 1, z.name, z.ztype, z.seed }) catch unreachable;
            pos += open_brace.len;

            if (z.radius > 0) {
                const display_r: u32 = @as(u32, @intFromFloat(@floor(z.radius + 0.5)));
                const r_part = std.fmt.bufPrint(buf[pos..], ",\"r\":{d}", .{display_r}) catch unreachable;
                pos += r_part.len;
            }

            // Tags for planets and moons
            if (std.mem.eql(u8, z.ztype, "planet") or std.mem.eql(u8, z.ztype, "moon")) {
                const tags = gen.computeTags(z.seed, z.name);
                if (tags.temperature) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"g\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.water) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"w\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.moisture) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"m\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.trees) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"tr\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.aux) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"a\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.cliff) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"c\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }
                if (tags.enemy) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"e\":\"{s}\"", .{v}) catch unreachable;
                    pos += t.len;
                }

                // Resources
                const primary = primaries.get(z.name);
                if (primary) |prim| {
                    const scores = gen.computeZoneResources(z.seed, z.ztype, prim, tags);
                    var first_res = true;
                    for (gen.resource_order, 0..) |rname, ri| {
                        if (scores[ri] > 0.0001) {
                            if (first_res) {
                                const prefix = std.fmt.bufPrint(buf[pos..], ",\"rs\":{{", .{}) catch unreachable;
                                pos += prefix.len;
                                first_res = false;
                            } else {
                                buf[pos] = ',';
                                pos += 1;
                            }
                            const rpart = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d}", .{rname, scores[ri]}) catch unreachable;
                            pos += rpart.len;
                        }
                    }
                    if (!first_res) {
                        buf[pos] = '}';
                        pos += 1;
                    }
                }

                // Delta-v
                if (nauvis_sgw > 0 and z.star_gravity_well > 0 and z.planet_gravity_well > 0) {
                    const dv_raw: f64 = if (@abs(z.star_gravity_well - nauvis_sgw) < 0.01)
                        100.0 * @abs(z.planet_gravity_well - nauvis_pgw)
                    else
                        500.0 * @abs(z.star_gravity_well - nauvis_sgw) + 100.0 * nauvis_pgw + 100.0 * z.planet_gravity_well;
                    const dv: u32 = @as(u32, @intFromFloat(@ceil(dv_raw)));
                    const dv_part = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                    pos += dv_part.len;
                }
            }

            buf[pos] = '}';
            pos += 1;
        }

        // Closing: ]}
        buf[pos] = ']';
        pos += 1;
        buf[pos] = '}';
        pos += 1;
        buf[pos] = '\n';
        pos += 1;

        std.debug.print("{s}", .{buf[0..pos]});

        seed += 2;
    }

    std.debug.print("# Done: {d} seeds.\n", .{generated});
}
