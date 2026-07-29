//! GPU ore placement for asteroid fields. Reads a --dump produced by
//! `segen --gpu-ore-dump` (per-resource params + precomputed spots), then tiles
//! the disk into an NxN grid and, per cell, runs the asteroid mask + ore.wgsl
//! per-tile eval on the GPU and writes oremap_<grid>_<cell>.png as it goes
//! (center-outward) so the GUI fills cells in progressively — symmetric with
//! gpu_terrain for terrain. grid<=1 → a single oremap.png. Also writes summary.json.
//! The f32 GPU output is bit-exact vs the f64 CPU oracle for fields; the CPU
//! path stays the oracle. See shaders/ore.wgsl.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const se = surfgen.se_ore;
const noise = surfgen.noise;
const png = surfgen.png;
const terrain = @import("terrain_gpu.zig");

const ore_wgsl = @embedFile("shaders/ore.wgsl");
const asteroid_wgsl = @embedFile("shaders/asteroid.wgsl");

fn getStr(args: []const []const u8, flag: []const u8) ?[]const u8 {
    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, flag) and i + 1 < args.len) return args[i + 1];
    }
    return null;
}
fn hasFlag(args: []const []const u8, flag: []const u8) bool {
    for (args) |arg| if (std.mem.eql(u8, arg, flag)) return true;
    return false;
}

// Shared classify mask: per-tile u32 (field: 0=space/1=asteroid/2=oom; planet:
// biome index / water sentinel >=60000). Written by --classify-only, consumed by
// --mask here and by gpu_terrain, so the terrain classify runs once for a surface.
fn maskPath(buf: []u8, dir: []const u8, grid: i32, cell: u32) ![]const u8 {
    return if (grid <= 1)
        std.fmt.bufPrint(buf, "{s}/biome.bin", .{dir})
    else
        std.fmt.bufPrint(buf, "{s}/biome_{d}_{d}.bin", .{ dir, grid, cell });
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

// Biome tile_restriction bit per resource (matches biome.oreAllowedOnBiome).
fn restrictBit(name: []const u8) u32 {
    if (std.mem.eql(u8, name, "se-vulcanite")) return 1;
    if (std.mem.eql(u8, name, "se-cryonite")) return 2;
    if (std.mem.eql(u8, name, "se-vitamelange")) return 4;
    return 0;
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

// MUST match shaders/ore.wgsl `Shared` (uniform).
const Shared = extern struct {
    origin_x: f32,
    origin_y: f32,
    width: u32,
    height: u32,
    zone_radius: f32,
    seed_byte: u32,
    is_field: u32,
    nres: u32,
    has_any_start: u32,
    pad0: u32 = 0,
    pad1: u32 = 0,
    pad2: u32 = 0,
};

// MUST match shaders/ore.wgsl `Res` (std430 array element, 80 bytes).
const ResGPU = extern struct {
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
    starting_blob_amplitude: f32,
    roll_salt: u32,
    res_index: u32,
    has_starting: u32,
    restrict_bit: u32,
    spot_off: u32,
    nspots: u32,
    start_off: u32,
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

// Parallel PNG encode: PNG (zlib) encoding is CPU-bound and the biggest cost,
// and cells are independent. The main thread does the GPU work per cell and
// collects each cell's RGBA; then all cells are encoded+written across worker
// threads (strided — no shared mutable state, so no locking needed).
const EncJob = struct { rgba: []u8, cw: u32, ch: u32, cell: u32 };
const EncCtx = struct {
    jobs: []const EncJob,
    start: usize,
    stride: usize,
    io: std.Io,
    dir: []const u8,
    grid: i32,
    err: ?anyerror = null,
    fn run(self: *EncCtx) void {
        var i = self.start;
        while (i < self.jobs.len) : (i += self.stride) {
            const job = self.jobs[i];
            const bytes = png.encodeRgba(std.heap.c_allocator, job.cw, job.ch, job.rgba) catch |e| {
                self.err = e;
                continue;
            };
            defer std.heap.c_allocator.free(bytes);
            var pb: [1200]u8 = undefined;
            const path = if (self.grid <= 1)
                std.fmt.bufPrint(&pb, "{s}/oremap.png", .{self.dir}) catch continue
            else
                std.fmt.bufPrint(&pb, "{s}/oremap_{d}_{d}.png", .{ self.dir, self.grid, job.cell }) catch continue;
            const f = std.Io.Dir.createFile(.cwd(), self.io, path, .{}) catch |e| {
                self.err = e;
                continue;
            };
            f.writePositionalAll(self.io, bytes, 0) catch |e| {
                self.err = e;
            };
            f.close(self.io);
        }
    }
};

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
    const classify_only = hasFlag(args, "--classify-only");
    const use_mask = hasFlag(args, "--mask"); // read the shared classify mask instead of classifying

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

    // Planet/moon: build the terrain classifier (for the water + biome gate) and
    // the per-biome restrict table. Fields skip this (asteroid mask instead).
    const is_field = H.is_field != 0;
    var classifier: ?terrain.Classifier = null;
    var base_params: terrain.Params = undefined;
    var b_restrict: c.WGPUBuffer = undefined;
    var restrict_bytes: u64 = 0;
    if (!is_field) {
        const rt = try terrain.restrictTable(a); // static — always needed for the ore biome gate
        b_restrict = ctx.uploadBuffer(u32, rt, c.WGPUBufferUsage_Storage);
        restrict_bytes = rt.len * @sizeOf(u32);
        // The classifier (192-gen upload) is only needed when we classify inline;
        // reading a precomputed mask (--mask) skips it entirely.
        if (!use_mask) {
            const zp = getStr(args, "--zones") orelse return err("planet/moon needs --zones");
            const zi = try terrain.loadZone(a, init.io, zp, world_seed, zone);
            if (!zi.found) return err("zone not found in --zones");
            base_params = terrain.buildParams(zi.radius, zi.has_water, zi.temp_label, zi.moist_label, zi.aux_label);
            classifier = try terrain.Classifier.init(a, &ctx, H.map_seed);
            std.debug.print("gpu_ore: planet/moon terrain gate — water {} biomes {d}\n", .{ zi.has_water, rt.len });
        } else {
            std.debug.print("gpu_ore: planet/moon — shared classify mask, {d} biomes\n", .{rt.len});
        }
    } else {
        b_restrict = ctx.uploadBuffer(u32, &[_]u32{0}, c.WGPUBufferUsage_Storage); // unused placeholder
        restrict_bytes = @sizeOf(u32);
    }
    defer c.wgpuBufferRelease(b_restrict);

    // Parse resources. Every SE ore resource shares ONE spot-noise generator
    // (seed1 == 100 — verified in the dump), so we concatenate all resources'
    // spots into single buffers, build one ResGPU param per resource, and upload
    // the shared generator once. The fused kernel evaluates all resources per
    // tile (see shaders/ore.wgsl).
    var all_spots: std.ArrayList(f32) = .empty; // 4 f32 per spot (x,y,peak,slope)
    var all_start: std.ArrayList(f32) = .empty;
    var rparams: std.ArrayList(ResGPU) = .empty;
    var rnames: std.ArrayList([]const u8) = .empty;
    var shared_seed1: u32 = 0;
    var has_seed1 = false;
    var has_any_start = false;
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
        // The fused kernel assumes ONE generator; refuse if a resource diverges.
        if (!has_seed1) {
            shared_seed1 = rh.seed1;
            has_seed1 = true;
        } else if (rh.seed1 != shared_seed1) return err("resources use different seed1 — fused kernel needs a shared generator");
        if (rh.has_starting == 1) has_any_start = true; // start_vein is used whenever has_starting

        const spot_off: u32 = @intCast(all_spots.items.len / 4);
        try all_spots.appendSlice(a, sp_f[0 .. nsp * 4]);
        const start_off: u32 = @intCast(all_start.items.len / 4);
        try all_start.appendSlice(a, st_f[0 .. nst * 4]);
        try rparams.append(a, .{
            .base_density = @floatCast(rh.base_density),
            .freq_mult = @floatCast(rh.freq_mult),
            .size_mult = @floatCast(rh.size_mult),
            .base_spots_per_km2 = @floatCast(rh.base_spots_per_km2),
            .rq = @floatCast(rh.rq),
            .smin = @floatCast(rh.smin),
            .smax = @floatCast(rh.smax),
            .basement_value = @floatCast(rh.basement_value),
            .richness_mult = @floatCast(rh.richness_mult),
            .additional_richness = @floatCast(rh.additional_richness),
            .starting_blob_amplitude = @floatCast(rh.starting_blob_amplitude),
            .roll_salt = rh.roll_salt,
            .res_index = @intCast(rparams.items.len),
            .has_starting = rh.has_starting,
            .restrict_bit = restrictBit(name),
            .spot_off = spot_off,
            .nspots = rh.nspots,
            .start_off = start_off,
            .nstart = rh.nstart,
        });
        try rnames.append(a, name);
    }
    const nres = rparams.items.len;
    if (nres == 0) return err("dump has no ore resources");

    // Shared generator (seed1 == 100) — perm/grad uploaded once. perm1+perm2 are
    // concatenated into one buffer ([0,256)=perm1, [256,512)=perm2) to stay under
    // the 8-storage-buffer-per-stage limit on Apple GPUs.
    const shgen = try buildGen(a, H.map_seed, shared_seed1);
    const perm12 = try a.alloc(u32, 512);
    @memcpy(perm12[0..256], shgen.perm1);
    @memcpy(perm12[256..512], shgen.perm2);
    const b_perm = ctx.uploadBuffer(u32, perm12, c.WGPUBufferUsage_Storage);
    const b_grad = ctx.uploadBuffer(f32, shgen.grad, c.WGPUBufferUsage_Storage);
    if (all_start.items.len == 0) try all_start.appendSlice(a, &.{ 0, 0, 0, 0 }); // WGSL needs a non-empty binding
    const b_spots = ctx.uploadBuffer(f32, all_spots.items, c.WGPUBufferUsage_Storage);
    const b_start = ctx.uploadBuffer(f32, all_start.items, c.WGPUBufferUsage_Storage);
    const b_rparams = ctx.uploadBuffer(ResGPU, rparams.items, c.WGPUBufferUsage_Storage);
    const spots_bytes: u64 = all_spots.items.len * @sizeOf(f32);
    const start_bytes: u64 = all_start.items.len * @sizeOf(f32);
    const rparams_bytes: u64 = rparams.items.len * @sizeOf(ResGPU);

    // Summary accumulators.
    const s_tiles = try a.alloc(u64, nres);
    const s_amount = try a.alloc(u64, nres);
    @memset(s_tiles, 0);
    @memset(s_amount, 0);

    // Phase timers (ns).
    var t_classify: u64 = 0;
    var t_ore: u64 = 0;
    var t_read: u64 = 0;
    var t_gpuwait: u64 = 0;
    var t_enc: u64 = 0;

    // Cull cells by the render EXTENT (R), matching the GUI's planSurfaceCells —
    // so the cell set + stitch line up with the CPU tiled path. The kernel also
    // gates ore to the disk of R (see OreParams.zone_radius), matching gpu_terrain's
    // circular field terrain.
    const cells = try cellList(a, R, @as(f64, @floatFromInt(R)), grid);
    std.debug.print("gpu_ore: {d} cells\n", .{cells.len});
    const t0 = wgpu.nowNs();

    const zdir = try std.fmt.allocPrint(a, "{s}/seed_{d}/{s}", .{ out_dir, world_seed, zone });
    std.Io.Dir.createDirPath(.cwd(), init.io, zdir) catch {};

    // --classify-only: run just the terrain/asteroid classify per cell and write
    // the shared biome mask (biome_<grid>_<cell>.bin) — consumed by the ore pass
    // (--mask) and by gpu_terrain (--mask), so the classify runs once per surface.
    if (classify_only) {
        for (cells) |cl| {
            var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
            defer cellArena.deinit();
            const ca = cellArena.allocator();
            const npx: usize = @as(usize, cl.cw) * cl.ch;
            const mask_bytes: u64 = npx * @sizeOf(u32);
            const buf_mask = ctx.makeBuffer(mask_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
            defer c.wgpuBufferRelease(buf_mask);
            const staging = ctx.makeBuffer(mask_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
            defer c.wgpuBufferRelease(staging);
            const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
            var kb: c.WGPUBindGroup = null;
            var kp: c.WGPUBuffer = null;
            if (is_field) {
                const p = AsteroidParams{ .origin_x = @floatFromInt(cl.x0), .origin_y = @floatFromInt(cl.y0), .size = @floatCast(ast_size), .freq = @floatCast(ast_freq), .planet_radius = @floatCast(ast_pr), .width = cl.cw, .height = cl.ch, .seed_byte = ag.sb };
                const bp = ctx.uploadBuffer(AsteroidParams, &.{p}, c.WGPUBufferUsage_Uniform);
                var e = [_]c.WGPUBindGroupEntry{
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bp, .size = @sizeOf(AsteroidParams) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = ab1, .size = 256 * @sizeOf(u32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = ab2, .size = 256 * @sizeOf(u32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = ab3, .size = 512 * @sizeOf(f32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_mask, .size = mask_bytes }),
                };
                kb = addPass(&ctx, enc, ast_pipe, ast_bgl, &e, cl.cw, cl.ch);
                kp = bp;
            } else {
                const r = classifier.?.classifyInto(enc, base_params, cl.x0, cl.y0, cl.cw, cl.ch, buf_mask);
                kb = r.bg;
                kp = r.params;
            }
            c.wgpuCommandEncoderCopyBufferToBuffer(enc, buf_mask, 0, staging, 0, mask_bytes);
            const cmd = c.wgpuCommandEncoderFinish(enc, null);
            c.wgpuCommandEncoderRelease(enc);
            c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
            c.wgpuCommandBufferRelease(cmd);
            const mask = try ca.alloc(u32, npx);
            try ctx.readBuffer(staging, u32, mask);
            c.wgpuBindGroupRelease(kb);
            c.wgpuBufferRelease(kp);
            var mb: [1200]u8 = undefined;
            const path = try maskPath(&mb, zdir, grid, cl.cell);
            const f = try std.Io.Dir.createFile(.cwd(), init.io, path, .{});
            f.writePositionalAll(init.io, std.mem.sliceAsBytes(mask), 0) catch {};
            f.close(init.io);
        }
        std.debug.print("gpu_ore: wrote {d} classify mask cells in {d:.0}ms\n", .{ cells.len, @as(f64, @floatFromInt(wgpu.nowNs() - t0)) / 1e6 });
        return;
    }

    // Collect each cell's RGBA; encoded in parallel after the loop.
    var jobs: std.ArrayListUnmanaged(EncJob) = .empty;

    for (cells) |cl| {
        var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer cellArena.deinit();
        const ca = cellArena.allocator();
        const npx: usize = @as(usize, cl.cw) * cl.ch;
        const mask_bytes: u64 = npx * @sizeOf(u32);
        const out_bytes: u64 = npx * 8; // packed vec2<u32>/tile (res+1, richness f32) — the readback

        // Per-tile gate buffer: field → asteroid mask (0/1/2); planet → biome
        // index (water = >=60000). With --mask it's read from the shared classify
        // stage; otherwise classified inline (a pass appended to the cell's
        // command buffer below).
        const tc0 = wgpu.nowNs();
        var buf_mask: c.WGPUBuffer = undefined;
        var loaded = false;
        if (use_mask) {
            var mb: [1200]u8 = undefined;
            const path = maskPath(&mb, zdir, grid, cl.cell) catch "";
            if (path.len > 0) {
                if (std.Io.Dir.readFileAlloc(.cwd(), init.io, path, ca, .unlimited)) |raw| {
                    if (raw.len == mask_bytes) {
                        buf_mask = ctx.uploadBuffer(u8, raw, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
                        loaded = true;
                    }
                } else |_| {}
            }
        }
        if (!loaded) buf_mask = ctx.makeBuffer(mask_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_mask);

        // The fused ore kernel writes the packed winner (res+1, richness) here.
        const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
        defer c.wgpuBufferRelease(buf_out);
        const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
        defer c.wgpuBufferRelease(staging);

        // One command buffer for the whole cell (classify (if not loaded) + every
        // ore pass + copy) → one submit and one GPU sync per cell.
        const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        const Keep = struct { bg: c.WGPUBindGroup, buf: c.WGPUBuffer };
        var keep: std.ArrayListUnmanaged(Keep) = .empty;

        if (!loaded) {
            if (is_field) {
                const p = AsteroidParams{ .origin_x = @floatFromInt(cl.x0), .origin_y = @floatFromInt(cl.y0), .size = @floatCast(ast_size), .freq = @floatCast(ast_freq), .planet_radius = @floatCast(ast_pr), .width = cl.cw, .height = cl.ch, .seed_byte = ag.sb };
                const bp = ctx.uploadBuffer(AsteroidParams, &.{p}, c.WGPUBufferUsage_Uniform);
                var e = [_]c.WGPUBindGroupEntry{
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bp, .size = @sizeOf(AsteroidParams) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = ab1, .size = 256 * @sizeOf(u32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = ab2, .size = 256 * @sizeOf(u32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = ab3, .size = 512 * @sizeOf(f32) }),
                    std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_mask, .size = mask_bytes }),
                };
                const bg = addPass(&ctx, enc, ast_pipe, ast_bgl, &e, cl.cw, cl.ch);
                try keep.append(ca, .{ .bg = bg, .buf = bp });
            } else {
                const r = classifier.?.classifyInto(enc, base_params, cl.x0, cl.y0, cl.cw, cl.ch, buf_mask);
                try keep.append(ca, .{ .bg = r.bg, .buf = r.params });
            }
        }
        t_classify += wgpu.nowNs() - tc0;

        const to0 = wgpu.nowNs();
        {
            // ONE fused dispatch evaluates all resources per tile → buf_out.
            // Disk gate = the render EXTENT (R), matching gpu_terrain's field
            // terrain; the density math uses distance directly so the gate doesn't
            // affect values, only which tiles are kept.
            const P = Shared{
                .origin_x = @floatFromInt(cl.x0),
                .origin_y = @floatFromInt(cl.y0),
                .width = cl.cw,
                .height = cl.ch,
                .zone_radius = @floatFromInt(R),
                .seed_byte = shgen.sb,
                .is_field = if (is_field) 1 else 0,
                .nres = @intCast(nres),
                .has_any_start = if (has_any_start) 1 else 0,
            };
            const bP = ctx.uploadBuffer(Shared, &.{P}, c.WGPUBufferUsage_Uniform);
            var e = [_]c.WGPUBindGroupEntry{
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bP, .size = @sizeOf(Shared) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = b_perm, .size = 512 * @sizeOf(u32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = b_grad, .size = 512 * @sizeOf(f32) }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = b_spots, .size = spots_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = b_start, .size = start_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = buf_mask, .size = mask_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = buf_out, .size = out_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 7, .buffer = b_restrict, .size = restrict_bytes }),
                std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 8, .buffer = b_rparams, .size = rparams_bytes }),
            };
            const bg = addPass(&ctx, enc, ore_pipe, ore_bgl, &e, cl.cw, cl.ch);
            try keep.append(ca, .{ .bg = bg, .buf = bP });
        }
        t_ore += wgpu.nowNs() - to0;

        // Finish the cell's command buffer: copy packed winners → staging, submit
        // once, read back (one GPU sync), then release the pass bind groups.
        c.wgpuCommandEncoderCopyBufferToBuffer(enc, buf_out, 0, staging, 0, out_bytes);
        const cmd = c.wgpuCommandEncoderFinish(enc, null);
        c.wgpuCommandEncoderRelease(enc);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);
        const pk = try ca.alloc(u32, npx * 2);
        const tw0 = wgpu.nowNs();
        ctx.poll(); // block until the GPU finishes the cell's passes (compute)
        t_gpuwait += wgpu.nowNs() - tw0;
        const tr0 = wgpu.nowNs();
        const mapped = try ctx.mapRead(staging, out_bytes); // GPU already idle → just maps
        @memcpy(pk, @as([*]const u32, @ptrCast(@alignCast(mapped)))[0 .. npx * 2]);
        ctx.unmap(staging);
        t_read += wgpu.nowNs() - tr0;
        for (keep.items) |k| {
            c.wgpuBindGroupRelease(k.bg);
            c.wgpuBufferRelease(k.buf);
        }

        const te0 = wgpu.nowNs();
        const rgba = try a.alloc(u8, npx * 4); // arena — persists to the parallel encode
        @memset(rgba, 0);
        for (0..npx) |i| {
            const type_i = pk[i * 2]; // res_index + 1 (0 = empty)
            if (type_i == 0) continue;
            const rr = type_i - 1;
            const richness: f32 = @bitCast(pk[i * 2 + 1]);
            const amount: u64 = @intFromFloat(@floor(richness));
            const col = mapColor(rnames.items[rr]);
            rgba[i * 4 ..][0..4].* = .{ col[0], col[1], col[2], 255 };
            s_tiles[rr] += 1;
            s_amount[rr] += amount;
        }
        try jobs.append(a, .{ .rgba = rgba, .cw = cl.cw, .ch = cl.ch, .cell = cl.cell });
        t_enc += wgpu.nowNs() - te0;
    }
    // Encode + write all cells across worker threads (strided).
    const tp0 = wgpu.nowNs();
    const nenc: usize = @max(1, @min(std.Thread.getCpuCount() catch 4, jobs.items.len));
    const ctxs = try a.alloc(EncCtx, nenc);
    for (ctxs, 0..) |*cx, k| cx.* = .{ .jobs = jobs.items, .start = k, .stride = nenc, .io = init.io, .dir = zdir, .grid = grid };
    const ethreads = try a.alloc(std.Thread, nenc);
    for (ethreads, ctxs) |*t, *cx| t.* = try std.Thread.spawn(.{}, EncCtx.run, .{cx});
    for (ethreads) |t| t.join();
    for (ctxs) |cx| if (cx.err) |e| return e;
    t_enc += wgpu.nowNs() - tp0;
    const ms = struct {
        fn f(ns: u64) f64 {
            return @as(f64, @floatFromInt(ns)) / 1e6;
        }
    }.f;
    std.debug.print("gpu_ore profile: classify {d:.0}ms | ore-record {d:.0}ms | gpu-compute {d:.0}ms | readback {d:.0}ms | png {d:.0}ms  ({d} cells, {d} resources)\n", .{ ms(t_classify), ms(t_ore), ms(t_gpuwait), ms(t_read), ms(t_enc), cells.len, nres });

    // summary.json
    var sum: std.ArrayList(u8) = .empty;
    try sum.appendSlice(a, try std.fmt.allocPrint(a, "{{\"zone\":\"{s}\",\"zone_seed\":{d},\"radius\":{d},\"resources\":{{", .{ zone, H.map_seed, R }));
    var first = true;
    for (rnames.items, 0..) |name, idx| {
        if (s_tiles[idx] == 0) continue;
        if (!first) try sum.appendSlice(a, ",");
        first = false;
        try sum.appendSlice(a, try std.fmt.allocPrint(a, "\"{s}\":{{\"amount\":{d},\"tiles\":{d}}}", .{ name, s_amount[idx], s_tiles[idx] }));
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

// Record one compute pass into `enc` (no submit) so a cell's dispatches batch
// into a single command buffer → one submit + one GPU sync per cell instead of
// one per dispatch. Returns the bind group (release after submit). Separate
// passes are auto-barriered by wgpu, preserving the buf_win RMW ordering.
fn addPass(ctx: *wgpu.Context, enc: c.WGPUCommandEncoder, pipe: c.WGPUComputePipeline, bgl: c.WGPUBindGroupLayout, entries: []c.WGPUBindGroupEntry, w: u32, h: u32) c.WGPUBindGroup {
    var bgd = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = entries.ptr });
    const bg = c.wgpuDeviceCreateBindGroup(ctx.device, &bgd);
    var pd = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
    const pass = c.wgpuCommandEncoderBeginComputePass(enc, &pd);
    c.wgpuComputePassEncoderSetPipeline(pass, pipe);
    c.wgpuComputePassEncoderSetBindGroup(pass, 0, bg, 0, null);
    c.wgpuComputePassEncoderDispatchWorkgroups(pass, (w + 7) / 8, (h + 7) / 8, 1);
    c.wgpuComputePassEncoderEnd(pass);
    c.wgpuComputePassEncoderRelease(pass);
    return bg;
}
