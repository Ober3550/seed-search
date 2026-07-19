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

    const count = getEnvU32("COUNT", 1);
    const k2_enabled = getEnvBool("SE_K2") or getEnvBool("SE_ENABLE_K2");
    const max_lines = getEnvU32("MAX_LINES_PER_FILE", 10000);
    const output_dir = std.mem.sliceTo(std.c.getenv("OUTPUT_DIR") orelse ".", 0);

    // --- Find or create output directory ---
    var dir = std.Io.Dir.cwd().createDirPathOpen(io, output_dir, .{}) catch |e| {
        std.debug.print("# ERROR opening output dir '{s}': {}\n", .{ output_dir, e });
        return;
    };
    defer dir.close(io);

    // --- Resume from last seed ---
    var cur_n: u32 = 0;
    var start_seed: u32 = getEnvU32("START_SEED", 341);
    var existing_lines: u32 = 0;

    // Find highest existing seeds_N.jsonl and read last seed.
    // Close each file explicitly so reads see flushed data.
    var probe_n: u32 = 0;
    while (true) : (probe_n += 1) {
        const name = try std.fmt.allocPrint(a, "seeds_{d}.jsonl", .{probe_n});
        var f = std.Io.Dir.cwd().openFile(io, name, .{}) catch break;
        const file_len = f.length(io) catch 0;
        if (file_len > 0) {
            var reader = f.reader(io, &.{});
            const content = reader.interface.readAlloc(a, @intCast(file_len)) catch "";
            if (content.len > 0) {
                existing_lines = @intCast(std.mem.count(u8, content, "\n"));
                // Find last line's seed
                var last_line_start: usize = 0;
                var i: usize = content.len;
                while (i > 0) { i -= 1; if (content[i] == '\n') { last_line_start = if (i + 1 < content.len) i + 1 else i; break; } }
                if (last_line_start < content.len) {
                    start_seed = parseSeedFromJson(content[last_line_start..]);
                    if (start_seed > 0) start_seed += 2;
                }
            }
        }
        f.close(io);
        cur_n = probe_n;
    }
    if (start_seed < 341) start_seed = getEnvU32("START_SEED", 341);
    cur_n += 1; existing_lines = 0;

    std.debug.print("# Resumed: file {d}, {d} existing lines, max {d}/file\n", .{ cur_n, existing_lines, max_lines });

    // --- Open current output file (append if exists, create if not) ---
    const fname = try std.fmt.allocPrint(a, "seeds_{d}.jsonl", .{cur_n});
    std.debug.print("# Generating seeds {d} to {d} (K2={}) -> {s}\n", .{ start_seed, count, k2_enabled, fname });

    var seed = start_seed;
    var passed: u32 = 0;
    var file_lines: u32 = existing_lines;
    const t_start = std.Io.Clock.awake.now(io).nanoseconds;

    while (seed <= count) : (seed += 2) {
        if (seed != start_seed) _ = arena.reset(.retain_capacity);

        if (seed > start_seed and (seed - start_seed) % 2000 == 0) {
            const elapsed_s: f64 = @as(f64, @floatFromInt(std.Io.Clock.awake.now(io).nanoseconds - t_start)) / 1_000_000_000.0;
            std.debug.print("# [{d:.1}s] seed {d}/{d}, {d} passed\n", .{ elapsed_s, seed, count, passed });
        }

        var universe = gen.generateUniverse(a, seed, k2_enabled) catch |err| {
            std.debug.print("# ERROR seed {d}: {}\n", .{ seed, err });
            // loop advances seed
            continue;
        };

        const bodyMap = try gen.buildBodyMap(a);
        const primaries = gen.resolvePrimaries(a, universe.zones, bodyMap) catch unreachable;
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
            if (nearest > min_naq_dv) { continue; }
        }

        const min_prod = getEnvU32("MIN_PROD_MODULES", 0);
        if (min_prod > 0) {
            var p_count: u32 = 0;
            for (universe.vault_loot) |c| { if (c == 'P') p_count += 1; }
            if (p_count < min_prod) { continue; }
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
            if (z.ztype == .star) { zone_end = si; break; }
        }
        var zi: u32 = 0;
        for (universe.zones.items[calidus_zi..zone_end]) |z| {
            if (zi > 0) { buf[pos] = ','; pos += 1; }
            zi += 1;
            const ob = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed }) catch unreachable;
            pos += ob.len;
            if (z.radius > 0) {
                const dr: u32 = @intFromFloat(@floor(z.radius + 0.5));
                const rp = std.fmt.bufPrint(buf[pos..], ",\"r\":{d}", .{dr}) catch unreachable; pos += rp.len;
            }
            if (z.ztype == .planet or z.ztype == .moon) {
                const tags = gen.computeTags(z.seed, z.name, bodyMap);
                if (tags.temperature) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"g\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.water) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"w\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.moisture) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"m\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.trees) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"tr\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.aux) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"a\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.cliff) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"c\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                if (tags.enemy) |v| { const t = std.fmt.bufPrint(buf[pos..], ",\"e\":\"{s}\"", .{v.tagStr()}) catch unreachable; pos += t.len; }
                const primary = primaries.get(z.name);
                if (primary) |prim| {
                    const scores = gen.computeZoneResources(z.seed, z.ztype, prim, tags);
                    var first = true;
                    for (gen.resource_order, 0..) |rname, ri| {
                        if (scores[ri] > 0.0001) {
                            if (first) { const p = std.fmt.bufPrint(buf[pos..], ",\"rs\":{{", .{}) catch unreachable; pos += p.len; first = false; }
                            else { buf[pos] = ','; pos += 1; }
                            const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d:.4}", .{rname, scores[ri]}) catch unreachable; pos += rp.len;
                        }
                    }
                    if (!first) { buf[pos] = '}'; pos += 1; }
                }
                if (nauvis_sgw > 0 and z.star_gravity_well > 0 and z.planet_gravity_well > 0) {
                    const dv_raw: f64 = if (@abs(z.star_gravity_well - nauvis_sgw) < 0.01)
                        100.0 * @abs(z.planet_gravity_well - nauvis_pgw)
                    else 500.0 * @abs(z.star_gravity_well - nauvis_sgw) + 100.0 * nauvis_pgw + 100.0 * z.planet_gravity_well;
                    const dv: u32 = @intFromFloat(@ceil(dv_raw));
                    const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable; pos += dp.len;
                }
            }
            if (z.ztype == .@"asteroid-field") {
                const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
                const scores = gen.computeZoneResources(z.seed, z.ztype, null, empty_tags);
                var first = true;
                for (gen.resource_order, 0..) |rname, ri| {
                    if (scores[ri] > 0.0001) {
                        if (first) { const p = std.fmt.bufPrint(buf[pos..], ",\"rs\":{{", .{}) catch unreachable; pos += p.len; first = false; }
                        else { buf[pos] = ','; pos += 1; }
                        const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d:.4}", .{rname, scores[ri]}) catch unreachable; pos += rp.len;
                    }
                }
                if (!first) { buf[pos] = '}'; pos += 1; }
                
                const cx = universe.zones.items[calidus_zi].stellar_x;
                const cy = universe.zones.items[calidus_zi].stellar_y;
                const dx = z.stellar_x - cx;
                const dy = z.stellar_y - cy;
                const dist = @sqrt(dx * dx + dy * dy);
                const dv_raw: f64 = 400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw;
                const dv: u32 = @intFromFloat(@ceil(dv_raw));
                const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable; pos += dp.len;
            }
            buf[pos] = '}'; pos += 1;
        }
        // Append asteroid fields and tail homesystem bodies
        for (universe.zones.items[zone_end..]) |z| {
            if (z.ztype == .@"asteroid-field" or z.ztype == .planet or z.ztype == .moon) {
                buf[pos] = ','; pos += 1;
                zi += 1;
                const ob = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed }) catch unreachable;
                pos += ob.len;
                const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
                const scores = gen.computeZoneResources(z.seed, z.ztype, null, empty_tags);
                var fr: bool = true;
                for (gen.resource_order, 0..) |rname, ri| {
                    if (scores[ri] > 0.0001) {
                        if (fr) { const p = std.fmt.bufPrint(buf[pos..], ",\"rs\":{{", .{}) catch unreachable; pos += p.len; fr = false; }
                        else { buf[pos] = ','; pos += 1; }
                        const rp = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d:.4}", .{rname, scores[ri]}) catch unreachable; pos += rp.len;
                    }
                }
                if (!fr) { buf[pos] = '}'; pos += 1; }
                const cx = universe.zones.items[calidus_zi].stellar_x;
                const cy = universe.zones.items[calidus_zi].stellar_y;
                const dx = z.stellar_x - cx;
                const dy = z.stellar_y - cy;
                const dist = @sqrt(dx * dx + dy * dy);
                const dv_raw: f64 = 400.0 * dist + 500.0 * nauvis_sgw + 100.0 * nauvis_pgw;
                const dv: u32 = @intFromFloat(@ceil(dv_raw));
                const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable; pos += dp.len;
                buf[pos] = '}'; pos += 1;
            }
        }
        buf[pos] = ']'; pos += 1;
        buf[pos] = '}'; pos += 1;
        buf[pos] = '\n'; pos += 1;

        // Write JSONL to stdout (shell redirects to file)
        {
            var stdout_buf: [4096]u8 = [_]u8{0} ** 4096;
            var fw = std.Io.File.stdout().writer(io, &stdout_buf);
            _ = try fw.interface.writeSplat(&.{buf[0..pos]}, 1);
            try fw.interface.flush();
        }
        passed += 1;
        file_lines += 1;

        // Rotate if full
        if (file_lines >= max_lines) {
            cur_n += 1;
            file_lines = 0;
            // New file will be created on next write
            std.debug.print("# Rolled over to seeds_{d}.jsonl\n", .{cur_n});
        }

        // loop advances seed
    }

    std.debug.print("# Done: seed {d}, {d} passed -> {s}\n", .{ seed - 2, passed, fname });
}
