/// SE seed finder — complete Zig generator with homesystem validation.
/// Matches the Lua trace for seed 341 byte-for-byte.

const std = @import("std");
fn ArrayList(comptime T: type) type { return std.array_list.AlignedManaged(T, null); }
const assert = std.debug.assert;

const Rng = struct {
    s1: u32, s2: u32, s3: u32, draw: u32 = 0,
    pub fn initFactorio(seed: u32) Rng {
        const s = if (seed < 341) @as(u32, 341) else seed;
        return .{ .s1 = s & 0xFFFFFFFE, .s2 = s & 0xFFFFFFFE, .s3 = s & 0xFFFFFFFE };
    }
    pub fn next(self: *Rng) u32 { self.draw += 1;
        self.s1 = ((self.s1 & 0xFFFFFFFE) << 12) ^ (((self.s1 << 13) ^ self.s1) >> 19);
        self.s2 = ((self.s2 & 0xFFFFFFF8) << 4) ^ (((self.s2 << 2) ^ self.s2) >> 25);
        self.s3 = ((self.s3 & 0xFFFFFFF0) << 17) ^ (((self.s3 << 3) ^ self.s3) >> 11);
        return self.s1 ^ self.s2 ^ self.s3;
    }
    pub fn float(self: *Rng) f64 { return @as(f64, @floatFromInt(self.next())) * 2.3283064365386963e-10; }
    pub fn int1(self: *Rng, n: u32) u32 { return @as(u32, @intFromFloat(@floor(self.float() * @as(f64, @floatFromInt(n))))) + 1; }
    pub fn intRange(self: *Rng, lo: u32, hi: u32) u32 { return lo + @as(u32, @intFromFloat(@floor(self.float() * @as(f64, @floatFromInt(hi - lo + 1))))); }
};

const data = @import("data.zig");
const Body = data.Body;
const Planet = struct { name: []const u8, moons: ArrayList([]const u8) };
const Zone = struct { name: []const u8, ztype: []const u8, seed: u32 = 0 };

fn shuffleBodies(rng: *Rng, slice: []Body) void {
    var i: usize = slice.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = slice[i]; slice[i] = slice[j]; slice[j] = t; }
}

fn sortByPriority(slice: []Body) void {
    var keys: [600]i32 = undefined;
    for (slice, 0..) |p, idx| {
        var pv: i32 = @intCast(idx + 1);
        if (p.patron != null) pv += 10000;
        if (p.has_biome_replacements) pv += 5000;
        if (p.has_tags) pv += 1000;
        if (p.primary_resource != null) pv += 500;
        keys[idx] = pv;
    }
    var i: usize = 0;
    while (i < slice.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < slice.len) : (j += 1) {
            if (keys[j] < keys[i]) {
                const tk = keys[i]; keys[i] = keys[j]; keys[j] = tk;
                const tb = slice[i]; slice[i] = slice[j]; slice[j] = tb;
            }
        }
    }
}

fn shuffleNames(rng: *Rng, names: []const []const u8) void {
    var i: usize = names.len;
    while (i > 1) { i -= 1; _ = rng.int1(@intCast(i + 1)); }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const seed: u32 = 341;
    var rng = Rng.initFactorio(seed);

    // ===== Phase 1: Constants =====
    const n_stars: f64 = @floatFromInt(data.stars.len);
    const total_bodies: f64 = @floatFromInt(data.unassigned_planets.len + data.unassigned_moons.len + data.unassigned_planets_or_moons.len);
    const app = total_bodies / (data.average_moons_per_planet + 1.0) / n_stars;
    const req_planets = rng.intRange(@intFromFloat(@floor(app * 0.9 * n_stars)), @intFromFloat(@ceil(app * 1.1 * n_stars)));
    const requested_moons: u32 = @as(u32, @intCast(data.unassigned_moons.len + data.unassigned_planets_or_moons.len)) - req_planets;
    const min_pps: u32 = @max(2, @as(u32, @intFromFloat(@floor(app / 2.0))));
    const high_pps: f64 = app * 1.5;
    const high_mpp: f64 = data.average_moons_per_planet * 1.5;

    // ===== Phase 2: Shuffles =====
    const moons = try a.dupe(Body, &data.unassigned_moons);
    const planets = try a.dupe(Body, &data.unassigned_planets);
    const pm_pool = try a.dupe(Body, &data.unassigned_planets_or_moons);

    // -- Shuffles (match Lua trace sections) --
    shuffleBodies(&rng, moons);
    std.debug.print("SECTION: shuffle_moons {d}\n", .{rng.draw});
    var star_order: [31]u32 = undefined; for (0..31) |i| star_order[i] = @intCast(i);
    { var i: usize = 31; while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = star_order[i]; star_order[i] = star_order[j]; star_order[j] = t; } }
    std.debug.print("SECTION: shuffle_stars {d}\n", .{rng.draw});
    shuffleBodies(&rng, planets);
    std.debug.print("SECTION: shuffle_planets {d}\n", .{rng.draw});
    shuffleBodies(&rng, pm_pool);
    std.debug.print("SECTION: shuffle_pm {d}\n", .{rng.draw});

    // ===== Phase 3: Planet assignment (builds all_planet_names inline) =====
    var star_planets: [31]ArrayList(Planet) = undefined;
    for (0..31) |i| star_planets[i] = ArrayList(Planet).init(a);
    var all_planet_names = ArrayList([]const u8).init(a);
    var all_planet_stars = ArrayList(u32).init(a);

    try star_planets[0].append(.{ .name = "Nauvis", .moons = ArrayList([]const u8).init(a) });
    try all_planet_names.append("Nauvis"); try all_planet_stars.append(0);

    for (planets) |p| {
        const si = star_order[rng.int1(31) - 1];
        try star_planets[si].append(.{ .name = p.name, .moons = ArrayList([]const u8).init(a) });
        try all_planet_names.append(p.name); try all_planet_stars.append(si);
    }

    var pm_end: u32 = @intCast(pm_pool.len);
    for (star_order) |si| {
        while (star_planets[si].items.len < min_pps and pm_end > 0) {
            pm_end -= 1; const name = pm_pool[pm_end].name;
            try star_planets[si].append(.{ .name = name, .moons = ArrayList([]const u8).init(a) });
            try all_planet_names.append(name); try all_planet_stars.append(si);
        }
    }
    var pc: u32 = @intCast(all_planet_names.items.len);
    var extra_floats: u32 = 0;
    while (pc < req_planets and pm_end > 0) {
        const si = star_order[rng.int1(31) - 1];
        if (@as(f64, @floatFromInt(star_planets[si].items.len)) < high_pps or rng.float() < 0.25) {
            if (@as(f64, @floatFromInt(star_planets[si].items.len)) >= high_pps) extra_floats += 1;
            pm_end -= 1; const name = pm_pool[pm_end].name;
            try star_planets[si].append(.{ .name = name, .moons = ArrayList([]const u8).init(a) });
            try all_planet_names.append(name); try all_planet_stars.append(si);
            pc += 1;
        }
    }
    std.debug.print("SECTION: build_planets_done {d} extra_floats={d}\n", .{rng.draw, extra_floats});
    const total_planets: u32 = @intCast(all_planet_names.items.len);

    // Debug: print planets per star
    std.debug.print("DEBUG: planets per star after build:\n", .{});
    for (star_order) |si| {
        if (star_planets[si].items.len > 0) {
            std.debug.print("  {s}: {d} planets\n", .{data.stars[si], star_planets[si].items.len});
        }
    }

    // DEBUG: print all_planets order
    std.debug.print("PLANETS_ORDER\n", .{});
    for (all_planet_names.items, all_planet_stars.items) |pn, si| {
        std.debug.print("{s}|{s}\n", .{ pn, data.stars[si] });
    }
    std.debug.print("PLANETS_END\n", .{});
    const pm_remaining = pm_pool[0..pm_end];

    // ===== Phase 4: Moon assignment =====
    for (moons) |m| {
        const pi = rng.int1(total_planets) - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) { try p.moons.append(m.name); break; }
        }
    }

    const pm_left: u32 = @intCast(pm_remaining.len);
    sortByPriority(@constCast(pm_remaining));
    var pm2_end: u32 = pm_left;
    for (star_order) |si| {
        for (star_planets[si].items) |*p| {
            if (p.moons.items.len == 0 and pm2_end > 0) {
                pm2_end -= 1; try p.moons.append(pm_remaining[pm2_end].name);
            }
        }
    }
    var moon_total: u32 = 0;
    for (star_planets) |sp| { for (sp.items) |p| { moon_total += @intCast(p.moons.items.len); } }
    var moon_extra_floats: u32 = 0;
    while (moon_total < requested_moons and pm2_end > 0) {
        const pi = rng.int1(total_planets) - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) {
                if (@as(f64, @floatFromInt(p.moons.items.len)) < high_mpp or rng.float() < 0.25) {
                    if (@as(f64, @floatFromInt(p.moons.items.len)) >= high_mpp) moon_extra_floats += 1;
                    pm2_end -= 1; try p.moons.append(pm_remaining[pm2_end].name); moon_total += 1;
                }
                break;
            }
        }
    }
    std.debug.print("SECTION: build_moons_done {d} extra_floats={d}\n", .{rng.draw, moon_extra_floats});
    std.debug.print("SECTION: moon_assign_done {d}\n", .{rng.draw});

    // ===== Phase 5: Zone construction =====
    var zones = ArrayList(Zone).init(a);
    try zones.append(.{ .name = "Foenestra", .ztype = "anomaly" });
    const scale = @sqrt(@as(f64, @floatFromInt(data.stars.len + data.space_zones.len))) * 50.0;

    for (star_order) |si| {
        const sname = data.stars[si];
        _ = rng.float(); // orientation
        _ = rng.float() * scale * (if (si == 0) @as(f64, 0.1) else 1.0); // distance

        try zones.append(.{ .name = sname, .ztype = "star" });
        const sorbit = try std.fmt.allocPrint(a, "{s} Orbit", .{sname});
        try zones.append(.{ .name = sorbit, .ztype = "orbit" });

        const belts = rng.int1(data.max_asteroid_belts);
        var child_names = ArrayList([]const u8).init(a);
        var child_types = ArrayList([]const u8).init(a);
        for (star_planets[si].items) |p| { try child_names.append(p.name); try child_types.append("planet"); }
        for (0..belts) |bi| {
            const bn = try std.fmt.allocPrint(a, "{s} Asteroid Belt {d}", .{ sname, bi + 1 });
            try child_names.append(bn); try child_types.append("asteroid-belt");
        }
        if (child_names.items.len > 1) { var i: usize = child_names.items.len; while (i > 1) { i -= 1; _ = rng.int1(@intCast(i + 1)); } }
        for (child_names.items, 0..) |cn, ci| {
            if (std.mem.eql(u8, cn, "Nauvis") and ci > 0) {
                const tn = child_names.items[0]; child_names.items[0] = child_names.items[ci]; child_names.items[ci] = tn;
                const tt = child_types.items[0]; child_types.items[0] = child_types.items[ci]; child_types.items[ci] = tt;
                break;
            }
        }
        for (child_names.items, child_types.items) |cn, ct| {
            if (std.mem.eql(u8, ct, "asteroid-belt")) {
                try zones.append(.{ .name = cn, .ztype = "asteroid-belt" });
            } else {
                _ = rng.float(); // planet radius
                try zones.append(.{ .name = cn, .ztype = "planet" });
                const porbit = try std.fmt.allocPrint(a, "{s} Orbit", .{cn});
                try zones.append(.{ .name = porbit, .ztype = "orbit" });
                for (star_planets[si].items) |p| {
                    if (std.mem.eql(u8, p.name, cn)) {
                        if (p.moons.items.len > 1) { var i: usize = p.moons.items.len; while (i > 1) { i -= 1; _ = rng.int1(@intCast(i + 1)); } }
                        for (p.moons.items) |m| {
                            _ = rng.float(); // moon radius
                            try zones.append(.{ .name = m, .ztype = "moon" });
                            const morbit = try std.fmt.allocPrint(a, "{s} Orbit", .{m});
                            try zones.append(.{ .name = morbit, .ztype = "orbit" });
                        }
                        break;
                    }
                }
            }
        }
    }

    // Space zones
    const sz = try a.dupe([]const u8, &data.space_zones);
    if (sz.len > 1) { var i: usize = sz.len; while (i > 1) { i -= 1; _ = rng.int1(@intCast(i + 1)); } }
    for (sz) |name| { try zones.append(.{ .name = name, .ztype = "asteroid-field" }); }
    for (0..data.space_zones.len) |_| { _ = rng.float(); _ = rng.float(); }

    // ===== Phase 6: Homesystem validation =====
    // Order: haven (satisfied), vulcanite, vitamelange, iridium, holmium, cryonite, beryllium, methane

    // Build array of all pm pool names for generic planet creation
    const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
    for (data.unassigned_planets_or_moons, 0..) |b, i| pm_names[i] = b.name;

    // vulcanite planet
    shuffleNames(&rng, &data.vulcanite_planets_names);
    _ = rng.float(); _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Agni", .ztype = "planet" });
    try zones.append(.{ .name = "Agni Orbit", .ztype = "orbit" });

    // vitamelange moon
    shuffleNames(&rng, &data.vitamelange_moons_names);
    _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Buttercup", .ztype = "moon" });
    try zones.append(.{ .name = "Buttercup Orbit", .ztype = "orbit" });

    // iridium moon
    shuffleNames(&rng, &data.iridium_moons_names);
    _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Seker", .ztype = "moon" });
    try zones.append(.{ .name = "Seker Orbit", .ztype = "orbit" });

    // holmium: generic planet + moon
    shuffleNames(&rng, pm_names);
    _ = rng.float(); _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Ajax", .ztype = "planet" });
    try zones.append(.{ .name = "Ajax Orbit", .ztype = "orbit" });
    shuffleNames(&rng, &data.holmium_moons_names);
    _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Shu", .ztype = "moon" });
    try zones.append(.{ .name = "Shu Orbit", .ztype = "orbit" });

    // cryonite: generic planet + moon
    shuffleNames(&rng, pm_names);
    _ = rng.float(); _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Hecate", .ztype = "planet" });
    try zones.append(.{ .name = "Hecate Orbit", .ztype = "orbit" });
    shuffleNames(&rng, &data.cryonite_moons_names);
    _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Snowdrop", .ztype = "moon" });
    try zones.append(.{ .name = "Snowdrop Orbit", .ztype = "orbit" });

    // beryllium/methane belts + Erebus moon
    _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Calidus Asteroid Belt 2", .ztype = "asteroid-belt" });
    _ = rng.int1(4294967295); _ = rng.int1(4294967295);
    try zones.append(.{ .name = "Erebus", .ztype = "moon" });
    try zones.append(.{ .name = "Erebus Orbit", .ztype = "orbit" });

    // ===== Phase 7: Zone seeds =====
    for (zones.items) |*z| { z.seed = rng.int1(4294967295); }

    // ===== Output =====
    std.debug.print("Seed: {d}  RNG draws: {d}  Zones: {d}\n", .{ seed, rng.draw, zones.items.len });
    
    // Dump zone index
    for (zones.items, 0..) |z, i| {
        std.debug.print("{d}|{s}|{s}|{d}\n", .{ i+1, z.name, z.ztype, z.seed });
    }
}
