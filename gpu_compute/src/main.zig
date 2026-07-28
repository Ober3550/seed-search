//! Phase 0 — wgpu-native toolchain proof.
//!
//! Headless compute: uploads two f32 arrays, runs the `add.wgsl` kernel on the
//! GPU (Metal on macOS; Vulkan/D3D12 on Linux/Windows once those prebuilts are
//! fetched), reads the result back, and verifies out[i] == a[i] + b[i].
//!
//! This proves device creation → pipeline → dispatch → readback end-to-end
//! before we port the terrain noise+classify kernel (see the module README).

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;

const shader_src = @embedFile("shaders/add.wgsl");

const N: u32 = 1 << 20; // 1,048,576 elements

// ── async request plumbing ────────────────────────────────────────────────
// wgpu-native fires these callbacks synchronously inside the request call, but
// we still pump events + poll so the same code works on truly-async backends.

const AdapterResp = struct { adapter: c.WGPUAdapter = null, done: bool = false, ok: bool = false };
const DeviceResp = struct { device: c.WGPUDevice = null, done: bool = false, ok: bool = false };
const MapResp = struct { done: bool = false, ok: bool = false };

fn onAdapter(status: c.WGPURequestAdapterStatus, adapter: c.WGPUAdapter, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
    _ = ud2;
    const r: *AdapterResp = @ptrCast(@alignCast(ud1.?));
    r.adapter = adapter;
    r.ok = status == c.WGPURequestAdapterStatus_Success;
    r.done = true;
    if (!r.ok) std.debug.print("adapter request failed: {s}\n", .{wgpu.fromStrView(msg)});
}

fn onDevice(status: c.WGPURequestDeviceStatus, device: c.WGPUDevice, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
    _ = ud2;
    const r: *DeviceResp = @ptrCast(@alignCast(ud1.?));
    r.device = device;
    r.ok = status == c.WGPURequestDeviceStatus_Success;
    r.done = true;
    if (!r.ok) std.debug.print("device request failed: {s}\n", .{wgpu.fromStrView(msg)});
}

fn onMap(status: c.WGPUMapAsyncStatus, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
    _ = ud2;
    const r: *MapResp = @ptrCast(@alignCast(ud1.?));
    r.ok = status == c.WGPUMapAsyncStatus_Success;
    r.done = true;
    if (!r.ok) std.debug.print("buffer map failed: {s}\n", .{wgpu.fromStrView(msg)});
}

fn onLog(level: c.WGPULogLevel, msg: c.WGPUStringView, ud: ?*anyopaque) callconv(.c) void {
    _ = ud;
    _ = level;
    std.debug.print("[wgpu] {s}\n", .{wgpu.fromStrView(msg)});
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    c.wgpuSetLogLevel(c.WGPULogLevel_Warn);
    c.wgpuSetLogCallback(onLog, null);

    // 1. Instance
    const instance = c.wgpuCreateInstance(null) orelse return error.NoInstance;
    defer c.wgpuInstanceRelease(instance);

    // 2. Adapter (async → pump instance events until the callback lands)
    var ar = AdapterResp{};
    _ = c.wgpuInstanceRequestAdapter(instance, null, .{
        .mode = c.WGPUCallbackMode_AllowProcessEvents,
        .callback = onAdapter,
        .userdata1 = &ar,
    });
    while (!ar.done) c.wgpuInstanceProcessEvents(instance);
    if (!ar.ok) return error.NoAdapter;
    const adapter = ar.adapter.?;
    defer c.wgpuAdapterRelease(adapter);
    reportAdapter(adapter);

    // 3. Device + queue
    var dr = DeviceResp{};
    _ = c.wgpuAdapterRequestDevice(adapter, null, .{
        .mode = c.WGPUCallbackMode_AllowProcessEvents,
        .callback = onDevice,
        .userdata1 = &dr,
    });
    while (!dr.done) c.wgpuInstanceProcessEvents(instance);
    if (!dr.ok) return error.NoDevice;
    const device = dr.device.?;
    defer c.wgpuDeviceRelease(device);
    const queue = c.wgpuDeviceGetQueue(device);
    defer c.wgpuQueueRelease(queue);

    // 4. Shader module + compute pipeline
    var wgsl = std.mem.zeroInit(c.WGPUShaderSourceWGSL, .{
        .chain = .{ .sType = c.WGPUSType_ShaderSourceWGSL },
        .code = wgpu.strView(shader_src),
    });
    var sm_desc = std.mem.zeroInit(c.WGPUShaderModuleDescriptor, .{ .nextInChain = &wgsl.chain });
    const module = c.wgpuDeviceCreateShaderModule(device, &sm_desc) orelse return error.ShaderModule;
    defer c.wgpuShaderModuleRelease(module);

    var cp_desc = std.mem.zeroInit(c.WGPUComputePipelineDescriptor, .{
        .compute = .{ .module = module, .entryPoint = wgpu.strView("main") },
    });
    const pipeline = c.wgpuDeviceCreateComputePipeline(device, &cp_desc) orelse return error.Pipeline;
    defer c.wgpuComputePipelineRelease(pipeline);

    // 5. Buffers
    const bytes: u64 = @as(u64, N) * @sizeOf(f32);
    const buf_a = makeBuffer(device, bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopyDst);
    const buf_b = makeBuffer(device, bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopyDst);
    const buf_out = makeBuffer(device, bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    const staging = makeBuffer(device, bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer for ([_]c.WGPUBuffer{ buf_a, buf_b, buf_out, staging }) |bb| c.wgpuBufferRelease(bb);

    // Host input data
    const a = try alloc.alloc(f32, N);
    defer alloc.free(a);
    const b = try alloc.alloc(f32, N);
    defer alloc.free(b);
    for (a, b, 0..) |*va, *vb, i| {
        va.* = @floatFromInt(i);
        vb.* = @as(f32, @floatFromInt(i)) * 2.0;
    }
    c.wgpuQueueWriteBuffer(queue, buf_a, 0, a.ptr, bytes);
    c.wgpuQueueWriteBuffer(queue, buf_b, 0, b.ptr, bytes);

    // 6. Bind group (layout comes from the pipeline)
    const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0);
    defer c.wgpuBindGroupLayoutRelease(bgl);
    var entries = [_]c.WGPUBindGroupEntry{
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = buf_a, .size = bytes }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = buf_b, .size = bytes }),
        std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = buf_out, .size = bytes }),
    };
    var bg_desc = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{
        .layout = bgl,
        .entryCount = entries.len,
        .entries = &entries,
    });
    const bind_group = c.wgpuDeviceCreateBindGroup(device, &bg_desc);
    defer c.wgpuBindGroupRelease(bind_group);

    // 7. Encode: compute pass → dispatch → copy out → staging → submit
    const encoder = c.wgpuDeviceCreateCommandEncoder(device, null);
    var pass_desc = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
    const pass = c.wgpuCommandEncoderBeginComputePass(encoder, &pass_desc);
    c.wgpuComputePassEncoderSetPipeline(pass, pipeline);
    c.wgpuComputePassEncoderSetBindGroup(pass, 0, bind_group, 0, null);
    const groups = (N + 63) / 64;
    c.wgpuComputePassEncoderDispatchWorkgroups(pass, groups, 1, 1);
    c.wgpuComputePassEncoderEnd(pass);
    c.wgpuComputePassEncoderRelease(pass);
    c.wgpuCommandEncoderCopyBufferToBuffer(encoder, buf_out, 0, staging, 0, bytes);
    const cmd = c.wgpuCommandEncoderFinish(encoder, null);
    c.wgpuCommandEncoderRelease(encoder);
    c.wgpuQueueSubmit(queue, 1, &cmd);
    c.wgpuCommandBufferRelease(cmd);

    // 8. Map staging + verify
    var mr = MapResp{};
    _ = c.wgpuBufferMapAsync(staging, c.WGPUMapMode_Read, 0, bytes, .{
        .mode = c.WGPUCallbackMode_AllowProcessEvents,
        .callback = onMap,
        .userdata1 = &mr,
    });
    while (!mr.done) _ = c.wgpuDevicePoll(device, 1, null);
    if (!mr.ok) return error.MapFailed;

    const mapped = c.wgpuBufferGetConstMappedRange(staging, 0, bytes) orelse return error.NoMappedRange;
    const out: [*]const f32 = @ptrCast(@alignCast(mapped));
    var mismatches: u32 = 0;
    for (0..N) |i| {
        if (out[i] != a[i] + b[i]) mismatches += 1;
    }
    c.wgpuBufferUnmap(staging);

    if (mismatches == 0) {
        std.debug.print("✅ Phase 0 OK — {d} elements, out[i] == a[i]+b[i] (e.g. out[100]={d})\n", .{ N, out[100] });
    } else {
        std.debug.print("❌ {d}/{d} mismatches\n", .{ mismatches, N });
        return error.Mismatch;
    }
}

fn makeBuffer(device: c.WGPUDevice, size: u64, usage: c.WGPUBufferUsage) c.WGPUBuffer {
    var d = std.mem.zeroInit(c.WGPUBufferDescriptor, .{ .size = size, .usage = usage });
    return c.wgpuDeviceCreateBuffer(device, &d);
}

fn reportAdapter(adapter: c.WGPUAdapter) void {
    var info = std.mem.zeroes(c.WGPUAdapterInfo);
    if (c.wgpuAdapterGetInfo(adapter, &info) == c.WGPUStatus_Success) {
        std.debug.print("adapter: {s} — {s} (backend {d})\n", .{
            wgpu.fromStrView(info.device),
            wgpu.fromStrView(info.description),
            info.backendType,
        });
        c.wgpuAdapterInfoFreeMembers(info);
    }
}
