//! Regression tests for Space Exploration surfaces. The vectors are live-game
//! values (Factorio 2.0.77 with Space Exploration 0.7.57 and alien-biomes
//! 0.7.4, map seed 1000, the moon Hermes) captured with
//! calibration/sa-probe/probe_se_zone.py --names: what calculate_tile_properties
//! returned for an entity's placement probability over a 16 x 16 grid of
//! positions, evaluated - as the game does - as one column.
//!
//! They pin what the alien-biomes entities exercise and the Space Age planets
//! do not: random_penalty drawing only where its source is positive, from a
//! stream seeded with a map-seed-sized seed parameter (added to y as a
//! float), and multioctave_noise with a fractional octave count.
const std = @import("std");
const sa_data = @import("sa_data.zig");
const prog = @import("sa_program.zig");
const terrain = @import("terrain.zig");

const ZONE_SEED = 258057357;
const GRID = .{ .x0 = -320, .y0 = 96, .n = 16, .step = 8 };

/// The surface's autoplace controls as the game reported them.
fn control(_: *const anyopaque, name: []const u8, field: []const u8) f64 {
    const eq = std.mem.eql;
    const freq = eq(u8, field, "frequency");
    if (eq(u8, name, "starting-area")) return 0.5;
    if (eq(u8, name, "hot") or eq(u8, name, "cold")) return if (freq) 8.619887351989746 else 1;
    if (eq(u8, name, "trees")) return if (freq) 0.800000011920929 else if (eq(u8, field, "size")) 0.6600000262260437 else 1;
    if (eq(u8, name, "rocks")) return if (freq) 3.4013595581054688 else if (eq(u8, field, "size")) 0.50701904296875 else 0.32430145144462585;
    return if (eq(u8, field, "bias")) 0 else 1;
}

fn checkColumn(expr: []const u8, want: []const f32) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.loadSe(a);
    const planet = data.planet("se-zone").?;
    var msg: []const u8 = "";
    const p = prog.compile(a, &data, planet, ZONE_SEED, .{
        .starting_lake = terrain.startingLakeCenter(ZONE_SEED),
        .lookup = control,
    }, &.{expr}, &msg) catch |e| {
        std.debug.print("{s}: {s}\n", .{ expr, msg });
        return e;
    };
    const n = GRID.n * GRID.n;
    try std.testing.expectEqual(n, want.len);
    var xs: [n]f32 = undefined;
    var ys: [n]f32 = undefined;
    for (0..n) |i| {
        xs[i] = @floatFromInt(GRID.x0 + @as(i32, @intCast(i % GRID.n)) * GRID.step);
        ys[i] = @floatFromInt(GRID.y0 + @as(i32, @intCast(i / GRID.n)) * GRID.step);
    }
    var ws = try p.workspaceN(a, n);
    ws.column_rng = true;
    p.eval(&ws, &xs, &ys);
    for (p.out(&ws, 0)[0..n], want) |got, w| try std.testing.expectApproxEqAbs(w, got, 2e-5);
}

test "se-zone: every entity and the cliff expressions compile" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const data = try sa_data.loadSe(a);
    const planet = data.planet("se-zone").?;
    var names: std.ArrayList([]const u8) = .empty;
    for (planet.entities) |e| try names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{e}));
    try names.appendSlice(a, &.{ "cliff_elevation", "cliffiness" });
    var msg: []const u8 = "";
    _ = prog.compile(a, &data, planet, ZONE_SEED, .{ .starting_lake = .{ 0, 0 } }, names.items, &msg) catch |e| {
        std.debug.print("{s}\n", .{msg});
        return e;
    };
}

test "se-zone: a tree's probability matches the game (random penalty, fractional octaves)" {
    try checkColumn("entity:tree-grassland-g:probability", &.{
    0, 0, 0, 0, 0, 0, 0, 0.120394766,
    0, 0, 0, 0, 0.119934008, 0.105251864, 0.102820948, 0.120969959,
    0, 0, 0, 0, 0, 0, 0.122609332, 0.107591987,
    0, 0, 0, 0, 0.100881673, 0.127465457, 0.104804248, 0.117149048,
    0, 0, 0, 0, 0, 0, 0, 0.0899710283,
    0, 0.0415997617, 0.116040647, 0, 0.107297629, 0.112857208, 0.123359643, 0.119044147,
    0, 0, 0, 0, 0, 0, 0, 0.0764421895,
    0.0670368448, 0, 0.118659124, 0, 0, 0.103550158, 0.125475809, 0.121835604,
    0, 0, 0, 0, 0, 0, 0.108266331, 0,
    0, 0, 0, 0, 0, 0.0939623341, 0.03822181, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0.104069442, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0.126475364, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0.123244248, 0.109982647, 0.0795074031, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0.110607058, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0.105112046, 0.120814778, 0, 0, 0.0578728355,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0.108318374, 0.112723358, 0.106004432, 0.00793735124, 0,
    0, 0, 0, 0, 0.109782048, 0, 0, 0,
    0, 0.113008395, 0.116168551, 0.119761154, 0.121037617, 0.124767832, 0.106289372, 0.0478026271,
    0, 0, 0, 0, 0, 0, 0.0359627083, 0,
    0, 0.124293804, 0.115143701, 0.122957394, 0.123867154, 0.121640712, 0.121724725, 0.0986376479,
    0.0370806307, 0, 0, 0, 0, 0, 0, 0,
    0, 0.124355465, 0.10606131, 0.12029691, 0.110709302, 0.107315086, 0.114584565, 0.106256828,
    0, 0, 0.0345358886, 0, 0, 0, 0, 0,
    0, 0, 0.117210187, 0.106284373, 0.105154075, 0.121182449, 0.120878354, 0,
    0, 0, 0, 0, 0, 0, 0.0149007831, 0,
    0, 0, 0, 0.126709625, 0.121299155, 0.112936646, 0.116681859, 0.00588330161,
    });
}

test "se-zone: a volcanic rock's probability matches the game (penalty drawn only where positive)" {
    try checkColumn("entity:big-rock-volcanic:probability", &.{
    -0.174616262, 0, 0.278228194, 0, 0, -0.273696721, 0, -0.0205275565,
    0, 0, 0.173292845, -0.119990058, 0, 0, 0, 0,
    -0.159057185, 0, 0, 0, 0, -0.417909294, 0, 0,
    -0.277497709, 0.0811742693, 0, 0, 0, 0, -0.124127455, 0,
    0, 0, -0.406836092, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, -0.38471061, 0, 0, 0, -0.0657744482, -0.0824785158, 0,
    0, 0, 0, 0, -0.0128639266, 0.166167364, 0, 0,
    -0.278519243, 0.0513409451, 0, 0, 0, 0, -0.460891992, 0.102205582,
    0.0313475206, 0, 0, 0, 0, 0, 0.387433052, 0,
    0, -0.426539689, 0, 0, 0, 0, 0, 0,
    0, -0.0267265923, -0.354786187, 0, -0.589609027, 0, 0, 0,
    0, -0.142491534, 0, 0, 0, 0, 0, 0.169440925,
    -0.391094446, 0, 0, 0, -0.316330403, -0.528874099, 0, 0,
    -0.524346888, -0.277079672, 0, -0.342273563, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    -0.232569501, 0, 0, -0.180010557, 0, 0, -0.159742713, 0,
    0, 0, 0, 0, 0, 0.483292788, 0, 0,
    0, -0.349550039, -0.362859428, 0, -0.310448617, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0.0583685376,
    0, 0, 0, 0, 0, 0, 0, 0,
    0.00165471202, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0.191842332, 0.0329573154, 0, -0.106324151, -0.0792225525,
    0, 0, 0, 0, 0, 0, 0, 0,
    -0.171697795, 0, -0.198315486, 0, 0, -0.0405569412, -0.244386509, 0.145352229,
    0, -0.19713442, -0.50735116, -0.312001258, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, -0.518148422, -0.417769611, 0, 0, 0, 0, 0.0102335056,
    0, 0, 0, -0.302877516, -0.413888484, 0, 0, 0,
    0, -0.00247317133, 0, -0.0837358534, -0.522262156, 0, 0.0811484084, 0,
    -0.122356288, 0, 0, -0.294175297, 0.0619434938, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, -0.283249766,
    });
}

test "se-zone: a rock's probability matches the game (no penalty)" {
    try checkColumn("entity:huge-rock-brown:probability", &.{
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0.101435401, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    });
}
