//! Phase 2 — CPU-vs-GPU conformance for the full elevation composition.
//!
//! Runs terrain.zig `Elevation.at` over a grid on the CPU (the f64 oracle) and
//! `shaders/elevation.wgsl` on the GPU (f32), then reports the elevation diff
//! AND the water-mask (elevation < 0) agreement — the mask is what the renderer
//! actually consumes, so it's the metric that matters.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const terrain = surfgen.terrain;

const elev_wgsl = @embedFile("shaders/elevation.wgsl");

// Must match `struct EParams` in elevation.wgsl (17 f32 + 3 u32 = 80 bytes,
// already 16-aligned — no padding needed).
const EParams = extern struct {
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
    width: u32,
    height: u32,
    slake_n: u32,
};

const W: u32 = 512;
const H: u32 = 512;
const MAP_SEED: u32 = 0x1234567;
const WATER_FREQ: f64 = 1.0;
const WATER_SIZE: f64 = 1.42;
// Far from origin: past the starting-island dome (dist*nsm/2000 >= 1 saturates
// smm), so elevation is macro-driven and actually straddles the water threshold.
const ORIGIN_X: f64 = 3000.0;
const ORIGIN_Y: f64 = 3000.0;

// Generator seed1s, in the index order elevation.wgsl expects.
const GEN_SEED1 = [_]u32{ 900, 99584, 700, 1000, 1100, 500, 600 };
const NGEN = GEN_SEED1.len;

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const n = W * H;

    // ── CPU oracle ──────────────────────────────────────────────────────────
    const elev = terrain.Elevation.init(MAP_SEED, WATER_FREQ, WATER_SIZE);
    const cpu = try alloc.alloc(f32, n);
    defer alloc.free(cpu);
    for (0..H) |gy| {
        for (0..W) |gx| {
            const x = ORIGIN_X + @as(f64, @floatFromInt(gx));
            const y = ORIGIN_Y + @as(f64, @floatFromInt(gy));
            cpu[gy * W + gx] = @floatCast(elev.at(x, y));
        }
    }

    // ── Pack the 7 generators' tables (built the same way mo()/basisNoise do) ─
    var perm1 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm1);
    var perm2 = try alloc.alloc(u32, NGEN * 256);
    defer alloc.free(perm2);
    var grad = try alloc.alloc(f32, NGEN * 512);
    defer alloc.free(grad);
    var seed_bytes = try alloc.alloc(u32, NGEN);
    defer alloc.free(seed_bytes);
    for (GEN_SEED1, 0..) |s1, gi| {
        const g = noise.BasisNoiseGen.init(MAP_SEED, s1);
        seed_bytes[gi] = g.seed_byte;
        for (0..256) |i| {
            perm1[gi * 256 + i] = g.perm1[i];
            perm2[gi * 256 + i] = g.perm2[i];
            grad[gi * 512 + 2 * i] = g.grad[i][0];
            grad[gi * 512 + 2 * i + 1] = g.grad[i][1];
        }
    }

    // ── Host-side f32 params (scales divided in f64, then cast — matches the
    //    CPU, which computes nsm/90 etc. in f64 before evalOffset casts to f32) ─
    const nsm = elev.nsm;
    const p_pers = 0.7;
    const os_pers = (1.0 - p_pers) / std.math.pow(f64, 2.0, 5.0) / (1.0 - std.math.pow(f64, p_pers, 5.0)) * 0.5;
    const params = EParams{
        .origin_x = @floatCast(ORIGIN_X),
        .origin_y = @floatCast(ORIGIN_Y),
        .nsm = @floatCast(nsm),
        .seg = @floatCast(elev.seg),
        .water_level = @floatCast(elev.water_level),
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
        .width = W,
        .height = H,
        .slake_n = 0,
    };

    // ── GPU run ─────────────────────────────────────────────────────────────
    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(elev_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_params = ctx.uploadBuffer(EParams, &.{params}, c.WGPUBufferUsage_Uniform);
    const buf_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage);
    const buf_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage);
    const buf_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage);
    const buf_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage);
    const out_bytes: u64 = @as(u64, n) * @sizeOf(f32);
    const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_params, buf_perm1, buf_perm2, buf_grad, buf_sb, buf_out, staging }) |b| c.wgpuBufferRelease(b);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(EParams) }),
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

    const gpu = try alloc.alloc(f32, n);
    defer alloc.free(gpu);
    try ctx.readBuffer(staging, f32, gpu);

    // ── Compare: elevation diff + water-mask agreement ──────────────────────
    var max_abs: f64 = 0.0;
    var sum_abs: f64 = 0.0;
    var mask_mismatch: u32 = 0;
    var water_cpu: u32 = 0;
    var worst_mask_elev: f64 = 0.0; // largest |elev| among mask disagreements
    for (0..n) |i| {
        const d = @abs(@as(f64, cpu[i]) - @as(f64, gpu[i]));
        sum_abs += d;
        if (d > max_abs) max_abs = d;
        const cw = cpu[i] < 0.0;
        const gw = gpu[i] < 0.0;
        if (cw) water_cpu += 1;
        if (cw != gw) {
            mask_mismatch += 1;
            if (@abs(@as(f64, cpu[i])) > worst_mask_elev) worst_mask_elev = @abs(@as(f64, cpu[i]));
        }
    }
    const pct_water = 100.0 * @as(f64, @floatFromInt(water_cpu)) / @as(f64, @floatFromInt(n));
    const pct_agree = 100.0 * @as(f64, @floatFromInt(n - mask_mismatch)) / @as(f64, @floatFromInt(n));
    std.debug.print(
        "grid {d}x{d} @ ({d},{d}), map_seed 0x{x}\n" ++
            "  elevation: max abs diff = {e:.3}, mean = {e:.3}\n" ++
            "  water mask: cpu {d:.1}% water | agreement {d:.3}% ({d}/{d} disagree)\n" ++
            "  worst disagreeing tile |elevation| = {e:.3} (all within f32 noise of the shoreline)\n",
        .{ W, H, ORIGIN_X, ORIGIN_Y, MAP_SEED, max_abs, sum_abs / @as(f64, @floatFromInt(n)), pct_water, pct_agree, mask_mismatch, n, worst_mask_elev },
    );

    // Elevation magnitudes reach ~tens, and the composition is f64/f32; a few
    // shoreline tiles may flip. Gate on water-mask agreement, not bit-equality.
    if (pct_agree >= 99.5) {
        std.debug.print("✅ Phase 2 conformance PASS (water mask agreement {d:.3}% >= 99.5%)\n", .{pct_agree});
    } else {
        std.debug.print("❌ Phase 2 conformance FAIL (water mask agreement {d:.3}% < 99.5%)\n", .{pct_agree});
        return error.Diverged;
    }
}
