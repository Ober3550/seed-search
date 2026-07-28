/// SE seed finder — batch runner for gen.zig.
///
/// Environment:
///   START_SEED          First seed (default 341)
///   COUNT               Seeds to generate (default 1)
///   SE_K2 / SE_ENABLE_K2  Enable Krastorio2 (1 or true)
///   MIN_NAQ_DV          Naquium field delta-v filter (0=off)
///   MIN_PROD_MODULES    Prod module filter (0=off)
///   OUTPUT_DIR          Output directory (default "output")
///   MAX_LINES_PER_FILE  Lines per JSONL file before rotating (default 10000)
///
/// Output:
///   stderr → progress log (redirect to file in docker)
///   OUTPUT_DIR/seeds_N.jsonl → rotating JSONL, auto-resumes from last seed
const std = @import("std");
const gen = @import("gen.zig");
const data = @import("data.zig");

fn getEnvU32(comptime name: [:0]const u8, default: u32) u32 {
    const val = std.c.getenv(name) orelse return default;
    return std.fmt.parseInt(u32, std.mem.sliceTo(val, 0), 10) catch default;
}
fn getEnvBool(comptime name: [:0]const u8) bool {
    const val = std.c.getenv(name) orelse return false;
    const s = std.mem.sliceTo(val, 0);
    return std.mem.eql(u8, s, "1") or std.mem.eql(u8, s, "true");
}

/// Parse "s":NNN from the start of a JSON line. Returns 0 on failure.
fn parseSeedFromJson(line: []const u8) u32 {
    const needle = "\"s\":";
    const idx = std.mem.indexOf(u8, line, needle) orelse return 0;
    var rest = line[idx + needle.len ..];
    const end = std.mem.indexOfScalar(u8, rest, ',') orelse std.mem.indexOfScalar(u8, rest, '}') orelse rest.len;
    return std.fmt.parseInt(u32, rest[0..end], 10) catch 0;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const end_seed = getEnvU32("END_SEED", 100000);
    const k2_enabled = getEnvBool("SE_K2") or getEnvBool("SE_ENABLE_K2");
    const start_seed = getEnvU32("START_SEED", 0);

    std.debug.print("# Generating seeds {d} to {d} (K2={})\n", .{ start_seed, end_seed, k2_enabled });

    var seed = start_seed;
    var passed: u32 = 0;
    const t_start = std.Io.Clock.awake.now(io).nanoseconds;
    var last_t = t_start;
    var last_seed = start_seed;
    var last_passed: u32 = 0;

    // Single stdout writer for the whole run (creating one per seed resets the
    // file offset to 0 and clobbers previous seeds when stdout is a regular file).
    var stdout_buf: [1 << 16]u8 = undefined;
    var stdout_fw = std.Io.File.stdout().writer(io, &stdout_buf);
    const stdout_w = &stdout_fw.interface;

    while (seed <= end_seed) : (seed += 2) {
        if (seed != start_seed) _ = arena.reset(.retain_capacity);

        if (seed > start_seed and (seed - start_seed) % 2000 == 0) {
            const now = std.Io.Clock.awake.now(io).nanoseconds;
            const elapsed_s: f64 = @as(f64, @floatFromInt(now - t_start)) / 1_000_000_000.0;
            const delta_s: f64 = @as(f64, @floatFromInt(now - last_t)) / 1_000_000_000.0;
            const delta_seeds = seed - last_seed;
            const rate: u32 = if (delta_s > 0) @intFromFloat(@round(@as(f64, @floatFromInt(delta_seeds)) / delta_s)) else 0;
            const worker_id = getEnvU32("WORKER_ID", 0);
            std.debug.print("worker {d}, [{d:>3.0}s] seed {d} rate {d}/s, passed {d}\n", .{ worker_id, elapsed_s, seed, rate, passed });
            last_t = now;
            last_seed = seed;
            last_passed = passed;
        }

        var universe = gen.generateUniverse(a, seed, k2_enabled) catch |err| {
            std.debug.print("# ERROR seed {d}: {}\n", .{ seed, err });
            // loop advances seed
            continue;
        };

        const bodyMap = try gen.buildBodyMap(a);
        const primaries = gen.resolvePrimaries(a, universe.zones, bodyMap) catch unreachable;
        const field_primaries = gen.resolveFieldPrimaries(a, universe.zones) catch unreachable;
        gen.computeGravityWells(&universe.zones, universe.zoneByName);

        const nauvis_zi = universe.zoneByName.get("Nauvis") orelse @panic("Nauvis not found");
        const nauvis_sgw = universe.zones.items[nauvis_zi].star_gravity_well;
        const nauvis_pgw = universe.zones.items[nauvis_zi].planet_gravity_well;

        // --- Filters ---
        const min_naq_dv = getEnvU32("MIN_NAQ_DV", 0);
        if (min_naq_dv > 0) {
            const calidus_zi = universe.zoneByName.get("Calidus") orelse @panic("Calidus not found");
            const cx = universe.zones.items[calidus_zi].stellar_x;
            const cy = universe.zones.items[calidus_zi].stellar_y;
            const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
            var nearest: u32 = std.math.maxInt(u32);
            for (universe.zones.items) |z| {
                if (z.ztype == .@"asteroid-field") {
                    const scores = gen.computeZoneResources(z.seed, z.ztype, null, empty_tags);
                    if (scores[@intFromEnum(data.Resource.se_naquium_ore)] <= 0.0001) continue;
                    const dx = z.stellar_x - cx;
                    const dy = z.stellar_y - cy;
                    const dist = @sqrt(dx * dx + dy * dy);
                    const dv: u32 = @intFromFloat(@ceil(400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw));
                    if (dv < nearest) nearest = dv;
                }
            }
            if (nearest > min_naq_dv) {
                continue;
            }
        }

        const min_prod = getEnvU32("MIN_PROD_MODULES", 0);
        if (min_prod > 0) {
            var p_count: u32 = 0;
            for (universe.vault_loot) |c| {
                if (c == 'P') p_count += 1;
            }
            if (p_count < min_prod) {
                continue;
            }
        }

        // --- Fast scan: nearest asteroid field where naquium is the #1 yield ---
        // Emits one "dv\n" per qualifying seed (nothing otherwise). Skips JSONL.
        // NOTE: uses the current (pre-quota-fix) null-primary yield ranking, so it
        // OVER-counts naquium-primary fields — treat as an upper bound.
        if (getEnvBool("NAQ_SCAN")) {
            const calidus_zi2 = universe.zoneByName.get("Calidus") orelse @panic("Calidus not found");
            const cx = universe.zones.items[calidus_zi2].stellar_x;
            const cy = universe.zones.items[calidus_zi2].stellar_y;
            const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
            _ = empty_tags;
            var best_dv: u32 = std.math.maxInt(u32);
            for (universe.zones.items) |z| {
                if (z.ztype != .@"asteroid-field") continue;
                // naquium is this field's quota-assigned PRIMARY
                const fp = field_primaries.get(z.name) orelse continue;
                if (!std.mem.eql(u8, fp, "se-naquium-ore")) continue;
                const dx = z.stellar_x - cx;
                const dy = z.stellar_y - cy;
                const dist = @sqrt(dx * dx + dy * dy);
                const dv: u32 = @intFromFloat(@ceil(400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw));
                if (dv < best_dv) best_dv = dv;
            }
            if (best_dv != std.math.maxInt(u32)) {
                var lb: [16]u8 = undefined;
                const ls = std.fmt.bufPrint(&lb, "{d}\n", .{best_dv}) catch unreachable;
                _ = stdout_w.writeAll(ls) catch {};
            }
            continue;
        }

        // --- Serialize JSONL (Calidus system only, plus all asteroid fields) ---
        var buf: [524288]u8 = undefined;
        var pos: usize = 0;
        const open = std.fmt.bufPrint(buf[pos..], "{{\"s\":{d},\"d\":{d},\"k\":{},\"l\":\"{s}\",\"z\":[", .{ seed, universe.draws, k2_enabled, universe.vault_loot }) catch unreachable;
        pos += open.len;

        // Only serialize Calidus system + asteroid fields
        const calidus_zi = universe.zoneByName.get("Calidus") orelse @panic("Calidus not found");
        var zone_end: usize = universe.zones.items.len;
        for (universe.zones.items[calidus_zi + 1 ..], calidus_zi + 1..) |z, si| {
            if (z.ztype == .star) {
                zone_end = si;
                break;
            }
        }
        var zi: u32 = 0;
        for (universe.zones.items[calidus_zi..zone_end]) |z| {
            // Nauvis uses map-gen UI settings, not universe generation
            if (std.mem.eql(u8, z.name, "Nauvis")) continue;
            // Orbits carry no resource data
            if (z.ztype == .orbit) continue;
            // Stars carry no resource data
            if (z.ztype == .star) continue;
            if (zi > 0) {
                buf[pos] = ',';
                pos += 1;
            }
            zi += 1;
            const ob = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed }) catch unreachable;
            pos += ob.len;
            if (z.radius > 0) {
                const dr: u32 = @intFromFloat(@floor(z.radius + 0.5));
                const rp = std.fmt.bufPrint(buf[pos..], ",\"r\":{d}", .{dr}) catch unreachable;
                pos += rp.len;
            }
            if (z.ztype == .@"asteroid-field" or z.ztype == .planet or z.ztype == .moon) {
                const tags = gen.computeTags(z.seed, z.name, bodyMap);
                if (tags.temperature) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"temperature\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.water) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"water\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.moisture) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"moisture\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.trees) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"trees\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.aux) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"aux\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.cliff) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"cliff\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.enemy) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"enemy\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                const primary = primaries.get(z.name);
                if (primary) |prim| {
                    const scores = gen.computeZoneResources(z.seed, z.ztype, prim, tags);
                    // Output yield estimates
                    var first = true;
                    for (gen.resource_order, 0..) |rname, ri| {
                        const y = gen.computeYield(scores[ri], false, z.radius, tags.water, rname);
                        if (y >= 0.5) {
                            if (first) {
                                const p = std.fmt.bufPrint(buf[pos..], ",\"y\":{{", .{}) catch unreachable;
                                pos += p.len;
                                first = false;
                            } else {
                                buf[pos] = ',';
                                pos += 1;
                            }
                            var ybuf: [16]u8 = undefined;
                            const ys = gen.formatYield(y, &ybuf);
                            const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":\"{s}\"", .{ rname, ys }) catch unreachable;
                            pos += rp.len;
                        }
                    }
                    if (!first) {
                        buf[pos] = '}';
                        pos += 1;
                    }
                    // Also output normalized scores for ranking
                    first = true;
                    for (gen.resource_order, 0..) |rname, ri| {
                        if (scores[ri] > 0.0001) {
                            if (first) {
                                const p = std.fmt.bufPrint(buf[pos..], ",\"rs\":{{", .{}) catch unreachable;
                                pos += p.len;
                                first = false;
                            } else {
                                buf[pos] = ',';
                                pos += 1;
                            }
                            const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d:.4}", .{ rname, scores[ri] }) catch unreachable;
                            pos += rp.len;
                        }
                    }
                    if (!first) {
                        buf[pos] = '}';
                        pos += 1;
                    }
                    // Output primary resource
                    const pp = std.fmt.bufPrint(buf[pos..], ",\"p\":\"{s}\"", .{prim}) catch unreachable;
                    pos += pp.len;
                }
                if (nauvis_sgw > 0 and z.star_gravity_well > 0 and z.planet_gravity_well > 0) {
                    const dv_raw: f64 = if (@abs(z.star_gravity_well - nauvis_sgw) < 0.01)
                        100.0 * @abs(z.planet_gravity_well - nauvis_pgw)
                    else
                        500.0 * @abs(z.star_gravity_well - nauvis_sgw) + 100.0 * nauvis_pgw + 100.0 * z.planet_gravity_well;
                    const dv: u32 = @intFromFloat(@ceil(dv_raw));
                    const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                    pos += dp.len;
                }
            }
            if (z.ztype == .@"asteroid-field") {
                const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
                const fprim = field_primaries.get(z.name);
                if (fprim) |fp| {
                    const pp = std.fmt.bufPrint(buf[pos..], ",\"p\":\"{s}\"", .{fp}) catch unreachable;
                    pos += pp.len;
                }
                const scores = gen.computeZoneResources(z.seed, z.ztype, fprim, empty_tags);
                var first = true;
                for (gen.resource_order, 0..) |rname, ri| {
                    const y = gen.computeYield(scores[ri], true, 0, null, rname);
                    if (y >= 0.5) {
                        if (first) {
                            const p = std.fmt.bufPrint(buf[pos..], ",\"y\":{{", .{}) catch unreachable;
                            pos += p.len;
                            first = false;
                        } else {
                            buf[pos] = ',';
                            pos += 1;
                        }
                        var ybuf: [16]u8 = undefined;
                        const ys = gen.formatYield(y, &ybuf);
                        const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":\"{s}\"", .{ rname, ys }) catch unreachable;
                        pos += rp.len;
                    }
                }
                if (!first) {
                    buf[pos] = '}';
                    pos += 1;
                }

                const cx = universe.zones.items[calidus_zi].stellar_x;
                const cy = universe.zones.items[calidus_zi].stellar_y;
                const dx = z.stellar_x - cx;
                const dy = z.stellar_y - cy;
                const dist = @sqrt(dx * dx + dy * dy);
                const dv_raw: f64 = 400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw;
                const dv: u32 = @intFromFloat(@ceil(dv_raw));
                const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                pos += dp.len;
            }
            buf[pos] = '}';
            pos += 1;
        }
        // Append asteroid fields and tail homesystem bodies
        for (universe.zones.items[zone_end..]) |z| {
            if (z.ztype == .@"asteroid-field" or z.ztype == .planet or z.ztype == .moon) {
                buf[pos] = ',';
                pos += 1;
                zi += 1;
                const ob = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed }) catch unreachable;
                pos += ob.len;
                const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
                const scores = gen.computeZoneResources(z.seed, z.ztype, null, empty_tags);
                var fr: bool = true;
                for (gen.resource_order, 0..) |rname, ri| {
                    const is_field = z.ztype == .@"asteroid-field";
                    const y = gen.computeYield(scores[ri], is_field, z.radius, null, rname);
                    if (y >= 0.5) {
                        if (fr) {
                            const p = std.fmt.bufPrint(buf[pos..], ",\"y\":{{", .{}) catch unreachable;
                            pos += p.len;
                            fr = false;
                        } else {
                            buf[pos] = ',';
                            pos += 1;
                        }
                        var ybuf: [16]u8 = undefined;
                        const ys = gen.formatYield(y, &ybuf);
                        const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":\"{s}\"", .{ rname, ys }) catch unreachable;
                        pos += rp.len;
                    }
                }
                if (!fr) {
                    buf[pos] = '}';
                    pos += 1;
                }
                const cx = universe.zones.items[calidus_zi].stellar_x;
                const cy = universe.zones.items[calidus_zi].stellar_y;
                const dx = z.stellar_x - cx;
                const dy = z.stellar_y - cy;
                const dist = @sqrt(dx * dx + dy * dy);
                const dv_raw: f64 = 400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw;
                const dv: u32 = @intFromFloat(@ceil(dv_raw));
                const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                pos += dp.len;
                buf[pos] = '}';
                pos += 1;
            }
        }
        buf[pos] = ']';
        pos += 1;
        buf[pos] = '}';
        pos += 1;
        buf[pos] = '\n';
        pos += 1;

        // Write JSONL to stdout (shell redirects to file)
        _ = try stdout_w.writeSplat(&.{buf[0..pos]}, 1);
        passed += 1;

        // loop advances seed
    }
    try stdout_w.flush();
}
