//! Phase 3a — CPU-vs-GPU conformance for temperature/moisture/aux.
//!
//! These use quick_multioctave_noise (a fresh generator per octave, seed0+k),
//! so 27 generator sets are uploaded. Field math is f32 on both sides, so the
//! diffs should be tighter than the elevation composition.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const terrain = surfgen.terrain;

const tma_wgsl = @embedFile("shaders/tma.wgsl");

const Params = extern struct {
    origin_x: f32,
    origin_y: f32,
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
}; // 10 f32 + 2 u32 = 48 bytes (16-aligned)

const W: u32 = 512;
const H: u32 = 512;
const MAP_SEED: u32 = 0x1234567;
const ORIGIN_X: f64 = 3000.0;
const ORIGIN_Y: f64 = 3000.0;

// Horaerratum ZoneTerrain defaults.
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

// (gbase index, count, seed1) for each generator group, matching tma.wgsl.
const GROUPS = [_]struct { base: usize, count: usize, seed1: u32 }{
    .{ .base = 0, .count = 11, .seed1 = 5 },
    .{ .base = 11, .count = 8, .seed1 = 6 },
    .{ .base = 19, .count = 8, .seed1 = 7 },
};
const NGEN = 27;

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const n = W * H;

    // ── CPU oracle ──────────────────────────────────────────────────────────
    const zt = terrain.ZoneTerrain.init(CFG);
    const cpu = try alloc.alloc(f32, 3 * n); // t | m | a
    defer alloc.free(cpu);
    for (0..H) |gy| {
        for (0..W) |gx| {
            const x = ORIGIN_X + @as(f64, @floatFromInt(gx));
            const y = ORIGIN_Y + @as(f64, @floatFromInt(gy));
            const i = gy * W + gx;
            cpu[i] = @floatCast(zt.temperature(x, y));
            cpu[n + i] = @floatCast(zt.moisture(x, y));
            cpu[2 * n + i] = @floatCast(zt.aux(x, y));
        }
    }

    // ── Pack 27 generators (seed0+k, seed1 per group) ───────────────────────
    var perm1 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm1);
    var perm2 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm2);
    var grad = try alloc.alloc(f32, NGEN * 512);
    defer alloc.free(grad);
    var seed_bytes = try alloc.alloc(u32, NGEN);
    defer alloc.free(seed_bytes);
    for (GROUPS) |grp| {
        for (0..grp.count) |k| {
            const gi = grp.base + k;
            const g = noise.BasisNoiseGen.init(MAP_SEED +% @as(u32, @intCast(k)), grp.seed1);
            seed_bytes[gi] = g.seed_byte;
            for (0..256) |i| {
                perm1[gi * 256 + i] = g.perm1[i];
                perm2[gi * 256 + i] = g.perm2[i];
                grad[gi * 512 + 2 * i] = g.grad[i][0];
                grad[gi * 512 + 2 * i + 1] = g.grad[i][1];
            }
        }
    }

    const params = Params{
        .origin_x = @floatCast(ORIGIN_X),
        .origin_y = @floatCast(ORIGIN_Y),
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
    };

    // ── GPU run ─────────────────────────────────────────────────────────────
    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(tma_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_params = ctx.uploadBuffer(Params, &.{params}, c.WGPUBufferUsage_Uniform);
    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    const buf_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage);
    const out_bytes: u64 = @as(u64, 3 * n) * @sizeOf(f32);
    const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_params, buf_perm1, buf_perm2, buf_grad, buf_sb, buf_out, staging }) |b| c.wgpuBufferRelease(b);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(Params) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_perm1, .size = perm1.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_perm2, .size = perm2.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = buf_grad, .size = grad.len * @sizeOf(f32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_sb, .size = seed_bytes.len * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = buf_out, .size = out_bytes }),
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

    const gpu = try alloc.alloc(f32, 3 * n);
    defer alloc.free(gpu);
    try ctx.readBuffer(staging, f32, gpu);

    // ── Compare each field ──────────────────────────────────────────────────
    const names = [_][]const u8{ "temperature", "moisture   ", "aux        " };
    var worst: f64 = 0.0;
    for (0..3) |field| {
        var max_abs: f64 = 0.0;
        var sum_abs: f64 = 0.0;
        for (0..n) |i| {
            const idx = field * n + i;
            const d = @abs(@as(f64, cpu[idx]) - @as(f64, gpu[idx]));
            sum_abs += d;
            if (d > max_abs) max_abs = d;
        }
        if (max_abs > worst) worst = max_abs;
        std.debug.print("  {s}: max abs diff = {e:.3}, mean = {e:.3}\n", .{ names[field], max_abs, sum_abs / @as(f64, @floatFromInt(n)) });
    }

    // temperature spans ~[-20,150]; moisture/aux ~[0,1]. Allow modest f32
    // coordinate-precision drift on the large temperature coords.
    if (worst <= 5e-2) {
        std.debug.print("✅ Phase 3a conformance PASS (worst field max abs diff {e:.3} <= 5e-2)\n", .{worst});
    } else {
        std.debug.print("❌ Phase 3a conformance FAIL (worst field max abs diff {e:.3} > 5e-2)\n", .{worst});
        return error.Diverged;
    }
}
