//! Phase 3 finale — chained end-to-end terrain render + benchmark.
//!
//! Runs the full pipeline (elevation + temp/moisture/aux + biome classify) in a
//! single GPU dispatch, writes a BMP, and benchmarks GPU vs CPU single-thread vs
//! CPU thread-pool. GPU inputs are computed on-GPU, so a few biome-edge tiles
//! differ from the CPU (f32-vs-f64 drift) — the render is a fast preview.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const terrain = surfgen.terrain;
const biome = surfgen.biome;

const render_wgsl = @embedFile("shaders/render.wgsl");

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
    has_water: u32 = 1,
    _pa: u32 = 0,
    _pb: u32 = 0,
    _pc: u32 = 0,
}; // 25 f32 + 7 u32 = 128 bytes (16-aligned)

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

const W: u32 = 1024;
const H: u32 = 1024;
const MAP_SEED: u32 = 0x1234567;
const ORIGIN_X: f64 = 3000.0;
const ORIGIN_Y: f64 = 3000.0;
const NGEN = 192;
const OUT_PNG: [*:0]const u8 = "render-out.png";

const CFG = terrain.ZoneTerrain.Config{
    .map_seed = MAP_SEED,
    .moisture_frequency = 1.0,
    .moisture_bias = 0.0,
    .aux_frequency = 1.0,
    .aux_bias = 0.0,
    .temperature_frequency = 1.0,
    .temperature_bias = 0.0,
    .cold_size = 6.0,
    .hot_size = 6.0,
    .cold_frequency = 4.8053212165833,
    .hot_frequency = 4.8053212165833,
    .water_frequency = 1.0,
    .water_size = 1.42,
};

fn cpuTile(zt: *const terrain.ZoneTerrain, cl: *const biome.Classifier, gx: usize, gy: usize) u32 {
    const x = ORIGIN_X + @as(f64, @floatFromInt(gx));
    const y = ORIGIN_Y + @as(f64, @floatFromInt(gy));
    const e = zt.elev.at(x, y);
    const t = zt.temperature(x, y);
    const m = zt.moisture(x, y);
    const a = zt.aux(x, y);
    return cl.classifyIdx(x, y, t, m, a, e);
}

const RowJob = struct {
    zt: *const terrain.ZoneTerrain,
    cl: *const biome.Classifier,
    out: []u32,
    y0: usize,
    y1: usize,
    fn run(j: RowJob) void {
        var gy = j.y0;
        while (gy < j.y1) : (gy += 1) {
            var gx: usize = 0;
            while (gx < W) : (gx += 1) j.out[gy * W + gx] = cpuTile(j.zt, j.cl, gx, gy);
        }
    }
};

fn packGen(gi: usize, g: noise.BasisNoiseGen, p1: []u32, p2: []u32, gr: []f32, sb: []u32) void {
    sb[gi] = g.seed_byte;
    for (0..256) |i| {
        p1[gi * 256 + i] = g.perm1[i];
        p2[gi * 256 + i] = g.perm2[i];
        gr[gi * 512 + 2 * i] = g.grad[i][0];
        gr[gi * 512 + 2 * i + 1] = g.grad[i][1];
    }
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const n = W * H;
    const nb = biome.biomes.len;

    const zt = terrain.ZoneTerrain.init(CFG);
    const classifier = biome.Classifier.init(MAP_SEED);

    // ── CPU single-thread benchmark ─────────────────────────────────────────
    const cpu1 = try alloc.alloc(u32, n);
    defer alloc.free(cpu1);
    const t_cpu1_0 = wgpu.nowNs();
    for (0..H) |gy| {
        for (0..W) |gx| cpu1[gy * W + gx] = cpuTile(&zt, &classifier, gx, gy);
    }
    const cpu1_ms = @as(f64, @floatFromInt(wgpu.nowNs() - t_cpu1_0)) / 1e6;

    // ── CPU thread-pool benchmark ───────────────────────────────────────────
    const cpuN = try alloc.alloc(u32, n);
    defer alloc.free(cpuN);
    const nthreads = @max(@as(usize, 1), std.Thread.getCpuCount() catch 8);
    const t_cpuN_0 = wgpu.nowNs();
    {
        var threads = try alloc.alloc(std.Thread, nthreads);
        defer alloc.free(threads);
        const rows_per = (H + nthreads - 1) / nthreads;
        var spawned: usize = 0;
        for (0..nthreads) |ti| {
            const y0 = ti * rows_per;
            if (y0 >= H) break;
            const y1 = @min(y0 + rows_per, H);
            threads[ti] = try std.Thread.spawn(.{}, RowJob.run, .{RowJob{ .zt = &zt, .cl = &classifier, .out = cpuN, .y0 = y0, .y1 = y1 }});
            spawned += 1;
        }
        for (0..spawned) |ti| threads[ti].join();
    }
    const cpuN_ms = @as(f64, @floatFromInt(wgpu.nowNs() - t_cpuN_0)) / 1e6;

    // ── Pack 192 generators + biome table ───────────────────────────────────
    const perm1 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm1);
    const perm2 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm2);
    const grad = try alloc.alloc(f32, NGEN * 512);
    defer alloc.free(grad);
    const seed_bytes = try alloc.alloc(u32, NGEN);
    defer alloc.free(seed_bytes);
    const table = try alloc.alloc(BiomeGPU, nb);
    defer alloc.free(table);

    const elev_seed1 = [_]u32{ 900, 99584, 700, 1000, 1100, 500, 600 };
    for (elev_seed1, 0..) |s1, i| packGen(i, noise.BasisNoiseGen.init(MAP_SEED, s1), perm1, perm2, grad, seed_bytes);
    for (0..11) |k| packGen(7 + k, noise.BasisNoiseGen.init(MAP_SEED +% @as(u32, @intCast(k)), 5), perm1, perm2, grad, seed_bytes);
    for (0..8) |k| packGen(18 + k, noise.BasisNoiseGen.init(MAP_SEED +% @as(u32, @intCast(k)), 6), perm1, perm2, grad, seed_bytes);
    for (0..8) |k| packGen(26 + k, noise.BasisNoiseGen.init(MAP_SEED +% @as(u32, @intCast(k)), 7), perm1, perm2, grad, seed_bytes);
    for (biome.biomes, 0..) |b, i| {
        packGen(34 + i, noise.BasisNoiseGen.init(MAP_SEED, b.tv_seed), perm1, perm2, grad, seed_bytes);
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
    packGen(190, noise.BasisNoiseGen.init(MAP_SEED, biome.WATER_SEED), perm1, perm2, grad, seed_bytes);
    packGen(191, noise.BasisNoiseGen.init(MAP_SEED, biome.CRATER_SEED), perm1, perm2, grad, seed_bytes);

    const nsm = zt.elev.nsm;
    const os_pers = (1.0 - 0.7) / std.math.pow(f64, 2.0, 5.0) / (1.0 - std.math.pow(f64, 0.7, 5.0)) * 0.5;
    const params = Params{
        .origin_x = @floatCast(ORIGIN_X),
        .origin_y = @floatCast(ORIGIN_Y),
        .nsm = @floatCast(nsm),
        .seg = @floatCast(zt.elev.seg),
        .water_level = @floatCast(zt.elev.water_level),
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
        .cold_size = @floatCast(CFG.cold_size),
        .hot_size = @floatCast(CFG.hot_size),
        .cold_freq = @floatCast(CFG.cold_frequency),
        .hot_freq = @floatCast(CFG.hot_frequency),
        .moist_freq = @floatCast(CFG.moisture_frequency),
        .moist_bias = @floatCast(CFG.moisture_bias),
        .aux_freq = @floatCast(CFG.aux_frequency),
        .aux_bias = @floatCast(CFG.aux_bias),
        .width = W,
        .height = H,
        .n_biomes = @intCast(nb),
    };

    // ── GPU run ─────────────────────────────────────────────────────────────
    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(render_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_params = ctx.uploadBuffer(Params, &.{params}, c.WGPUBufferUsage_Uniform);
    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    const buf_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage);
    const buf_table = ctx.uploadBuffer(BiomeGPU, table, c.WGPUBufferUsage_Storage);
    const out_bytes: u64 = @as(u64, n) * @sizeOf(u32);
    const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_params, buf_perm1, buf_perm2, buf_grad, buf_sb, buf_table, buf_out, staging }) |b| c.wgpuBufferRelease(b);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
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

    const gpu_idx = try alloc.alloc(u32, n);
    defer alloc.free(gpu_idx);

    const t_gpu_0 = wgpu.nowNs();
    const encoder = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
    var pass_desc = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
    const pass = c.wgpuCommandEncoderBeginComputePass(encoder, &pass_desc);
    c.wgpuComputePassEncoderSetPipeline(pass, pipeline);
    c.wgpuComputePassEncoderSetBindGroup(pass, 0, bind_group, 0, null);
    c.wgpuComputePassEncoderDispatchWorkgroups(pass, (W + 7) / 8, (H + 7) / 8, 1);
    c.wgpuComputePassEncoderEnd(pass);
    c.wgpuComputePassEncoderRelease(pass);
    c.wgpuCommandEncoderCopyBufferToBuffer(encoder, buf_out, 0, staging, 0, out_bytes);
    const cmd = c.wgpuCommandEncoderFinish(encoder, null);
    c.wgpuCommandEncoderRelease(encoder);
    c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
    c.wgpuCommandBufferRelease(cmd);
    try ctx.readBuffer(staging, u32, gpu_idx);
    const gpu_ms = @as(f64, @floatFromInt(wgpu.nowNs() - t_gpu_0)) / 1e6;

    // ── Agreement (GPU has on-GPU f32 t/m/a/e; expect a small edge diff) ─────
    var mismatch: u32 = 0;
    for (0..n) |i| {
        if (cpu1[i] != gpu_idx[i]) mismatch += 1;
    }
    const agree = 100.0 * @as(f64, @floatFromInt(n - mismatch)) / @as(f64, @floatFromInt(n));

    // ── Write PNG from the GPU indices (zigimg encode + libc write) ─────────
    const rgb = try alloc.alloc(u8, n * 3);
    defer alloc.free(rgb);
    for (0..n) |i| {
        const col = biome.idxColor(@intCast(gpu_idx[i]));
        rgb[3 * i] = col[0];
        rgb[3 * i + 1] = col[1];
        rgb[3 * i + 2] = col[2];
    }
    const png_bytes = try surfgen.png.encode(alloc, W, H, rgb);
    defer alloc.free(png_bytes);
    try wgpu.writeFileC(OUT_PNG, png_bytes);

    // ── Report ──────────────────────────────────────────────────────────────
    std.debug.print(
        "\n=== render {d}x{d} ({d} tiles) ===\n" ++
            "  CPU  1-thread : {d:>8.1} ms   ({d:.2} Mtile/s)\n" ++
            "  CPU  {d:>2}-thread: {d:>8.1} ms   ({d:.2} Mtile/s)  [{d:.1}x vs 1-thread]\n" ++
            "  GPU  (Metal)  : {d:>8.1} ms   ({d:.2} Mtile/s)  [{d:.1}x vs 1-thread, {d:.1}x vs pool]\n" ++
            "  GPU-vs-CPU biome agreement: {d:.3}% ({d} edge tiles differ)\n" ++
            "  wrote {s}\n",
        .{
            W,                                            H,                             n,
            cpu1_ms,                                      mtiles(n, cpu1_ms),            nthreads,
            cpuN_ms,                                      mtiles(n, cpuN_ms),            cpu1_ms / cpuN_ms,
            gpu_ms,                                       mtiles(n, gpu_ms),             cpu1_ms / gpu_ms,
            cpuN_ms / gpu_ms,                             agree,                         mismatch,
            OUT_PNG,
        },
    );
}

fn mtiles(n: u32, ms: f64) f64 {
    return @as(f64, @floatFromInt(n)) / (ms / 1000.0) / 1e6;
}

// (BMP writer removed — output is PNG via zigimg now)
