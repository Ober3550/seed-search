/// SE universe generator — extracted from main.zig as a reusable module.
/// Call generateUniverse() to get the zone list for a given seed.

const std = @import("std");
pub fn ArrayList(comptime T: type) type { return std.array_list.AlignedManaged(T, null); }

pub const Rng = struct {
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
pub const Zone = struct { name: []const u8, ztype: []const u8, seed: u32 = 0 };

pub const Universe = struct {
    zones: ArrayList(Zone),
    draws: u32,
    k2: bool,
};

fn shuffleBodies(rng: *Rng, slice: []Body) void {
    var i: usize = slice.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = slice[i]; slice[i] = slice[j]; slice[j] = t; }
}

fn shufflePlanets(rng: *Rng, slice: []Planet) void {
    var i: usize = slice.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = slice[i]; slice[i] = slice[j]; slice[j] = t; }
}

fn shuffleNames(rng: *Rng, names: [][]const u8) void {
    var i: usize = names.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = names[i]; names[i] = names[j]; names[j] = t; }
}

fn pickShuffledName(rng: *Rng, alloc: std.mem.Allocator, const_names: []const []const u8, zones: ArrayList(Zone)) ![]const u8 {
    const names = try alloc.alloc([]const u8, const_names.len);
    @memcpy(names, const_names);
    shuffleNames(rng, names);
    var result: ?[]const u8 = null;
    for (names) |n| {
        var used = false;
        for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
        if (!used) result = n;
    }
    return result orelse @panic("No unused name in pool");
}

fn shuffleMoons(rng: *Rng, moons: [][]const u8) void {
    var i: usize = moons.len;
    while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = moons[i]; moons[i] = moons[j]; moons[j] = t; }
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

fn countBelts(zones: ArrayList(Zone), star_name: []const u8) u32 {
    var count: u32 = 0;
    const marker = " Asteroid Belt ";
    for (zones.items) |z| {
        if (z.name.len > star_name.len + marker.len and std.mem.startsWith(u8, z.name, star_name)) {
            const rest = z.name[star_name.len..];
            if (std.mem.startsWith(u8, rest, marker)) {
                const num_part = rest[marker.len..];
                var is_num = num_part.len > 0;
                for (num_part) |c| { if (c < '0' or c > '9') { is_num = false; break; } }
                if (is_num) count += 1;
            }
        }
    }
    return count;
}

pub fn generateUniverse(alloc: std.mem.Allocator, seed: u32, k2_enabled: bool) !Universe {
    const a = alloc;
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

    shuffleBodies(&rng, moons);
    var star_order: [31]u32 = undefined; for (0..31) |i| star_order[i] = @intCast(i);
    { var i: usize = 31; while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = star_order[i]; star_order[i] = star_order[j]; star_order[j] = t; } }
    shuffleBodies(&rng, planets);
    shuffleBodies(&rng, pm_pool);

    // ===== Phase 3: Planet assignment =====
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
    while (pc < req_planets and pm_end > 0) {
        const si = star_order[rng.int1(31) - 1];
        if (@as(f64, @floatFromInt(star_planets[si].items.len)) < high_pps or rng.float() < 0.25) {
            pm_end -= 1; const name = pm_pool[pm_end].name;
            try star_planets[si].append(.{ .name = name, .moons = ArrayList([]const u8).init(a) });
            try all_planet_names.append(name); try all_planet_stars.append(si);
            pc += 1;
        }
    }
    const total_planets: u32 = @intCast(all_planet_names.items.len);

    // ===== Phase 4: Moon assignment =====
    for (moons) |m| {
        const pi = rng.int1(total_planets) - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) { try p.moons.append(m.name); break; }
        }
    }

    var pm2_end: u32 = pm_end;
    for (all_planet_names.items, all_planet_stars.items) |pname, si| {
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) {
                if (@as(f64, @floatFromInt(p.moons.items.len)) < high_mpp and pm2_end > 0) {
                    pm2_end -= 1; try p.moons.append(pm_pool[pm2_end].name);
                }
                break;
            }
        }
    }
    sortByPriority(pm_pool[0..pm2_end]);
    var moon_total: u32 = 0;
    for (star_planets) |sp| { for (sp.items) |p| { moon_total += @intCast(p.moons.items.len); } }
    while (moon_total < requested_moons and pm2_end > 0) {
        const pi = rng.int1(total_planets) - 1;
        const si = all_planet_stars.items[pi];
        const pname = all_planet_names.items[pi];
        for (star_planets[si].items) |*p| {
            if (std.mem.eql(u8, p.name, pname)) {
                if (@as(f64, @floatFromInt(p.moons.items.len)) < high_mpp or rng.float() < 0.25) {
                    pm2_end -= 1; try p.moons.append(pm_pool[pm2_end].name); moon_total += 1;
                }
                break;
            }
        }
    }

    // ===== Phase 5: Zone construction =====
    var zones = ArrayList(Zone).init(a);
    try zones.append(.{ .name = "Foenestra", .ztype = "anomaly" });
    const scale = @sqrt(@as(f64, @floatFromInt(data.stars.len + data.space_zones.len))) * 50.0;

    for (star_order) |si| {
        const sname = data.stars[si];
        _ = rng.float(); // orientation
        _ = rng.float() * scale * (if (std.mem.eql(u8, sname, "Calidus")) @as(f64, 0.1) else 1.0); // distance

        try zones.append(.{ .name = sname, .ztype = "star" });
        const sorbit = try std.fmt.allocPrint(a, "{s} Orbit", .{sname});
        try zones.append(.{ .name = sorbit, .ztype = "orbit" });

        const belts = rng.int1(data.max_asteroid_belts);
        const n_planets = star_planets[si].items.len;
        if (n_planets > 1) {
            shufflePlanets(&rng, star_planets[si].items);
        }

        var child_names = ArrayList([]const u8).init(a);
        var child_types = ArrayList([]const u8).init(a);
        for (star_planets[si].items) |p| {
            try child_names.append(p.name);
            try child_types.append("planet");
        }

        for (0..belts) |bi| {
            const lua_pos = @as(usize, @intFromFloat(@floor(0.4 + rng.float() + @as(f64, @floatFromInt(child_names.items.len)) * @as(f64, @floatFromInt(bi + 1)) / @as(f64, @floatFromInt(belts)))));
            const bn = try std.fmt.allocPrint(a, "{s} Asteroid Belt {d}", .{ sname, bi + 1 });
            try child_names.insert(lua_pos - 1, bn);
            try child_types.insert(lua_pos - 1, "asteroid-belt");
        }

        for (child_names.items, 0..) |cn, ci| {
            if (std.mem.eql(u8, cn, "Nauvis") and ci > 0) {
                const tn = child_names.items[0]; child_names.items[0] = child_names.items[ci]; child_names.items[ci] = tn;
                const tt = child_types.items[0]; child_types.items[0] = child_types.items[ci]; child_types.items[ci] = tt;
                break;
            }
        }

        var asteroid_belts: u32 = 0;
        for (child_names.items, child_types.items) |cn, ct| {
            if (std.mem.eql(u8, ct, "asteroid-belt")) {
                asteroid_belts += 1;
                const belt_name = try std.fmt.allocPrint(a, "{s} Asteroid Belt {d}", .{ sname, asteroid_belts });
                try zones.append(.{ .name = belt_name, .ztype = "asteroid-belt" });
            } else {
                _ = rng.float(); // planet radius
                try zones.append(.{ .name = cn, .ztype = "planet" });
                const porbit = try std.fmt.allocPrint(a, "{s} Orbit", .{cn});
                try zones.append(.{ .name = porbit, .ztype = "orbit" });
                for (star_planets[si].items) |p| {
                    if (std.mem.eql(u8, p.name, cn)) {
                        if (p.moons.items.len > 1) {
                            shuffleMoons(&rng, p.moons.items);
                        }
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
    if (sz.len > 1) { shuffleNames(&rng, sz); }
    for (sz) |name| { try zones.append(.{ .name = name, .ztype = "asteroid-field" }); }
    for (0..data.space_zones.len) |_| { _ = rng.float(); _ = rng.float(); }

    // ===== Phase 5b: Assign seeds to all zones =====
    for (zones.items) |*z| {
        z.seed = rng.int1(4294967295);
    }

    // ===== Phase 6: Homesystem validation =====
    var available_planets = ArrayList([]const u8).init(a);
    var available_belts = ArrayList([]const u8).init(a);
    var calidus_all_non_homeworld = ArrayList([]const u8).init(a);
    const calidus_si = for (star_order) |s| {
        if (std.mem.eql(u8, data.stars[s], "Calidus")) break s;
    } else @as(u32, 0);
    for (star_planets[calidus_si].items) |p| {
        if (!std.mem.eql(u8, p.name, "Nauvis")) {
            try available_planets.append(p.name);
            try calidus_all_non_homeworld.append(p.name);
        }
    }
    const pre_belts = countBelts(zones, "Calidus");
    for (0..pre_belts) |i| {
        const bn = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{i + 1});
        try available_belts.append(bn);
    }

    // haven
    {
        const names = try a.alloc([]const u8, data.haven_moons_names.len);
        for (data.haven_moons_names, 0..) |n, idx| names[idx] = n;
        { var i: usize = names.len; while (i > 1) { i -= 1; const j = rng.int1(@intCast(i + 1)) - 1; const t = names[i]; names[i] = names[j]; names[j] = t; } }
        const name = blk: {
            var result: ?[]const u8 = null;
            for (names) |n| {
                var used = false;
                for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
                if (!used) result = n;
            }
            break :blk result orelse @panic("no unused");
        };
        try zones.append(.{ .name = name, .ztype = "moon", .seed = rng.int1(4294967295) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = "orbit", .seed = rng.int1(4294967295) });
    }

    // vulcanite
    {
        const name = try pickShuffledName(&rng, a, &data.vulcanite_planets_names, zones);
        try calidus_all_non_homeworld.append(name);
        try zones.append(.{ .name = name, .ztype = "planet", .seed = rng.int1(4294967295) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = "orbit", .seed = rng.int1(4294967295) });
    }

    // vitamelange
    {
        _ = if (available_planets.items.len > 0) blk: { _ = available_planets.orderedRemove(0); break :blk true; } else false;
        const name = try pickShuffledName(&rng, a, &data.vitamelange_moons_names, zones);
        try zones.append(.{ .name = name, .ztype = "moon", .seed = rng.int1(4294967295) });
        const orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{name});
        try zones.append(.{ .name = orbit_name, .ztype = "orbit", .seed = rng.int1(4294967295) });
    }

    // Helper: make a generic planet from unassigned pool, or reuse existing
    const makeGenericPlanet = struct {
        fn call(ap: *ArrayList([]const u8), rzones: *ArrayList(Zone), rng2: *Rng, alloc2: std.mem.Allocator, cahnw: *ArrayList([]const u8)) !void {
            const used = if (ap.items.len > 0) blk: { _ = ap.orderedRemove(0); break :blk true; } else false;
            if (!used) {
                const pm_names = try alloc2.alloc([]const u8, data.unassigned_planets_or_moons.len);
                for (data.unassigned_planets_or_moons, 0..) |b, i| pm_names[i] = b.name;
                shuffleNames(rng2, pm_names);
                const planet_name = blk: {
                    var result: ?[]const u8 = null;
                    for (pm_names) |n| {
                        var used2 = false;
                        for (rzones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used2 = true; break; } }
                        if (!used2) result = n;
                    }
                    break :blk result orelse @panic("no unused");
                };
                _ = rng2.float(); // radius
                try cahnw.append(planet_name);
                try rzones.append(.{ .name = planet_name, .ztype = "planet", .seed = rng2.int1(4294967295) });
                const planet_orbit_name = try std.fmt.allocPrint(alloc2, "{s} Orbit", .{planet_name});
                try rzones.append(.{ .name = planet_orbit_name, .ztype = "orbit", .seed = rng2.int1(4294967295) });
            }
        }
    }.call;

    // Helper: add special moon
    const addSpecialMoon = struct {
        fn call(moon_names: []const []const u8, rzones: *ArrayList(Zone), rng2: *Rng, alloc2: std.mem.Allocator) !void {
            const name = try pickShuffledName(rng2, alloc2, moon_names, rzones.*);
            try rzones.append(.{ .name = name, .ztype = "moon", .seed = rng2.int1(4294967295) });
            const orbit_name = try std.fmt.allocPrint(alloc2, "{s} Orbit", .{name});
            try rzones.append(.{ .name = orbit_name, .ztype = "orbit", .seed = rng2.int1(4294967295) });
        }
    }.call;

    // iridium
    try makeGenericPlanet(&available_planets, &zones, &rng, a, &calidus_all_non_homeworld);
    try addSpecialMoon(&data.iridium_moons_names, &zones, &rng, a);

    // holmium
    try makeGenericPlanet(&available_planets, &zones, &rng, a, &calidus_all_non_homeworld);
    try addSpecialMoon(&data.holmium_moons_names, &zones, &rng, a);

    // cryonite
    try makeGenericPlanet(&available_planets, &zones, &rng, a, &calidus_all_non_homeworld);
    try addSpecialMoon(&data.cryonite_moons_names, &zones, &rng, a);

    // beryllium
    {
        const used = if (available_belts.items.len > 0) blk: {
            _ = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            try zones.append(.{ .name = belt_name, .ztype = "asteroid-belt", .seed = rng.int1(4294967295) });
        }
    }

    // methane
    {
        const used = if (available_belts.items.len > 0) blk: {
            _ = available_belts.orderedRemove(0);
            break :blk true;
        } else false;
        if (!used) {
            const existing = countBelts(zones, "Calidus");
            const belt_name = try std.fmt.allocPrint(a, "Calidus Asteroid Belt {d}", .{existing + 1});
            try zones.append(.{ .name = belt_name, .ztype = "asteroid-belt", .seed = rng.int1(4294967295) });
        }
    }

    // kr-imersite (K2 only)
    if (k2_enabled) {
        if (available_planets.items.len > 0) {
            _ = available_planets.orderedRemove(0);
        } else {
            if (calidus_all_non_homeworld.items.len > 1) {
                shuffleNames(&rng, calidus_all_non_homeworld.items);
            }
        }

        const pm_names = try a.alloc([]const u8, data.unassigned_planets_or_moons.len);
        for (data.unassigned_planets_or_moons, 0..) |b, idx| pm_names[idx] = b.name;
        shuffleNames(&rng, pm_names);
        const moon_name = blk: {
            for (pm_names) |n| {
                var used = false;
                for (zones.items) |z| { if (std.mem.eql(u8, z.name, n)) { used = true; break; } }
                if (!used) {
                    for (data.unassigned_planets_or_moons) |b| {
                        if (std.mem.eql(u8, b.name, n)) {
                            if (b.primary_resource == null) break :blk n;
                            break;
                        }
                    }
                }
            }
            @panic("no unused unassigned body without primary_resource");
        };
        _ = rng.intRange(80, 120);
        try zones.append(.{ .name = moon_name, .ztype = "moon", .seed = rng.int1(4294967295) });
        const moon_orbit_name = try std.fmt.allocPrint(a, "{s} Orbit", .{moon_name});
        try zones.append(.{ .name = moon_orbit_name, .ztype = "orbit", .seed = rng.int1(4294967295) });
    }

    return .{ .zones = zones, .draws = rng.draw, .k2 = k2_enabled };
}
