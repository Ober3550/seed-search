//! Phase 3b — CPU-vs-GPU conformance for biome classification.
//!
//! Feeds identical t/m/a/e (computed once on the CPU) to both the CPU
//! `classifyIdx` oracle and `shaders/biome.wgsl`, so any difference is purely
//! the classifier port (argmax over 156 land biomes + 4 water tiles), not
//! accumulated tma/elevation drift. Reports biome-index agreement.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const terrain = surfgen.terrain;
const biome = surfgen.biome;

const biome_wgsl = @embedFile("shaders/biome.wgsl");

const Params = extern struct {
    origin_x: f32,
    origin_y: f32,
    width: u32,
    height: u32,
    n_biomes: u32,
    _pad0: u32 = 0,
    _pad1: u32 = 0,
    _pad2: u32 = 0, // pad 20 -> 32
};

// Matches `struct BiomeGPU` in biome.wgsl (48 bytes).
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

const W: u32 = 512;
const H: u32 = 512;
const MAP_SEED: u32 = 0x1234567;
const ORIGIN_X: f64 = 3000.0;
const ORIGIN_Y: f64 = 3000.0;
const NGEN = biome.biomes.len + 2; // 156 tv + water + crater

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

fn packRange(r: ?[2]f64, lo: *f32, hi: *f32, active_bit: u32, flags: *u32) void {
    if (r) |rr| {
        lo.* = @floatCast(rr[0]);
        hi.* = @floatCast(rr[1]);
        flags.* |= active_bit;
    }
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const n = W * H;
    const nb = biome.biomes.len;

    // ── CPU: compute t/m/a/e, then classifyIdx ──────────────────────────────
    const zt = terrain.ZoneTerrain.init(CFG);
    const classifier = biome.Classifier.init(MAP_SEED);
    const tmae = try alloc.alloc(f32, 4 * n);
    defer alloc.free(tmae);
    const cpu_idx = try alloc.alloc(u32, n);
    defer alloc.free(cpu_idx);
    for (0..H) |gy| {
        for (0..W) |gx| {
            const x = ORIGIN_X + @as(f64, @floatFromInt(gx));
            const y = ORIGIN_Y + @as(f64, @floatFromInt(gy));
            const i = gy * W + gx;
            const t = zt.temperature(x, y);
            const m = zt.moisture(x, y);
            const a = zt.aux(x, y);
            const e = zt.elev.at(x, y);
            tmae[i] = @floatCast(t);
            tmae[n + i] = @floatCast(m);
            tmae[2 * n + i] = @floatCast(a);
            tmae[3 * n + i] = @floatCast(e);
            cpu_idx[i] = classifier.classifyIdx(x, y, t, m, a, e);
        }
    }

    // ── Pack 158 generators + the biome table ───────────────────────────────
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

    const packGen = struct {
        fn go(gi: usize, g: noise.BasisNoiseGen, p1: []u32, p2: []u32, gr: []f32, sb: []u32) void {
            sb[gi] = g.seed_byte;
            for (0..256) |i| {
                p1[gi * 256 + i] = g.perm1[i];
                p2[gi * 256 + i] = g.perm2[i];
                gr[gi * 512 + 2 * i] = g.grad[i][0];
                gr[gi * 512 + 2 * i + 1] = g.grad[i][1];
            }
        }
    }.go;

    for (biome.biomes, 0..) |b, i| {
        packGen(i, noise.BasisNoiseGen.init(MAP_SEED, b.tv_seed), perm1, perm2, grad, seed_bytes);
        var bd = BiomeGPU{ .water_coef = @floatCast(b.water_coef) };
        packRange(b.t, &bd.t_lo, &bd.t_hi, 1, &bd.flags);
        packRange(b.m, &bd.m_lo, &bd.m_hi, 2, &bd.flags);
        packRange(b.a, &bd.a_lo, &bd.a_hi, 4, &bd.flags);
        packRange(b.e, &bd.e_lo, &bd.e_hi, 8, &bd.flags);
        if (b.beach_weight < 0.0) bd.flags |= 16;
        if (b.crater) bd.flags |= 32;
        table[i] = bd;
    }
    packGen(nb, noise.BasisNoiseGen.init(MAP_SEED, biome.WATER_SEED), perm1, perm2, grad, seed_bytes);
    packGen(nb + 1, noise.BasisNoiseGen.init(MAP_SEED, biome.CRATER_SEED), perm1, perm2, grad, seed_bytes);

    const params = Params{ .origin_x = @floatCast(ORIGIN_X), .origin_y = @floatCast(ORIGIN_Y), .width = W, .height = H, .n_biomes = @intCast(nb) };

    // ── GPU run ─────────────────────────────────────────────────────────────
    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(biome_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_params = ctx.uploadBuffer(Params, &.{params}, c.WGPUBufferUsage_Uniform);
    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    const buf_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage);
    const buf_table = ctx.uploadBuffer(BiomeGPU, table, c.WGPUBufferUsage_Storage);
    const buf_tmae = ctx.uploadBuffer(f32, tmae, c.WGPUBufferUsage_Storage);
    const out_bytes: u64 = @as(u64, n) * @sizeOf(u32);
    const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_params, buf_perm1, buf_perm2, buf_grad, buf_sb, buf_table, buf_tmae, buf_out, staging }) |b| c.wgpuBufferRelease(b);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(Params) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_perm1, .size = perm1.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_perm2, .size = perm2.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = buf_grad, .size = grad.len * @sizeOf(f32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_sb, .size = seed_bytes.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = buf_table, .size = table.len * @sizeOf(BiomeGPU) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = buf_tmae, .size = tmae.len * @sizeOf(f32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 7, .buffer = buf_out, .size = out_bytes }),
    };
    var bg_desc = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = &entries });
    const bind_group = c.wgpuDeviceCreateBindGroup(ctx.device, &bg_desc);
    defer c.wgpuBindGroupRelease(bind_group);

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

    const gpu_idx = try alloc.alloc(u32, n);
    defer alloc.free(gpu_idx);
    try ctx.readBuffer(staging, u32, gpu_idx);

    // ── Compare biome-index agreement ───────────────────────────────────────
    var mismatch: u32 = 0;
    for (0..n) |i| {
        if (cpu_idx[i] != gpu_idx[i]) mismatch += 1;
    }
    const pct = 100.0 * @as(f64, @floatFromInt(n - mismatch)) / @as(f64, @floatFromInt(n));
    std.debug.print(
        "grid {d}x{d} @ ({d},{d}), {d} biomes, {d} generators\n" ++
            "  biome-index agreement {d:.3}% ({d}/{d} differ)\n",
        .{ W, H, ORIGIN_X, ORIGIN_Y, nb, NGEN, pct, mismatch, n },
    );

    if (pct >= 99.0) {
        std.debug.print("✅ Phase 3b conformance PASS (biome agreement {d:.3}% >= 99.0%)\n", .{pct});
    } else {
        std.debug.print("❌ Phase 3b conformance FAIL (biome agreement {d:.3}% < 99.0%)\n", .{pct});
        return error.Diverged;
    }
}
