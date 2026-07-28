//! GPU surface renderer for the GUI — a fast terrain preview.
//!
//! Same CLI shape segen uses (--zones <jsonl> --world-seed N --zone <name>
//! --out <dir>). Renders the zone's biome+water (planet/moon) or se-space /
//! se-asteroid (asteroid field) on the GPU and writes it under
//! <out>/seed_<world>/<zone>/ (segen orientation: vertical flip, grey
//! background outside the disk).
//!
//! Tiling: with `--surface-grid N` (N>1) the disk is split into an N×N grid of
//! cells (identical geometry to segen's --surface-grid/--surface-cell and to the
//! GUI's surfaceCellLayout), and each disk-intersecting cell is rendered — in
//! ONE process (the GPU context + pipeline + per-map_seed generator buffers are
//! built once and reused) — center-outward, writing terrain_<N>_<cell>.png as it
//! goes. The GUI polls the zone dir and fills cells in as they land, so a big
//! surface shows visible progress instead of one long stall. Without the flag
//! (or N<=1) it renders the whole disk in one dispatch → terrain.png.
//!
//! The zone's terrain config depends only on zone_seed (z.s), radius (z.r) and
//! has_water (z.water present & != "none") — all in the jsonl — so no universe
//! port is needed here. fm = 5000/radius (universe.zoneFrequencyMultiplier).

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const biome = surfgen.biome;

const render_wgsl = @embedFile("shaders/render.wgsl");
const asteroid_wgsl = @embedFile("shaders/asteroid.wgsl");

const AsteroidParams = extern struct {
    origin_x: f32,
    origin_y: f32,
    size: f32,
    freq: f32,
    planet_radius: f32,
    width: u32,
    height: u32,
    seed_byte: u32,
};

const Params = extern struct {
    origin_x: f32,
    origin_y: f32,
    nsm: f32,
    seg: f32,
    water_level: f32,
    is_hills: f32,
    is_cliff: f32,
    os_cliff: f32,
    is_bridge: f32,
    is_macro1: f32,
    is_macro2: f32,
    is_detail: f32,
    os_detail: f32,
    offx_detail: f32,
    is_pers: f32,
    os_pers: f32,
    offx_pers: f32,
    cold_size: f32,
    hot_size: f32,
    cold_freq: f32,
    hot_freq: f32,
    moist_freq: f32,
    moist_bias: f32,
    aux_freq: f32,
    aux_bias: f32,
    width: u32,
    height: u32,
    n_biomes: u32,
    has_water: u32,
    _pa: u32 = 0,
    _pb: u32 = 0,
    _pc: u32 = 0,
};

const BiomeGPU = extern struct {
    t_lo: f32 = 0,
    t_hi: f32 = 0,
    m_lo: f32 = 0,
    m_hi: f32 = 0,
    a_lo: f32 = 0,
    a_hi: f32 = 0,
    e_lo: f32 = 0,
    e_hi: f32 = 0,
    water_coef: f32 = 0,
    flags: u32 = 0,
    pad0: u32 = 0,
    pad1: u32 = 0,
};

const NGEN = 192;

fn getStr(args: []const [:0]const u8, flag: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i + 1 < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], flag)) return args[i + 1];
    }
    return null;
}

// ── SE per-zone control settings (Universe.control_settings_from_tag, verified
// against the live game: e.g. Grishord temperature=midrange → cold/hot size 0.65,
// moisture=max → freq 2 bias 0.5, aux=very_high → bias 0.5). The zone's qualitative
// labels (z.temperature/z.moisture/z.aux) select these; without them our biomes
// swing to hot/cold extremes. cold/hot frequency is × the zone frequency
// multiplier (fm); moisture/aux frequency is the raw control multiplier.
const ColdHot = struct { cold_f: f64, cold_s: f64, hot_f: f64, hot_s: f64 };
fn tempControl(label: []const u8) ColdHot {
    const eq = std.mem.eql;
    if (eq(u8, label, "bland")) return .{ .cold_f = 0.5, .cold_s = 0, .hot_f = 0.5, .hot_s = 0 };
    if (eq(u8, label, "temperate")) return .{ .cold_f = 1, .cold_s = 0.25, .hot_f = 1, .hot_s = 0.25 };
    if (eq(u8, label, "midrange")) return .{ .cold_f = 1, .cold_s = 0.65, .hot_f = 1, .hot_s = 0.65 };
    if (eq(u8, label, "balanced")) return .{ .cold_f = 1, .cold_s = 1, .hot_f = 1, .hot_s = 1 };
    if (eq(u8, label, "wild")) return .{ .cold_f = 1, .cold_s = 3, .hot_f = 1, .hot_s = 3 };
    if (eq(u8, label, "extreme")) return .{ .cold_f = 1, .cold_s = 6, .hot_f = 1, .hot_s = 6 };
    if (eq(u8, label, "cool")) return .{ .cold_f = 0.75, .cold_s = 0.5, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "cold")) return .{ .cold_f = 0.75, .cold_s = 1, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "vcold")) return .{ .cold_f = 0.75, .cold_s = 2.2, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "frozen")) return .{ .cold_f = 0.75, .cold_s = 6, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "warm")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 0.5 };
    if (eq(u8, label, "hot")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 1 };
    if (eq(u8, label, "vhot")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 2.2 };
    if (eq(u8, label, "volcanic")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 6 };
    return .{ .cold_f = 1, .cold_s = 0.65, .hot_f = 1, .hot_s = 0.65 }; // default midrange
}
const FreqBias = struct { f: f64, bias: f64 };
fn moistControl(label: []const u8) FreqBias {
    const eq = std.mem.eql;
    if (eq(u8, label, "none")) return .{ .f = 2, .bias = -1 };
    if (eq(u8, label, "low")) return .{ .f = 1, .bias = -0.15 };
    if (eq(u8, label, "med")) return .{ .f = 1, .bias = 0 };
    if (eq(u8, label, "high")) return .{ .f = 1, .bias = 0.15 };
    if (eq(u8, label, "max")) return .{ .f = 2, .bias = 0.5 };
    return .{ .f = 1, .bias = 0 }; // default med
}
fn auxControl(label: []const u8) FreqBias {
    const eq = std.mem.eql;
    if (eq(u8, label, "very_low")) return .{ .f = 1, .bias = -0.5 };
    if (eq(u8, label, "low")) return .{ .f = 1, .bias = -0.3 };
    if (eq(u8, label, "med")) return .{ .f = 1, .bias = -0.1 };
    if (eq(u8, label, "high")) return .{ .f = 1, .bias = 0.2 };
    if (eq(u8, label, "very_high")) return .{ .f = 1, .bias = 0.5 };
    return .{ .f = 1, .bias = -0.1 }; // default med
}

// ── Cell layout (mirrors segen se_main + the GUI's planSurfaceCells) ─────────
// One rectangle of the N×N grid over [-R,R]² that intersects the disk. Cells
// fully outside are dropped; the rest are ordered center-outward (by centre
// distance from the origin) so the landing area renders first.
const Cell = struct { cell: u32, x0: i32, y0: i32, cw: u32, ch: u32, d2: f64 };

fn lessCell(_: void, p: Cell, q: Cell) bool {
    return p.d2 < q.d2;
}

fn cellList(a: std.mem.Allocator, R: i32, radius: f64, grid: i32) ![]Cell {
    var list: std.ArrayList(Cell) = .empty;
    if (grid <= 1) {
        const W: u32 = @intCast(R * 2);
        try list.append(a, .{ .cell = 0, .x0 = -R, .y0 = -R, .cw = W, .ch = W, .d2 = 0 });
        return list.toOwnedSlice(a);
    }
    const full: i32 = R * 2;
    const cellW: i32 = @divTrunc(full + grid - 1, grid); // ceil
    const rr = radius * radius;
    var cell: i32 = 0;
    while (cell < grid * grid) : (cell += 1) {
        const gx = @mod(cell, grid);
        const gy = @divTrunc(cell, grid);
        const x0 = -R + gx * cellW;
        const x1 = @min(R, x0 + cellW);
        const y0 = -R + gy * cellW;
        const y1 = @min(R, y0 + cellW);
        if (x1 <= x0 or y1 <= y0) continue;
        // nearest rect point to origin — skip cells fully outside the disk.
        const nx: f64 = @floatFromInt(@max(x0, @min(0, x1 - 1)));
        const ny: f64 = @floatFromInt(@max(y0, @min(0, y1 - 1)));
        if (nx * nx + ny * ny > rr) continue;
        const cx = @as(f64, @floatFromInt(x0 + x1)) / 2.0;
        const cy = @as(f64, @floatFromInt(y0 + y1)) / 2.0;
        try list.append(a, .{
            .cell = @intCast(cell),
            .x0 = x0,
            .y0 = y0,
            .cw = @intCast(x1 - x0),
            .ch = @intCast(y1 - y0),
            .d2 = cx * cx + cy * cy,
        });
    }
    std.mem.sort(Cell, list.items, {}, lessCell);
    return list.toOwnedSlice(a);
}

// Write <out>/seed_<world>/<zone>/terrain.png (grid<=1) or terrain_<grid>_<cell>.png.
fn writeZonePng(init: std.process.Init, out_dir: []const u8, world_seed: u64, zone_name: []const u8, grid: i32, cell: u32, png: []const u8) !void {
    var pb: [1024]u8 = undefined;
    const dir = try std.fmt.bufPrint(&pb, "{s}/seed_{d}/{s}", .{ out_dir, world_seed, zone_name });
    try std.Io.Dir.createDirPath(.cwd(), init.io, dir);
    var pb2: [1100]u8 = undefined;
    const path = if (grid <= 1)
        try std.fmt.bufPrint(&pb2, "{s}/terrain.png", .{dir})
    else
        try std.fmt.bufPrint(&pb2, "{s}/terrain_{d}_{d}.png", .{ dir, grid, cell });
    const file = try std.Io.Dir.createFile(.cwd(), init.io, path, .{});
    defer file.close(init.io);
    try file.writePositionalAll(init.io, png, 0);
    std.debug.print("   wrote {s} ({d} bytes)\n", .{ path, png.len });
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    const zones_path = getStr(args, "--zones") orelse return err("missing --zones");
    const world_seed_s = getStr(args, "--world-seed") orelse return err("missing --world-seed");
    const zone_name = getStr(args, "--zone") orelse return err("missing --zone");
    const out_dir = getStr(args, "--out") orelse return err("missing --out");
    const world_seed = try std.fmt.parseInt(u64, world_seed_s, 10);

    // Optional radius override (required for asteroid fields — they carry no z.r).
    const radius_override: ?f64 = if (getStr(args, "--radius")) |rs| try std.fmt.parseFloat(f64, rs) else null;
    // Optional N×N tiling. Default 1 = whole disk in one dispatch → terrain.png.
    const grid: i32 = if (getStr(args, "--surface-grid")) |gs| try std.fmt.parseInt(i32, gs, 10) else 1;

    // ── Find the zone in the jsonl → zone_seed, radius, type, has_water ──────
    const raw = try std.Io.Dir.readFileAlloc(.cwd(), init.io, zones_path, a, .unlimited);
    var zone_seed: u32 = 0;
    var radius: f64 = 0;
    var has_water = false;
    var is_field = false;
    var found = false;
    // Per-zone control labels (SE tags without the property prefix). Defaults
    // reproduce the previous behaviour if a zone omits them.
    var temp_label: []const u8 = "midrange";
    var moist_label: []const u8 = "med";
    var aux_label: []const u8 = "med";
    var it = std.mem.tokenizeScalar(u8, raw, '\n');
    outer: while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;
        const parsed = std.json.parseFromSlice(std.json.Value, a, trimmed, .{}) catch continue;
        const root = parsed.value;
        if (root != .object) continue;
        const s = root.object.get("s") orelse continue;
        if (s != .integer or @as(u64, @intCast(s.integer)) != world_seed) continue;
        const zs = root.object.get("z") orelse continue;
        if (zs != .array) continue;
        for (zs.array.items) |z| {
            if (z != .object) continue;
            const nm = z.object.get("n") orelse continue;
            if (nm != .string or !std.mem.eql(u8, nm.string, zone_name)) continue;
            zone_seed = @intCast((z.object.get("s") orelse continue).integer);
            if (z.object.get("t")) |t| is_field = (t == .string) and std.mem.eql(u8, t.string, "asteroid-field");
            if (z.object.get("r")) |rv| radius = switch (rv) {
                .integer => |v| @floatFromInt(v),
                .float => |v| v,
                else => 0,
            };
            if (z.object.get("water")) |w| {
                has_water = (w == .string) and !std.mem.eql(u8, w.string, "none");
            }
            if (z.object.get("temperature")) |v| if (v == .string) {
                temp_label = try a.dupe(u8, v.string);
            };
            if (z.object.get("moisture")) |v| if (v == .string) {
                moist_label = try a.dupe(u8, v.string);
            };
            if (z.object.get("aux")) |v| if (v == .string) {
                aux_label = try a.dupe(u8, v.string);
            };
            found = true;
            break :outer;
        }
    }
    if (!found) return err("zone not found in jsonl");
    // Render EXTENT (half-size of the rendered disk): --radius caps it, else the
    // zone's true radius. CRITICAL: the zone's TRUE radius stays for the
    // control/frequency math (fm = 5000/radius) below — capping the render
    // window must NOT change the noise scale, or the biome pattern shifts (this
    // was the moon-render bug: --radius 600 gave fm 8.3 instead of 1.7).
    const extent: f64 = if (radius_override) |ro| ro else radius;
    if (extent < 1) return err("zone has no radius — pass --radius (required for asteroid fields)");

    const R: u32 = @intFromFloat(extent);
    const W: u32 = R * 2;
    const H: u32 = R * 2;

    // ── Asteroid field: se-space / se-asteroid argmax (separate kernel) ──────
    if (is_field) {
        std.debug.print("# gpu_segen: {s} seed {d} r {d} ASTEROID-FIELD grid {d} → {d}x{d}\n", .{ zone_name, zone_seed, R, grid, W, H });
        try renderAsteroidField(a, init, zone_seed, extent, out_dir, world_seed, zone_name, grid);
        return;
    }
    if (radius < 1) return err("planet/moon zone has no radius (z.r)");

    std.debug.print("# gpu_segen: {s} seed {d} r {d} water {} grid {d} → {d}x{d}\n", .{ zone_name, zone_seed, R, has_water, grid, W, H });

    // ── Build params (mirrors segen's per-zone ZoneTerrain/Elevation config) ─
    // origin/width/height are placeholders here — renderTerrain overrides them
    // per cell; the rest are geometry-independent.
    const water_freq: f64 = 1.0;
    const water_size: f64 = if (has_water) 1.5 else 1.0;
    const fm: f64 = 5000.0 / radius; // universe.zoneFrequencyMultiplier
    const nsm: f64 = 1.5 * water_freq;
    // Per-zone temperature/moisture/aux controls from the SE tag tables.
    const temp = tempControl(temp_label);
    const moist = moistControl(moist_label);
    const aux = auxControl(aux_label);
    std.debug.print("   controls: temp={s}(cold s{d} f{d}, hot s{d} f{d}) moist={s}(f{d} b{d}) aux={s}(b{d})\n", .{ temp_label, temp.cold_s, temp.cold_f, temp.hot_s, temp.hot_f, moist_label, moist.f, moist.bias, aux_label, aux.bias });
    const os_pers = (1.0 - 0.7) / std.math.pow(f64, 2.0, 5.0) / (1.0 - std.math.pow(f64, 0.7, 5.0)) * 0.5;
    const base = Params{
        .origin_x = -@as(f32, @floatFromInt(R)),
        .origin_y = -@as(f32, @floatFromInt(R)),
        .nsm = @floatCast(nsm),
        .seg = @floatCast(water_freq),
        .water_level = @floatCast(10.0 * std.math.log2(water_size)),
        .is_hills = @floatCast(nsm / 90.0),
        .is_cliff = @floatCast(nsm / 500.0),
        .os_cliff = 0.6,
        .is_bridge = @floatCast(nsm / 150.0),
        .is_macro1 = @floatCast(nsm / 1600.0),
        .is_macro2 = @floatCast(nsm / 1600.0),
        .is_detail = @floatCast(nsm / 14.0),
        .os_detail = 0.03,
        .offx_detail = @floatCast(10000.0 / nsm),
        .is_pers = @floatCast(nsm / 2.0),
        .os_pers = @floatCast(os_pers),
        .offx_pers = @floatCast(10000.0 / nsm),
        // Temperature: per-zone cold/hot size + frequency from the SE tag table
        // (verified vs the game). This alone lifted Grishord from 31.7%→54.4%.
        .cold_size = @floatCast(temp.cold_s),
        .hot_size = @floatCast(temp.hot_s),
        .cold_freq = @floatCast(temp.cold_f * fm),
        .hot_freq = @floatCast(temp.hot_f * fm),
        // Moisture/aux: LEFT AT DEFAULTS. The SE control tags carry per-zone
        // moisture/aux frequency+bias (Grishord: max→f2/b0.5, very_high→b0.5),
        // but our moisture()/aux() bias convention doesn't match alien-biomes —
        // applying the real values REGRESSES accuracy (54%→12-40%). The game
        // reports moisture ~0.5 at origin even for "max", so its bias is applied
        // in biome selection, not as a property offset. Needs the alien-biomes
        // moisture/aux expression traced before it can be enabled. [[terrain-ore-verification-1845418]]
        .moist_freq = 1.0,
        .moist_bias = 0.0,
        .aux_freq = 1.0,
        .aux_bias = 0.0,
        .width = W,
        .height = H,
        .n_biomes = @intCast(biome.biomes.len),
        .has_water = if (has_water) 1 else 0,
    };

    // Geometry (disk mask + cell layout) uses the render EXTENT; the frequency
    // params in `base` already encode the true radius via fm.
    try renderTerrain(a, init, zone_seed, base, extent, out_dir, world_seed, zone_name, grid);
}

fn err(msg: []const u8) error{Usage} {
    std.debug.print("gpu_segen error: {s}\n  usage: gpu_segen --zones <jsonl> --world-seed N --zone <name> --out <dir> [--radius R] [--surface-grid N]\n", .{msg});
    return error.Usage;
}

fn packGen(gi: usize, g: noise.BasisNoiseGen, p1: []u32, p2: []u32, gr: []f32, sb: []u32) void {
    sb[gi] = g.seed_byte;
    for (0..256) |i| {
        p1[gi * 256 + i] = g.perm1[i];
        p2[gi * 256 + i] = g.perm2[i];
        gr[gi * 512 + 2 * i] = g.grad[i][0];
        gr[gi * 512 + 2 * i + 1] = g.grad[i][1];
    }
}

/// Pack the 192 generators + biome table for map_seed once, build the GPU
/// context + pipeline once, then render each disk cell (render.wgsl) and write
/// its PNG. grid<=1 → a single whole-disk cell → terrain.png.
fn renderTerrain(a: std.mem.Allocator, init: std.process.Init, map_seed: u32, base: Params, radius: f64, out_dir: []const u8, world_seed: u64, zone_name: []const u8, grid: i32) !void {
    const nb = biome.biomes.len;
    const perm1 = try a.alloc(u32, NGEN * 256);
    const perm2 = try a.alloc(u32, NGEN * 256);
    const grad = try a.alloc(f32, NGEN * 512);
    const seed_bytes = try a.alloc(u32, NGEN);
    const table = try a.alloc(BiomeGPU, nb);

    const elev_seed1 = [_]u32{ 900, 99584, 700, 1000, 1100, 500, 600 };
    for (elev_seed1, 0..) |s1, i| packGen(i, noise.BasisNoiseGen.init(map_seed, s1), perm1, perm2, grad, seed_bytes);
    for (0..11) |k| packGen(7 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 5), perm1, perm2, grad, seed_bytes);
    for (0..8) |k| packGen(18 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 6), perm1, perm2, grad, seed_bytes);
    for (0..8) |k| packGen(26 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 7), perm1, perm2, grad, seed_bytes);
    for (biome.biomes, 0..) |b, i| {
        packGen(34 + i, noise.BasisNoiseGen.init(map_seed, b.tv_seed), perm1, perm2, grad, seed_bytes);
        var bd = BiomeGPU{ .water_coef = @floatCast(b.water_coef) };
        if (b.t) |r| {
            bd.t_lo = @floatCast(r[0]);
            bd.t_hi = @floatCast(r[1]);
            bd.flags |= 1;
        }
        if (b.m) |r| {
            bd.m_lo = @floatCast(r[0]);
            bd.m_hi = @floatCast(r[1]);
            bd.flags |= 2;
        }
        if (b.a) |r| {
            bd.a_lo = @floatCast(r[0]);
            bd.a_hi = @floatCast(r[1]);
            bd.flags |= 4;
        }
        if (b.e) |r| {
            bd.e_lo = @floatCast(r[0]);
            bd.e_hi = @floatCast(r[1]);
            bd.flags |= 8;
        }
        if (b.beach_weight < 0.0) bd.flags |= 16;
        if (b.crater) bd.flags |= 32;
        table[i] = bd;
    }
    packGen(190, noise.BasisNoiseGen.init(map_seed, biome.WATER_SEED), perm1, perm2, grad, seed_bytes);
    packGen(191, noise.BasisNoiseGen.init(map_seed, biome.CRATER_SEED), perm1, perm2, grad, seed_bytes);

    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    const pipeline = try ctx.computePipeline(render_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    // Static per-map_seed buffers — uploaded once, reused for every cell.
    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_perm1);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_perm2);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_grad);
    const buf_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_sb);
    const buf_table = ctx.uploadBuffer(BiomeGPU, table, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_table);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);

    const R: i32 = @intFromFloat(radius);
    const rr = radius * radius;
    const bg = [3]u8{ 20, 20, 20 };
    const cells = try cellList(a, R, radius, grid);
    std.debug.print("   {d} cell(s) to render (grid {d})\n", .{ cells.len, grid });

    for (cells) |cl| {
        // Per-cell CPU scratch (indices/rgb/png) freed each iteration.
        var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer cellArena.deinit();
        const ca = cellArena.allocator();

        var params = base;
        params.origin_x = @floatFromInt(cl.x0);
        params.origin_y = @floatFromInt(cl.y0);
        params.width = cl.cw;
        params.height = cl.ch;
        const npx: u32 = cl.cw * cl.ch;
        const out_bytes: u64 = @as(u64, npx) * @sizeOf(u32);

        const buf_params = ctx.uploadBuffer(Params, &.{params}, c.WGPUBufferUsage_Uniform);
        defer c.wgpuBufferRelease(buf_params);
        const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_out);
        const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
        defer c.wgpuBufferRelease(staging);

        var entries = [_]c.WGPUBindGroupEntry{
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(Params) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_perm1, .size = perm1.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_perm2, .size = perm2.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = buf_grad, .size = grad.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_sb, .size = seed_bytes.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = buf_table, .size = table.len * @sizeOf(BiomeGPU) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = buf_out, .size = out_bytes }),
        };
        var bg_desc = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = &entries });
        const bind_group = c.wgpuDeviceCreateBindGroup(ctx.device, &bg_desc);
        defer c.wgpuBindGroupRelease(bind_group);

        const encoder = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        var pass_desc = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
        const pass = c.wgpuCommandEncoderBeginComputePass(encoder, &pass_desc);
        c.wgpuComputePassEncoderSetPipeline(pass, pipeline);
        c.wgpuComputePassEncoderSetBindGroup(pass, 0, bind_group, 0, null);
        c.wgpuComputePassEncoderDispatchWorkgroups(pass, (cl.cw + 7) / 8, (cl.ch + 7) / 8, 1);
        c.wgpuComputePassEncoderEnd(pass);
        c.wgpuComputePassEncoderRelease(pass);
        c.wgpuCommandEncoderCopyBufferToBuffer(encoder, buf_out, 0, staging, 0, out_bytes);
        const cmd = c.wgpuCommandEncoderFinish(encoder, null);
        c.wgpuCommandEncoderRelease(encoder);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);

        const indices = try ca.alloc(u32, npx);
        try ctx.readBuffer(staging, u32, indices);

        // Compose cell PNG: disk mask (grey 20) + idx→colour + vertical flip
        // (segen writes cells vertically flipped within the cell).
        const rgb = try ca.alloc(u8, npx * 3);
        for (0..cl.ch) |out_y| {
            const src_y = cl.ch - 1 - out_y;
            const fy: f64 = @as(f64, @floatFromInt(cl.y0)) + @as(f64, @floatFromInt(src_y));
            for (0..cl.cw) |x| {
                const fx: f64 = @as(f64, @floatFromInt(cl.x0)) + @as(f64, @floatFromInt(x));
                const col = if (fx * fx + fy * fy > rr) bg else biome.idxColor(@intCast(indices[src_y * cl.cw + x]));
                const o = (out_y * cl.cw + x) * 3;
                rgb[o] = col[0];
                rgb[o + 1] = col[1];
                rgb[o + 2] = col[2];
            }
        }
        const png = try surfgen.png.encode(ca, cl.cw, cl.ch, rgb);
        try writeZonePng(init, out_dir, world_seed, zone_name, grid, cl.cell, png);
    }
}

/// Render an asteroid field (se-space / se-asteroid) via asteroid.wgsl. Same
/// setup-once + per-cell loop as renderTerrain. grid<=1 → terrain.png.
fn renderAsteroidField(a: std.mem.Allocator, init: std.process.Init, map_seed: u32, radius: f64, out_dir: []const u8, world_seed: u64, zone_name: []const u8, grid: i32) !void {
    const size: f64 = surfgen.asteroid.FIELD_SIZE;
    const freq: f64 = surfgen.asteroid.FIELD_FREQ;
    const planet_radius = 10000.0 / 6.0 * (6.0 + std.math.log2(1.0 / freq / 6.0));

    const g = surfgen.noise.BasisNoiseGen.init(map_seed, 1);
    const perm1 = try a.alloc(u32, 256);
    const perm2 = try a.alloc(u32, 256);
    const grad = try a.alloc(f32, 512);
    for (0..256) |i| {
        perm1[i] = g.perm1[i];
        perm2[i] = g.perm2[i];
        grad[2 * i] = g.grad[i][0];
        grad[2 * i + 1] = g.grad[i][1];
    }

    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    const pipeline = try ctx.computePipeline(asteroid_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_perm1);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_perm2);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    defer c.wgpuBufferRelease(buf_grad);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);

    const space = surfgen.asteroid.SPACE_COLOR;
    const ast = surfgen.asteroid.ASTEROID_COLOR;
    const bg = [3]u8{ 20, 20, 20 };
    const R: i32 = @intFromFloat(radius);
    const rr = radius * radius;
    const cells = try cellList(a, R, radius, grid);
    std.debug.print("   {d} field cell(s) to render (grid {d})\n", .{ cells.len, grid });

    for (cells) |cl| {
        var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer cellArena.deinit();
        const ca = cellArena.allocator();

        const params = AsteroidParams{
            .origin_x = @floatFromInt(cl.x0),
            .origin_y = @floatFromInt(cl.y0),
            .size = @floatCast(size),
            .freq = @floatCast(freq),
            .planet_radius = @floatCast(planet_radius),
            .width = cl.cw,
            .height = cl.ch,
            .seed_byte = g.seed_byte,
        };
        const npx: u32 = cl.cw * cl.ch;
        const out_bytes: u64 = @as(u64, npx) * @sizeOf(u32);

        const buf_params = ctx.uploadBuffer(AsteroidParams, &.{params}, c.WGPUBufferUsage_Uniform);
        defer c.wgpuBufferRelease(buf_params);
        const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_out);
        const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
        defer c.wgpuBufferRelease(staging);

        var entries = [_]c.WGPUBindGroupEntry{
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(AsteroidParams) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_perm1, .size = perm1.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_perm2, .size = perm2.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = buf_grad, .size = grad.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_out, .size = out_bytes }),
        };
        var bg_desc = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = &entries });
        const bind_group = c.wgpuDeviceCreateBindGroup(ctx.device, &bg_desc);
        defer c.wgpuBindGroupRelease(bind_group);

        const encoder = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        var pass_desc = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
        const pass = c.wgpuCommandEncoderBeginComputePass(encoder, &pass_desc);
        c.wgpuComputePassEncoderSetPipeline(pass, pipeline);
        c.wgpuComputePassEncoderSetBindGroup(pass, 0, bind_group, 0, null);
        c.wgpuComputePassEncoderDispatchWorkgroups(pass, (cl.cw + 7) / 8, (cl.ch + 7) / 8, 1);
        c.wgpuComputePassEncoderEnd(pass);
        c.wgpuComputePassEncoderRelease(pass);
        c.wgpuCommandEncoderCopyBufferToBuffer(encoder, buf_out, 0, staging, 0, out_bytes);
        const cmd = c.wgpuCommandEncoderFinish(encoder, null);
        c.wgpuCommandEncoderRelease(encoder);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);

        const indices = try ca.alloc(u32, npx);
        try ctx.readBuffer(staging, u32, indices);

        // 0=space, 1=asteroid, 2=out-of-map; disk mask + vertical flip.
        const rgb = try ca.alloc(u8, npx * 3);
        for (0..cl.ch) |out_y| {
            const src_y = cl.ch - 1 - out_y;
            const fy: f64 = @as(f64, @floatFromInt(cl.y0)) + @as(f64, @floatFromInt(src_y));
            for (0..cl.cw) |x| {
                const fx: f64 = @as(f64, @floatFromInt(cl.x0)) + @as(f64, @floatFromInt(x));
                const col = if (fx * fx + fy * fy > rr) bg else switch (indices[src_y * cl.cw + x]) {
                    1 => ast,
                    2 => bg,
                    else => space,
                };
                const o = (out_y * cl.cw + x) * 3;
                rgb[o] = col[0];
                rgb[o + 1] = col[1];
                rgb[o + 2] = col[2];
            }
        }
        const png = try surfgen.png.encode(ca, cl.cw, cl.ch, rgb);
        try writeZonePng(init, out_dir, world_seed, zone_name, grid, cl.cell, png);
    }
}
