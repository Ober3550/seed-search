//! Regression tests for the data-driven planet generator. The vectors are
//! live-game values (Factorio 2.0.77, map seed 341) captured with
//! calibration/sa-probe/probe_surface.py: the tile the game placed at a
//! position, and the value calculate_tile_properties returned for a named
//! expression. Positions where the game's tile-transition correction pass
//! overrode the raw competition are not used.
const std = @import("std");
const sa_data = @import("sa_data.zig");
const prog = @import("sa_program.zig");
const surface = @import("sa_surface.zig");

const MAP_SEED = 341;

const TileVec = struct { x: i32, y: i32, tile: []const u8 };
const ValueVec = struct { x: f32, y: f32, v: f32 };

fn checkTiles(planet_name: []const u8, vecs: []const TileVec) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.load(a);
    const planet = data.planet(planet_name).?;
    var msg: []const u8 = "";
    var s = surface.Surface.init(a, &data, planet, MAP_SEED, .{}, &msg) catch |e| {
        std.debug.print("{s}: {s}\n", .{ planet_name, msg });
        return e;
    };
    for (vecs) |v| {
        var t: [1]u16 = undefined;
        s.tileRow(v.x, v.y, &t);
        try std.testing.expectEqualStrings(v.tile, planet.tiles[t[0]].name);
    }
}

fn checkValues(planet_name: []const u8, expr: []const u8, tolerance: f32, vecs: []const ValueVec) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.load(a);
    const planet = data.planet(planet_name).?;
    const p = try prog.compile(a, &data, planet, MAP_SEED, .{}, &.{expr}, null);
    var ws = try p.workspace(a);
    for (vecs) |v| {
        p.eval(&ws, &.{v.x}, &.{v.y});
        try std.testing.expectApproxEqAbs(v.v, p.out(&ws, 0)[0], tolerance);
    }
}

test "constant folding follows the DSL's operator rules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.load(a);
    var c = try prog.Compiler.init(a, &data, data.planet("fulgora").?, MAP_SEED, .{});
    const cases = [_]struct { []const u8, f64 }{
        .{ "2 + 3 * 4", 14 },
        .{ "(2 + 3) * 4", 20 },
        .{ "-2 ^ 2", -4 }, // unary minus binds looser than ^
        .{ "2 ^ -1", 0.5 },
        .{ "2 ^ 3 ^ 2", 512 }, // right associative
        .{ "10 / 4", 2.5 },
        .{ "min(4, 2, 3) + max(1, 7)", 9 },
        .{ "clamp(10, 0, 4)", 4 },
        .{ "if(3 > 2, 5, -5)", 5 },
        .{ "if(3 < 2, 5, -5)", -5 },
        .{ "(1 == 2) + (1 != 2)", 1 },
        .{ "5 & 3", 1 },
        .{ "lerp(10, 20, 0.25)", 12.5 }, // a data-defined noise function
        .{ "slider_to_linear(1, -50, 50)", 0 },
    };
    for (cases) |case| {
        const v = try c.expr(case[0]);
        try std.testing.expectApproxEqAbs(case[1], c.constant(v).?, 1e-6);
    }
    // a planet's surface seed is the map seed + crc32(planet name)
    try std.testing.expectEqual(@as(f64, 2967579351), c.constant(try c.expr("map_seed")).?);
}

test "every Space Age planet compiles from the data file" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.load(a);
    for ([_][]const u8{ "fulgora", "vulcanus", "gleba", "aquilo" }) |name| {
        _ = try surface.Surface.init(a, &data, data.planet(name).?, MAP_SEED, .{}, null);
    }
}


test "fulgora: tiles match the game" {
    try checkTiles("fulgora", &.{
        .{ .x = -260, .y = -220, .tile = "oil-ocean-deep" },
        .{ .x = -480, .y = -180, .tile = "fulgoran-dust" },
        .{ .x = -80, .y = -160, .tile = "fulgoran-sand" },
        .{ .x = 380, .y = -140, .tile = "oil-ocean-shallow" },
        .{ .x = -420, .y = -120, .tile = "fulgoran-dunes" },
        .{ .x = -420, .y = -100, .tile = "fulgoran-rock" },
        .{ .x = 160, .y = -80, .tile = "fulgoran-paving" },
        .{ .x = 260, .y = -80, .tile = "fulgoran-conduit" },
        .{ .x = 200, .y = -40, .tile = "fulgoran-machinery" },
        .{ .x = -140, .y = -20, .tile = "fulgoran-walls" },
        .{ .x = 280, .y = 40, .tile = "fulgoran-sand" },
        .{ .x = 300, .y = 60, .tile = "fulgoran-dust" },
        .{ .x = 340, .y = 80, .tile = "fulgoran-dunes" },
        .{ .x = 240, .y = 160, .tile = "oil-ocean-deep" },
        .{ .x = -240, .y = 180, .tile = "oil-ocean-shallow" },
        .{ .x = 340, .y = 180, .tile = "fulgoran-paving" },
        .{ .x = -280, .y = 200, .tile = "fulgoran-conduit" },
        .{ .x = 340, .y = 220, .tile = "fulgoran-machinery" },
        .{ .x = 400, .y = 220, .tile = "fulgoran-rock" },
        .{ .x = 400, .y = 320, .tile = "fulgoran-walls" },
    });
}

test "fulgora: fulgora_elevation matches the game" {
    try checkValues("fulgora", "fulgora_elevation", 0.01, &.{
        .{ .x = -420, .y = -340, .v = 32.9443512 },
        .{ .x = -420, .y = -200, .v = 41.3673515 },
        .{ .x = -420, .y = -60, .v = 43.4222717 },
        .{ .x = -420, .y = 80, .v = -25.4773483 },
        .{ .x = -420, .y = 220, .v = 25.6011009 },
        .{ .x = -420, .y = 360, .v = 7.1620636 },
    });
}

test "vulcanus: tiles match the game" {
    try checkTiles("vulcanus", &.{
        .{ .x = -220, .y = -380, .tile = "volcanic-ash-cracks" },
        .{ .x = -400, .y = -340, .tile = "volcanic-smooth-stone-warm" },
        .{ .x = -140, .y = -340, .tile = "volcanic-ash-light" },
        .{ .x = -60, .y = -340, .tile = "volcanic-ash-dark" },
        .{ .x = -140, .y = -320, .tile = "volcanic-ash-flats" },
        .{ .x = 440, .y = -260, .tile = "volcanic-cracks-warm" },
        .{ .x = 220, .y = -240, .tile = "volcanic-cracks-hot" },
        .{ .x = 440, .y = -240, .tile = "volcanic-smooth-stone" },
        .{ .x = -220, .y = -220, .tile = "volcanic-cracks" },
        .{ .x = -100, .y = -220, .tile = "volcanic-ash-soil" },
        .{ .x = 340, .y = -220, .tile = "lava" },
        .{ .x = -80, .y = -200, .tile = "volcanic-pumice-stones" },
        .{ .x = 0, .y = -180, .tile = "volcanic-ash-light" },
        .{ .x = 240, .y = -160, .tile = "lava-hot" },
        .{ .x = 160, .y = -120, .tile = "volcanic-smooth-stone-warm" },
        .{ .x = -140, .y = -100, .tile = "volcanic-ash-dark" },
        .{ .x = -120, .y = -100, .tile = "volcanic-ash-cracks" },
        .{ .x = -20, .y = -100, .tile = "volcanic-ash-flats" },
        .{ .x = -60, .y = -60, .tile = "volcanic-ash-soil" },
        .{ .x = -80, .y = -40, .tile = "volcanic-pumice-stones" },
        .{ .x = 340, .y = -40, .tile = "volcanic-cracks-warm" },
        .{ .x = 140, .y = 0, .tile = "volcanic-cracks-hot" },
        .{ .x = 220, .y = 0, .tile = "volcanic-cracks" },
        .{ .x = 340, .y = 0, .tile = "volcanic-smooth-stone" },
        .{ .x = -240, .y = 20, .tile = "volcanic-soil-dark" },
        .{ .x = -280, .y = 40, .tile = "volcanic-soil-light" },
        .{ .x = 100, .y = 60, .tile = "lava" },
        .{ .x = -420, .y = 100, .tile = "volcanic-folds-flat" },
        .{ .x = 100, .y = 120, .tile = "lava-hot" },
        .{ .x = 120, .y = 200, .tile = "volcanic-folds" },
        .{ .x = -40, .y = 220, .tile = "volcanic-folds-warm" },
        .{ .x = 200, .y = 260, .tile = "volcanic-folds-flat" },
        .{ .x = -380, .y = 280, .tile = "volcanic-soil-dark" },
        .{ .x = -280, .y = 280, .tile = "volcanic-soil-light" },
        .{ .x = 80, .y = 300, .tile = "volcanic-jagged-ground" },
        .{ .x = 100, .y = 360, .tile = "volcanic-folds" },
        .{ .x = 100, .y = 400, .tile = "volcanic-folds-warm" },
        .{ .x = 480, .y = 420, .tile = "volcanic-jagged-ground" },
    });
}

test "vulcanus: vulcanus_elev matches the game" {
    try checkValues("vulcanus", "vulcanus_elev", 0.01, &.{
        .{ .x = -420, .y = -340, .v = 8.37364388 },
        .{ .x = -420, .y = -200, .v = 168.224289 },
        .{ .x = -420, .y = -60, .v = 24.3832245 },
        .{ .x = -420, .y = 80, .v = 261.62677 },
        .{ .x = -420, .y = 220, .v = 501.810364 },
        .{ .x = -420, .y = 360, .v = 862.449707 },
    });
}

test "gleba: tiles match the game" {
    try checkTiles("gleba", &.{
        .{ .x = -360, .y = -320, .tile = "midland-turquoise-bark" },
        .{ .x = -300, .y = -320, .tile = "wetland-yumako" },
        .{ .x = -160, .y = -320, .tile = "lowland-olive-blubber-2" },
        .{ .x = -240, .y = -300, .tile = "lowland-olive-blubber" },
        .{ .x = -120, .y = -300, .tile = "pit-rock" },
        .{ .x = -440, .y = -280, .tile = "midland-turquoise-bark-2" },
        .{ .x = -240, .y = -280, .tile = "natural-yumako-soil" },
        .{ .x = -180, .y = -260, .tile = "wetland-green-slime" },
        .{ .x = -180, .y = -240, .tile = "lowland-olive-blubber-3" },
        .{ .x = -160, .y = -240, .tile = "wetland-light-green-slime" },
        .{ .x = 80, .y = -240, .tile = "wetland-yumako" },
        .{ .x = 440, .y = -240, .tile = "midland-cracked-lichen-dark" },
        .{ .x = 40, .y = -220, .tile = "lowland-olive-blubber-2" },
        .{ .x = -360, .y = -200, .tile = "lowland-brown-blubber" },
        .{ .x = 320, .y = -180, .tile = "gleba-deep-lake" },
        .{ .x = -160, .y = -160, .tile = "wetland-light-green-slime" },
        .{ .x = -80, .y = -160, .tile = "wetland-green-slime" },
        .{ .x = 180, .y = -160, .tile = "lowland-olive-blubber-3" },
        .{ .x = 380, .y = -160, .tile = "lowland-cream-cauliflower-2" },
        .{ .x = -260, .y = -140, .tile = "lowland-olive-blubber" },
        .{ .x = 360, .y = -120, .tile = "natural-yumako-soil" },
        .{ .x = 440, .y = -120, .tile = "midland-turquoise-bark" },
        .{ .x = -460, .y = -100, .tile = "lowland-pale-green" },
        .{ .x = -40, .y = -80, .tile = "midland-turquoise-bark-2" },
        .{ .x = -240, .y = -60, .tile = "lowland-brown-blubber" },
        .{ .x = 40, .y = -60, .tile = "highland-yellow-rock" },
        .{ .x = 240, .y = -60, .tile = "wetland-blue-slime" },
        .{ .x = -360, .y = -40, .tile = "lowland-dead-skin-2" },
        .{ .x = 20, .y = -40, .tile = "highland-dark-rock" },
        .{ .x = -60, .y = -20, .tile = "lowland-pale-green" },
        .{ .x = 40, .y = -20, .tile = "highland-yellow-rock" },
        .{ .x = 60, .y = -20, .tile = "highland-dark-rock-2" },
        .{ .x = -180, .y = 0, .tile = "lowland-cream-cauliflower-2" },
        .{ .x = -40, .y = 0, .tile = "midland-cracked-lichen-dark" },
        .{ .x = -120, .y = 20, .tile = "wetland-light-dead-skin" },
        .{ .x = -400, .y = 40, .tile = "wetland-dead-skin" },
        .{ .x = 0, .y = 40, .tile = "midland-cracked-lichen-dull" },
        .{ .x = 80, .y = 40, .tile = "highland-dark-rock-2" },
        .{ .x = -220, .y = 60, .tile = "lowland-dead-skin" },
        .{ .x = 200, .y = 60, .tile = "natural-jellynut-soil" },
    });
}

test "gleba: gleba_elevation matches the game" {
    try checkValues("gleba", "gleba_elevation", 0.01, &.{
        .{ .x = -420, .y = -340, .v = 124.798035 },
        .{ .x = -420, .y = -200, .v = 10.828661 },
        .{ .x = -420, .y = -60, .v = 35.9488792 },
        .{ .x = -420, .y = 80, .v = 68.3321686 },
        .{ .x = -420, .y = 220, .v = -1.9307704 },
        .{ .x = -420, .y = 360, .v = 5.860322 },
    });
}

test "aquilo: tiles match the game" {
    try checkTiles("aquilo", &.{
        .{ .x = 480, .y = -220, .tile = "snow-flat" },
        .{ .x = -380, .y = -160, .tile = "ammoniacal-ocean-2" },
        .{ .x = -280, .y = -160, .tile = "ammoniacal-ocean" },
        .{ .x = -320, .y = -140, .tile = "snow-crests" },
        .{ .x = 0, .y = -40, .tile = "snow-patchy" },
        .{ .x = 0, .y = -20, .tile = "snow-lumpy" },
        .{ .x = 20, .y = -20, .tile = "snow-flat" },
        .{ .x = 40, .y = -20, .tile = "ice-rough" },
        .{ .x = 40, .y = 0, .tile = "snow-crests" },
        .{ .x = -60, .y = 20, .tile = "brash-ice" },
        .{ .x = -20, .y = 20, .tile = "ice-smooth" },
        .{ .x = 20, .y = 20, .tile = "ice-smooth" },
        .{ .x = -40, .y = 60, .tile = "brash-ice" },
        .{ .x = 0, .y = 60, .tile = "snow-patchy" },
        .{ .x = -40, .y = 80, .tile = "snow-lumpy" },
        .{ .x = -80, .y = 160, .tile = "ammoniacal-ocean-2" },
        .{ .x = -460, .y = 180, .tile = "ammoniacal-ocean" },
        .{ .x = -420, .y = 200, .tile = "ice-rough" },
    });
}

test "aquilo: aquilo_elevation matches the game" {
    try checkValues("aquilo", "aquilo_elevation", 0.01, &.{
        .{ .x = -420, .y = -340, .v = -17.4929504 },
        .{ .x = -420, .y = -200, .v = -3.4046905 },
        .{ .x = -420, .y = -60, .v = -14.881485 },
        .{ .x = -420, .y = 80, .v = -14.8072052 },
        .{ .x = -420, .y = 220, .v = 1.3809098 },
        .{ .x = -420, .y = 360, .v = -6.25465488 },
    });
}

const ResourceVec = struct { x: i32, y: i32, name: []const u8, amount: u32 };

fn checkResources(planet_name: []const u8, vecs: []const ResourceVec) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.load(a);
    const planet = data.planet(planet_name).?;
    var w = try surface.World.init(a, &data, planet, MAP_SEED, .{}, null);
    const chunk = try a.create(surface.ChunkData);
    for (vecs) |v| {
        const cx = @divFloor(v.x, surface.CHUNK);
        const cy = @divFloor(v.y, surface.CHUNK);
        w.chunk(cx, cy, chunk);
        const i: usize = @intCast((v.y - cy * surface.CHUNK) * surface.CHUNK + (v.x - cx * surface.CHUNK));
        try std.testing.expect(chunk.resource[i] != surface.NO_RESOURCE);
        try std.testing.expectEqualStrings(v.name, planet.resources[chunk.resource[i]].name);
        try std.testing.expectEqual(v.amount, chunk.amount[i]);
    }
}


test "vulcanus: resource entities and amounts match the game" {
    try checkResources("vulcanus", &.{
        .{ .x = -127, .y = 97, .name = "calcite", .amount = 63 },
        .{ .x = -132, .y = 134, .name = "calcite", .amount = 892 },
        .{ .x = 65, .y = 393, .name = "calcite", .amount = 9502 },
        .{ .x = 75, .y = 415, .name = "calcite", .amount = 2629 },
        .{ .x = 475, .y = 459, .name = "calcite", .amount = 611 },
        .{ .x = 181, .y = -499, .name = "coal", .amount = 494 },
        .{ .x = -132, .y = -356, .name = "coal", .amount = 4164 },
        .{ .x = -69, .y = -82, .name = "coal", .amount = 295 },
        .{ .x = -74, .y = -68, .name = "coal", .amount = 735 },
        .{ .x = -89, .y = -54, .name = "coal", .amount = 338 },
        .{ .x = 259, .y = -475, .name = "tungsten-ore", .amount = 127 },
        .{ .x = 434, .y = -292, .name = "tungsten-ore", .amount = 6412 },
        .{ .x = 452, .y = -279, .name = "tungsten-ore", .amount = 4874 },
        .{ .x = 415, .y = -262, .name = "tungsten-ore", .amount = 853 },
        .{ .x = -374, .y = -58, .name = "tungsten-ore", .amount = 335 },
    });
}

test "gleba: resource entities and amounts match the game" {
    try checkResources("gleba", &.{
        .{ .x = -297, .y = -500, .name = "stone", .amount = 142 },
        .{ .x = 53, .y = -12, .name = "stone", .amount = 223 },
        .{ .x = 60, .y = -2, .name = "stone", .amount = 763 },
        .{ .x = 62, .y = 8, .name = "stone", .amount = 208 },
        .{ .x = -444, .y = 300, .name = "stone", .amount = 145 },
    });
}

test "aquilo: resource entities and amounts match the game" {
    try checkResources("aquilo", &.{
        .{ .x = -319, .y = -164, .name = "fluorine-vent", .amount = 255560 },
        .{ .x = -327, .y = -160, .name = "fluorine-vent", .amount = 253547 },
        .{ .x = -315, .y = -141, .name = "fluorine-vent", .amount = 465351 },
        .{ .x = -86, .y = -134, .name = "fluorine-vent", .amount = 354215 },
        .{ .x = -42, .y = -68, .name = "fluorine-vent", .amount = 420000 },
        .{ .x = 482, .y = -251, .name = "lithium-brine", .amount = 339031 },
        .{ .x = 469, .y = -233, .name = "lithium-brine", .amount = 496562 },
        .{ .x = 494, .y = -35, .name = "lithium-brine", .amount = 266945 },
        .{ .x = -442, .y = 370, .name = "lithium-brine", .amount = 140648 },
        .{ .x = -428, .y = 390, .name = "lithium-brine", .amount = 566757 },
    });
}
