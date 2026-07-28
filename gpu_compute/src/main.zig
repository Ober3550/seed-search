//! Phase 0 — wgpu-native toolchain proof.
//!
//! Headless compute: uploads two f32 arrays, runs the `add.wgsl` kernel on the
//! GPU (Metal on macOS; Vulkan/D3D12 on Linux/Windows once those prebuilts are
//! fetched), reads the result back, and verifies out[i] == a[i] + b[i].
//!
//! Proves device → pipeline → dispatch → readback end-to-end. See the module
//! README + noise_conformance.zig (Phase 1) for the real noise port.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;

const shader_src = @embedFile("shaders/add.wgsl");

const N: u32 = 1 << 20; // 1,048,576 elements

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    const pipeline = try ctx.computePipeline(shader_src, "main");
    defer c.wgpuComputePipelineRelease(pipeline);

    // Host input data
    const a = try alloc.alloc(f32, N);
    defer alloc.free(a);
    const b = try alloc.alloc(f32, N);
    defer alloc.free(b);
    for (a, b, 0..) |*va, *vb, i| {
        va.* = @floatFromInt(i);
        vb.* = @as(f32, @floatFromInt(i)) * 2.0;
    }

    const bytes: u64 = @as(u64, N) * @sizeOf(f32);
    const buf_a = ctx.uploadBuffer(f32, a, c.WGPUBufferUsage_Storage);
    const buf_b = ctx.uploadBuffer(f32, b, c.WGPUBufferUsage_Storage);
    const buf_out = ctx.makeBuffer(bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = ctx.makeBuffer(bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_a, buf_b, buf_out, staging }) |bb| c.wgpuBufferRelease(bb);

    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_a, .size = bytes }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_b, .size = bytes }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_out, .size = bytes }),
    };
    var bg_desc = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = entries.len, .entries = &entries });
    const bind_group = c.wgpuDeviceCreateBindGroup(ctx.device, &bg_desc);
    defer c.wgpuBindGroupRelease(bind_group);

    const encoder = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
    var pass_desc = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
    const pass = c.wgpuCommandEncoderBeginComputePass(encoder, &pass_desc);
    c.wgpuComputePassEncoderSetPipeline(pass, pipeline);
    c.wgpuComputePassEncoderSetBindGroup(pass, 0, bind_group, 0, null);
    c.wgpuComputePassEncoderDispatchWorkgroups(pass, (N + 63) / 64, 1, 1);
    c.wgpuComputePassEncoderEnd(pass);
    c.wgpuComputePassEncoderRelease(pass);
    c.wgpuCommandEncoderCopyBufferToBuffer(encoder, buf_out, 0, staging, 0, bytes);
    const cmd = c.wgpuCommandEncoderFinish(encoder, null);
    c.wgpuCommandEncoderRelease(encoder);
    c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
    c.wgpuCommandBufferRelease(cmd);

    const out = try alloc.alloc(f32, N);
    defer alloc.free(out);
    try ctx.readBuffer(staging, f32, out);

    var mismatches: u32 = 0;
    for (0..N) |i| {
        if (out[i] != a[i] + b[i]) mismatches += 1;
    }
    if (mismatches == 0) {
        std.debug.print("✅ Phase 0 OK — {d} elements, out[i] == a[i]+b[i] (e.g. out[100]={d})\n", .{ N, out[100] });
    } else {
        std.debug.print("❌ {d}/{d} mismatches\n", .{ mismatches, N });
        return error.Mismatch;
    }
}
