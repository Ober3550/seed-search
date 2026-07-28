//! Phase 1 — CPU-vs-GPU conformance for the multioctave noise primitive.
//!
//! Runs noise.zig's `multioctaveNoiseOffset` over a grid on the CPU (the
//! bit-exact oracle) and the same via `shaders/noise.wgsl` on the GPU, then
//! reports the max absolute difference. This is the guard that keeps the WGSL
//! kernel and the Zig CPU path from drifting as we build up to full elevation.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const noise = @import("surfgen").noise;

const noise_wgsl = @embedFile("shaders/noise.wgsl");

// Must match `struct Params` in noise.wgsl (std140-ish: scalars at 4-byte
// offsets, struct size padded to a multiple of 16).
const Params = extern struct {
    origin_x: f32,
    origin_y: f32,
    input_scale: f32,
    output_scale: f32,
    ampmul: f32,
    offset_x: f32,
    offset_y: f32,
    width: u32,
    height: u32,
    octaves: u32,
    seed_byte: u32,
    _pad0: u32 = 0, // pad 44 -> 48 bytes
};

// Test configuration (a representative elevation-style multioctave call).
const W: u32 = 128;
const H: u32 = 128;
const SEED0: u32 = 0x1234567;
const SEED1: u32 = 900;
const OCTAVES: u32 = 8;
const PERSISTENCE: f64 = 0.6;
const INPUT_SCALE: f64 = 1.0 / 64.0;
const OUTPUT_SCALE: f64 = 1.0;
const OFFSET_X: f64 = 0.0;
const OFFSET_Y: f64 = 0.0;

pub fn main() !void {
    const alloc = std.heap.c_allocator;
    const n = W * H;

    // ── Build the seeded generator on the CPU (Fisher-Yates, once) ──────────
    const gen = noise.BasisNoiseGen.init(SEED0, SEED1);

    // ── CPU reference grid ──────────────────────────────────────────────────
    const cpu = try alloc.alloc(f32, n);
    defer alloc.free(cpu);
    for (0..H) |gy| {
        for (0..W) |gx| {
            const x: f64 = @floatFromInt(gx);
            const y: f64 = @floatFromInt(gy);
            const v = noise.multioctaveNoiseOffset(&gen, x, y, OCTAVES, PERSISTENCE, INPUT_SCALE, OUTPUT_SCALE, OFFSET_X, OFFSET_Y);
            cpu[gy * W + gx] = @floatCast(v);
        }
    }

    // ── Flatten the generator's tables for upload ───────────────────────────
    var perm1: [256]u32 = undefined;
    var perm2: [256]u32 = undefined;
    var grad: [512]f32 = undefined;
    for (0..256) |i| {
        perm1[i] = gen.perm1[i];
        perm2[i] = gen.perm2[i];
        grad[2 * i] = gen.grad[i][0];
        grad[2 * i + 1] = gen.grad[i][1];
    }

    const params = Params{
        .origin_x = 0.0,
        .origin_y = 0.0,
        .input_scale = @floatCast(INPUT_SCALE),
        .output_scale = @floatCast(OUTPUT_SCALE),
        .ampmul = @floatCast(1.0 / PERSISTENCE),
        .offset_x = @floatCast(OFFSET_X),
        .offset_y = @floatCast(OFFSET_Y),
        .width = W,
        .height = H,
        .octaves = OCTAVES,
        .seed_byte = gen.seed_byte,
    };

    // ── GPU run ─────────────────────────────────────────────────────────────
    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(noise_wgsl, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    const buf_params = ctx.uploadBuffer(Params, &.{params}, c.WGPUBufferUsage_Uniform);
    const buf_perm1 = ctx.uploadBuffer(u32, &perm1, c.WGPUBufferUsage_Storage);
    const buf_perm2 = ctx.uploadBuffer(u32, &perm2, c.WGPUBufferUsage_Storage);
    const buf_grad = ctx.uploadBuffer(f32, &grad, c.WGPUBufferUsage_Storage);
    const out_bytes: u64 = @as(u64, n) * @sizeOf(f32);
    const buf_out = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(out_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_params, buf_perm1, buf_perm2, buf_grad, buf_out, staging }) |b| c.wgpuBufferRelease(b);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_params, .size = @sizeOf(Params) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_perm1, .size = @as(u64, perm1.len) * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_perm2, .size = @as(u64, perm2.len) * @sizeOf(u32) }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = buf_grad, .size = @as(u64, grad.len) * @sizeOf(f32) }),
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

    // ── Compare ─────────────────────────────────────────────────────────────
    var max_abs: f64 = 0.0;
    var max_rel: f64 = 0.0;
    var argmax: usize = 0;
    var sum_abs: f64 = 0.0;
    for (0..n) |i| {
        const d = @abs(@as(f64, cpu[i]) - @as(f64, gpu[i]));
        sum_abs += d;
        if (d > max_abs) {
            max_abs = d;
            argmax = i;
        }
        const denom = @abs(@as(f64, cpu[i]));
        if (denom > 1e-6) {
            const r = d / denom;
            if (r > max_rel) max_rel = r;
        }
    }
    std.debug.print(
        "grid {d}x{d}, octaves {d}, seed0 0x{x} seed1 {d}\n" ++
            "  max abs diff = {e:.3}  (cpu={d:.6} gpu={d:.6} at [{d},{d}])\n" ++
            "  mean abs diff = {e:.3}   max rel diff = {e:.3}\n",
        .{ W, H, OCTAVES, SEED0, SEED1, max_abs, cpu[argmax], gpu[argmax], argmax % W, argmax / W, sum_abs / @as(f64, @floatFromInt(n)), max_rel },
    );

    // f32 tolerance: allow a few ULPs of drift (FMA contraction, transcendental
    // rounding). Anything larger means the kernel and CPU path have diverged.
    if (max_abs <= 1e-5) {
        std.debug.print("✅ Phase 1 conformance PASS (max abs diff {e:.3} <= 1e-5)\n", .{max_abs});
    } else {
        std.debug.print("❌ Phase 1 conformance FAIL (max abs diff {e:.3} > 1e-5)\n", .{max_abs});
        return error.Diverged;
    }
}
