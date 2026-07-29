//! GPU ore placement for asteroid fields. Reads a --dump produced by
//! `segen --gpu-ore-dump` (per-resource params + precomputed spots), then tiles
//! the disk into an NxN grid and, per cell, runs the asteroid mask + ore.wgsl
//! per-tile eval on the GPU and writes oremap_<grid>_<cell>.png as it goes
//! (center-outward) so the GUI fills cells in progressively — symmetric with
//! gpu_segen for terrain. grid<=1 → a single oremap.png. Also writes summary.json.
//! The f32 GPU output is bit-exact vs the f64 CPU oracle for fields; the CPU
//! path stays the oracle. See shaders/ore.wgsl.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const se = surfgen.se_ore;
const noise = surfgen.noise;
const png = surfgen.png;

const ore_wgsl = @embedFile("shaders/ore.wgsl");
const asteroid_wgsl = @embedFile("shaders/asteroid.wgsl");

fn getStr(args: []const []const u8, flag: []const u8) ?[]const u8 {
    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, flag) and i + 1 < args.len) return args[i + 1];
    }
    return null;
}
fn err(msg: []const u8) error{Usage} {
    std.debug.print("gpu_ore error: {s}\n  usage: gpu_ore --dump <gore.bin> --out <dir> --world-seed N --zone <name> [--grid N]\n", .{msg});
    return error.Usage;
}

// Resource -> oremap map_color (matches se_main MapColors / ore-colors.json).
fn mapColor(name: []const u8) [3]u8 {
    const T = struct { n: []const u8, c: [3]u8 };
    const tbl = [_]T{
        .{ .n = "iron-ore", .c = .{ 105, 133, 147 } },
        .{ .n = "copper-ore", .c = .{ 204, 98, 54 } },
        .{ .n = "coal", .c = .{ 0, 0, 0 } },
        .{ .n = "stone", .c = .{ 175, 155, 108 } },
        .{ .n = "uranium-ore", .c = .{ 0, 178, 0 } },
        .{ .n = "crude-oil", .c = .{ 255, 153, 0 } },
        .{ .n = "kr-rare-metal-ore", .c = .{ 153, 76, 255 } },
        .{ .n = "kr-imersite", .c = .{ 255, 127, 255 } },
        .{ .n = "kr-mineral-water", .c = .{ 89, 127, 191 } },
        .{ .n = "se-water-ice", .c = .{ 198, 241, 245 } },
        .{ .n = "se-methane-ice", .c = .{ 245, 231, 198 } },
        .{ .n = "se-beryllium-ore", .c = .{ 144, 222, 184 } },
        .{ .n = "se-cryonite", .c = .{ 35, 164, 255 } },
        .{ .n = "se-holmium-ore", .c = .{ 135, 96, 109 } },
        .{ .n = "se-iridium-ore", .c = .{ 244, 202, 85 } },
        .{ .n = "se-naquium-ore", .c = .{ 137, 113, 214 } },
        .{ .n = "se-vulcanite", .c = .{ 224, 40, 10 } },
        .{ .n = "se-vitamelange", .c = .{ 173, 206, 54 } },
    };
    for (tbl) |e| if (std.mem.eql(u8, e.n, name)) return e.c;
    return .{ 128, 128, 128 };
}

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

// MUST match shaders/ore.wgsl `Params` (padded to a multiple of 16).
const OreParams = extern struct {
    origin_x: f32,
    origin_y: f32,
    width: u32,
    height: u32,
    zone_radius: f32,
    base_density: f32,
    freq_mult: f32,
    size_mult: f32,
    base_spots_per_km2: f32,
    rq: f32,
    smin: f32,
    smax: f32,
    basement_value: f32,
    richness_mult: f32,
    additional_richness: f32,
    random_probability: f32,
    roll_salt: u32,
    seed_byte: u32,
    res_index: u32,
    has_starting: u32,
    starting_blob_amplitude: f32,
    nspots: u32,
    nstart: u32,
    pad0: u32 = 0,
};

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
    const cellW: i32 = @divTrunc(full + grid - 1, grid);
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
        const nx: f64 = @floatFromInt(@max(x0, @min(0, x1 - 1)));
        const ny: f64 = @floatFromInt(@max(y0, @min(0, y1 - 1)));
        if (nx * nx + ny * ny > rr) continue;
        const cx = @as(f64, @floatFromInt(x0 + x1)) / 2.0;
        const cy = @as(f64, @floatFromInt(y0 + y1)) / 2.0;
        try list.append(a, .{ .cell = @intCast(cell), .x0 = x0, .y0 = y0, .cw = @intCast(x1 - x0), .ch = @intCast(y1 - y0), .d2 = cx * cx + cy * cy });
    }
    std.mem.sort(Cell, list.items, {}, lessCell);
    return list.toOwnedSlice(a);
}

fn buildGen(a: std.mem.Allocator, map_seed: u32, seed1: u32) !struct { perm1: []u32, perm2: []u32, grad: []f32, sb: u32 } {
    const g = noise.BasisNoiseGen.init(map_seed, seed1);
    const perm1 = try a.alloc(u32, 256);
    const perm2 = try a.alloc(u32, 256);
    const grad = try a.alloc(f32, 512);
    for (0..256) |i| {
        perm1[i] = g.perm1[i];
        perm2[i] = g.perm2[i];
        grad[2 * i] = @floatCast(g.grad[i][0]);
        grad[2 * i + 1] = @floatCast(g.grad[i][1]);
    }
    return .{ .perm1 = perm1, .perm2 = perm2, .grad = grad, .sb = g.seed_byte };
}

// Parsed per-resource, with its static GPU buffers uploaded once.
const Res = struct {
    name: []const u8,
    rh: se.GpuResHeader,
    seed_byte: u32,
    b_perm1: c.WGPUBuffer,
    b_perm2: c.WGPUBuffer,
    b_grad: c.WGPUBuffer,
    b_spots: c.WGPUBuffer,
    b_start: c.WGPUBuffer,
    spots_bytes: u64,
    start_bytes: u64,
};

fn writeCellPng(init: std.process.Init, out_dir: []const u8, world_seed: u64, zone: []const u8, grid: i32, cell: u32, data: []const u8) !void {
    var pb: [1024]u8 = undefined;
    const dir = try std.fmt.bufPrint(&pb, "{s}/seed_{d}/{s}", .{ out_dir, world_seed, zone });
    try std.Io.Dir.createDirPath(.cwd(), init.io, dir);
    var pb2: [1100]u8 = undefined;
    const path = if (grid <= 1)
        try std.fmt.bufPrint(&pb2, "{s}/oremap.png", .{dir})
    else
        try std.fmt.bufPrint(&pb2, "{s}/oremap_{d}_{d}.png", .{ dir, grid, cell });
    const file = try std.Io.Dir.createFile(.cwd(), init.io, path, .{});
    defer file.close(init.io);
    try file.writePositionalAll(init.io, data, 0);
    std.debug.print("   wrote {s} ({d} bytes)\n", .{ path, data.len });
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    const dump_path = getStr(args, "--dump") orelse return err("missing --dump");
    const out_dir = getStr(args, "--out") orelse return err("missing --out");
    const zone = getStr(args, "--zone") orelse return err("missing --zone");
    const ws_s = getStr(args, "--world-seed") orelse return err("missing --world-seed");
    const world_seed = try std.fmt.parseInt(u64, ws_s, 10);
    const grid: i32 = if (getStr(args, "--grid")) |g| try std.fmt.parseInt(i32, g, 10) else 1;

    const bytes = try std.Io.Dir.readFileAlloc(.cwd(), init.io, dump_path, a, .unlimited);
    var off: usize = 0;
    const H = std.mem.bytesToValue(se.GpuOreHeader, bytes[off..][0..@sizeOf(se.GpuOreHeader)]);
    off += @sizeOf(se.GpuOreHeader);
    if (H.magic != 0x45524f47) return err("bad dump magic");
    const R: i32 = @divTrunc(H.x1 - H.x0, 2);

    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("gpu_ore: {d} resources, extent r{d}, grid {d}, adapter {s}\n", .{ H.nres, R, grid, ctx.adapterName() });

    const ore_pipe = try ctx.computePipeline(ore_wgsl, "main");
    defer c.wgpuComputePipelineRelease(ore_pipe);
    const ore_bgl = c.wgpuComputePipelineGetBindGroupLayout(ore_pipe, 0);
    defer c.wgpuBindGroupLayoutRelease(ore_bgl);
    const ast_pipe = try ctx.computePipeline(asteroid_wgsl, "main");
    defer c.wgpuComputePipelineRelease(ast_pipe);
    const ast_bgl = c.wgpuComputePipelineGetBindGroupLayout(ast_pipe, 0);
    defer c.wgpuBindGroupLayoutRelease(ast_bgl);

    // Asteroid generator (seed1=1) static buffers — uploaded once.
    const ag = try buildGen(a, H.map_seed, 1);
    const ab1 = ctx.uploadBuffer(u32, ag.perm1, c.WGPUBufferUsage_Storage);
    const ab2 = ctx.uploadBuffer(u32, ag.perm2, c.WGPUBufferUsage_Storage);
    const ab3 = ctx.uploadBuffer(f32, ag.grad, c.WGPUBufferUsage_Storage);
    const ast_size: f64 = surfgen.asteroid.FIELD_SIZE;
    const ast_freq: f64 = surfgen.asteroid.FIELD_FREQ;
    const ast_pr = 10000.0 / 6.0 * (6.0 + std.math.log2(1.0 / ast_freq / 6.0));

    // Parse resources + upload their static buffers once.
    var res = try a.alloc(Res, H.nres);
    var nres: usize = 0;
    var ri: u32 = 0;
    while (ri < H.nres) : (ri += 1) {
        const rh = std.mem.bytesToValue(se.GpuResHeader, bytes[off..][0..@sizeOf(se.GpuResHeader)]);
        off += @sizeOf(se.GpuResHeader);
        const name = bytes[off .. off + rh.name_len];
        off += rh.name_len;
        const nsp: usize = rh.nspots;
        const nst: usize = rh.nstart;
        const sp_f = try a.alloc(f32, @max(nsp, 1) * 4);
        for (0..nsp) |k| {
            const s = std.mem.bytesToValue(noise.Spot, bytes[off + k * @sizeOf(noise.Spot) ..][0..@sizeOf(noise.Spot)]);
            sp_f[k * 4 ..][0..4].* = .{ @floatCast(s.x), @floatCast(s.y), @floatCast(s.peak), @floatCast(s.slope) };
        }
        off += nsp * @sizeOf(noise.Spot);
        const st_f = try a.alloc(f32, @max(nst, 1) * 4);
        for (0..nst) |k| {
            const s = std.mem.bytesToValue(noise.Spot, bytes[off + k * @sizeOf(noise.Spot) ..][0..@sizeOf(noise.Spot)]);
            st_f[k * 4 ..][0..4].* = .{ @floatCast(s.x), @floatCast(s.y), @floatCast(s.peak), @floatCast(s.slope) };
        }
        off += nst * @sizeOf(noise.Spot);
        if (nsp == 0) continue;
        const gen = try buildGen(a, H.map_seed, rh.seed1);
        res[nres] = .{
            .name = name,
            .rh = rh,
            .seed_byte = gen.sb,
            .b_perm1 = ctx.uploadBuffer(u32, gen.perm1, c.WGPUBufferUsage_Storage),
            .b_perm2 = ctx.uploadBuffer(u32, gen.perm2, c.WGPUBufferUsage_Storage),
            .b_grad = ctx.uploadBuffer(f32, gen.grad, c.WGPUBufferUsage_Storage),
            .b_spots = ctx.uploadBuffer(f32, sp_f, c.WGPUBufferUsage_Storage),
            .b_start = ctx.uploadBuffer(f32, st_f, c.WGPUBufferUsage_Storage),
            .spots_bytes = sp_f.len * @sizeOf(f32),
            .start_bytes = st_f.len * @sizeOf(f32),
        };
        nres += 1;
    }
    res = res[0..nres];

    // Summary accumulators.
    const s_tiles = try a.alloc(u64, nres);
    const s_amount = try a.alloc(u64, nres);
    @memset(s_tiles, 0);
    @memset(s_amount, 0);

    // Cull cells by the render EXTENT (R), matching the GUI's planSurfaceCells —
    // so the cell set + stitch line up with the CPU tiled path. The kernel's disk
    // gate still uses the zone's true radius (P.zone_radius) for the density math.
    const cells = try cellList(a, R, @as(f64, @floatFromInt(R)), grid);
    std.debug.print("gpu_ore: {d} cells\n", .{cells.len});
    const t0 = wgpu.nowNs();

    for (cells) |cl| {
        var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer cellArena.deinit();
        const ca = cellArena.allocator();
        const npx: usize = @as(usize, cl.cw) * cl.ch;
        const mask_bytes: u64 = npx * @sizeOf(u32);
        const win_bytes: u64 = npx * 16;

        // Asteroid mask for this cell.
        const buf_mask = ctx.makeBuffer(mask_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_mask);
        {
            const p = AsteroidParams{ .origin_x = @floatFromInt(cl.x0), .origin_y = @floatFromInt(cl.y0), .size = @floatCast(ast_size), .freq = @floatCast(ast_freq), .planet_radius = @floatCast(ast_pr), .width = cl.cw, .height = cl.ch, .seed_byte = ag.sb };
            const bp = ctx.uploadBuffer(AsteroidParams, &.{p}, c.WGPUBufferUsage_Uniform);
            defer c.wgpuBufferRelease(bp);
            var e = [_]c.WGPUBindGroupEntry{
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bp, .size = @sizeOf(AsteroidParams) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = ab1, .size = 256 * @sizeOf(u32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = ab2, .size = 256 * @sizeOf(u32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = ab3, .size = 512 * @sizeOf(f32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_mask, .size = mask_bytes }),
            };
            dispatch(&ctx, ast_pipe, ast_bgl, &e, cl.cw, cl.ch);
        }

        // Winner buffer (zeroed).
        const zeros = try ca.alloc(u32, npx * 4);
        @memset(zeros, 0);
        const buf_win = ctx.uploadBuffer(u32, zeros, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_win);

        for (res, 0..) |*rr, idx| {
            const P = OreParams{
                .origin_x = @floatFromInt(cl.x0),
                .origin_y = @floatFromInt(cl.y0),
                .width = cl.cw,
                .height = cl.ch,
                .zone_radius = @floatCast(H.zone_radius),
                .base_density = @floatCast(rr.rh.base_density),
                .freq_mult = @floatCast(rr.rh.freq_mult),
                .size_mult = @floatCast(rr.rh.size_mult),
                .base_spots_per_km2 = @floatCast(rr.rh.base_spots_per_km2),
                .rq = @floatCast(rr.rh.rq),
                .smin = @floatCast(rr.rh.smin),
                .smax = @floatCast(rr.rh.smax),
                .basement_value = @floatCast(rr.rh.basement_value),
                .richness_mult = @floatCast(rr.rh.richness_mult),
                .additional_richness = @floatCast(rr.rh.additional_richness),
                .random_probability = @floatCast(rr.rh.random_probability),
                .roll_salt = rr.rh.roll_salt,
                .seed_byte = rr.seed_byte,
                .res_index = @intCast(idx),
                .has_starting = rr.rh.has_starting,
                .starting_blob_amplitude = @floatCast(rr.rh.starting_blob_amplitude),
                .nspots = rr.rh.nspots,
                .nstart = rr.rh.nstart,
            };
            const bP = ctx.uploadBuffer(OreParams, &.{P}, c.WGPUBufferUsage_Uniform);
            defer c.wgpuBufferRelease(bP);
            var e = [_]c.WGPUBindGroupEntry{
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bP, .size = @sizeOf(OreParams) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = rr.b_perm1, .size = 256 * @sizeOf(u32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = rr.b_perm2, .size = 256 * @sizeOf(u32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = rr.b_grad, .size = 512 * @sizeOf(f32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = rr.b_spots, .size = rr.spots_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = rr.b_start, .size = rr.start_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = buf_mask, .size = mask_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 7, .buffer = buf_win, .size = win_bytes }),
            };
            dispatch(&ctx, ore_pipe, ore_bgl, &e, cl.cw, cl.ch);
        }

        // Read winners, paint RGBA (north-up: row 0 = cell y0), encode + write.
        const staging = ctx.makeBuffer(win_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
        defer c.wgpuBufferRelease(staging);
        {
            const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
            c.wgpuCommandEncoderCopyBufferToBuffer(enc, buf_win, 0, staging, 0, win_bytes);
            const cmd = c.wgpuCommandEncoderFinish(enc, null);
            c.wgpuCommandEncoderRelease(enc);
            c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
            c.wgpuCommandBufferRelease(cmd);
        }
        const win = try ca.alloc(u32, npx * 4);
        try ctx.readBuffer(staging, u32, win);

        const rgba = try ca.alloc(u8, npx * 4);
        @memset(rgba, 0);
        for (0..npx) |i| {
            const amount = win[i * 4 + 3];
            if (amount == 0) continue;
            const rr = win[i * 4 + 2];
            const col = mapColor(res[rr].name);
            rgba[i * 4 ..][0..4].* = .{ col[0], col[1], col[2], 255 };
            s_tiles[rr] += 1;
            s_amount[rr] += amount;
        }
        const bytes_png = try png.encodeRgba(ca, cl.cw, cl.ch, rgba);
        try writeCellPng(init, out_dir, world_seed, zone, grid, cl.cell, bytes_png);
    }

    // summary.json
    var sum: std.ArrayList(u8) = .empty;
    try sum.appendSlice(a, try std.fmt.allocPrint(a, "{{\"zone\":\"{s}\",\"zone_seed\":{d},\"radius\":{d},\"resources\":{{", .{ zone, H.map_seed, R }));
    var first = true;
    for (res, 0..) |*rr, idx| {
        if (s_tiles[idx] == 0) continue;
        if (!first) try sum.appendSlice(a, ",");
        first = false;
        try sum.appendSlice(a, try std.fmt.allocPrint(a, "\"{s}\":{{\"amount\":{d},\"tiles\":{d}}}", .{ rr.name, s_amount[idx], s_tiles[idx] }));
    }
    try sum.appendSlice(a, "}}");
    {
        var pb: [1024]u8 = undefined;
        const sp = try std.fmt.bufPrint(&pb, "{s}/seed_{d}/{s}/summary.json", .{ out_dir, world_seed, zone });
        const f = try std.Io.Dir.createFile(.cwd(), init.io, sp, .{});
        defer f.close(init.io);
        try f.writePositionalAll(init.io, sum.items, 0);
    }
    const dt_ms = @as(f64, @floatFromInt(wgpu.nowNs() - t0)) / 1e6;
    var tot: u64 = 0;
    for (s_tiles) |t| tot += t;
    std.debug.print("gpu_ore: {d} ore tiles across {d} cells in {d:.1} ms\n", .{ tot, cells.len, dt_ms });
}

fn dispatch(ctx: *wgpu.Context, pipe: c.WGPUComputePipeline, bgl: c.WGPUBindGroupLayout, entries: []c.WGPUBindGroupEntry, w: u32, h: u32) void {
    var bgd = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = entries.ptr });
    const bg = c.wgpuDeviceCreateBindGroup(ctx.device, &bgd);
    defer c.wgpuBindGroupRelease(bg);
    const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
    var pd = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
    const pass = c.wgpuCommandEncoderBeginComputePass(enc, &pd);
    c.wgpuComputePassEncoderSetPipeline(pass, pipe);
    c.wgpuComputePassEncoderSetBindGroup(pass, 0, bg, 0, null);
    c.wgpuComputePassEncoderDispatchWorkgroups(pass, (w + 7) / 8, (h + 7) / 8, 1);
    c.wgpuComputePassEncoderEnd(pass);
    c.wgpuComputePassEncoderRelease(pass);
    const cmd = c.wgpuCommandEncoderFinish(enc, null);
    c.wgpuCommandEncoderRelease(enc);
    c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
    c.wgpuCommandBufferRelease(cmd);
    ctx.poll();
}
