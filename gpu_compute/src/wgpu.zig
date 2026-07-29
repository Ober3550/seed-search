//! Thin wrapper over the vendored wgpu-native (v29.0.1.1) C API.
//!
//! We deliberately use @cImport rather than hand-written bindings so the whole
//! webgpu.h / wgpu.h surface stays in sync with whatever release fetch-wgpu.sh
//! pulled — the C API still shifts between versions (StringView, callback-info
//! async, etc.), and auto-translation is the only sane way to track it.

const std = @import("std");

pub const c = @cImport({
    @cInclude("webgpu/webgpu.h");
    @cInclude("webgpu/wgpu.h");
    @cInclude("time.h");
    @cInclude("stdio.h");
});

/// Write bytes to a file via libc (std.fs moved behind the Io interface in 0.16).
pub fn writeFileC(path: [*:0]const u8, data: []const u8) !void {
    const f = c.fopen(path, "wb") orelse return error.OpenFailed;
    defer _ = c.fclose(f);
    if (c.fwrite(data.ptr, 1, data.len, f) != data.len) return error.WriteFailed;
}

/// Monotonic nanoseconds (std.time.Timer was removed in Zig 0.16; we link libc).
pub fn nowNs() u64 {
    var ts: c.struct_timespec = undefined;
    _ = c.clock_gettime(c.CLOCK_MONOTONIC, &ts);
    return @as(u64, @intCast(ts.tv_sec)) * 1_000_000_000 + @as(u64, @intCast(ts.tv_nsec));
}

/// A WGPUStringView over a Zig slice. WebGPU v29 takes strings as (ptr,len)
/// pairs rather than NUL-terminated char*, so every label/entryPoint/code goes
/// through here.
pub fn strView(s: []const u8) c.WGPUStringView {
    return .{ .data = s.ptr, .length = s.len };
}

/// Read a WGPUStringView back into a Zig slice (for messages from callbacks).
pub fn fromStrView(sv: c.WGPUStringView) []const u8 {
    if (sv.data == null or sv.length == 0) return "";
    // WGPU_STRLEN (SIZE_MAX) means "NUL-terminated"; callbacks give real lengths.
    if (sv.length == std.math.maxInt(usize)) return std.mem.span(@as([*:0]const u8, @ptrCast(sv.data)));
    return sv.data[0..sv.length];
}

// ── Context: instance/adapter/device/queue + common compute helpers ─────────
// wgpu-native fires request callbacks synchronously, but we still pump events /
// poll so the same code works on truly-async backends.

fn onLog(level: c.WGPULogLevel, msg: c.WGPUStringView, ud: ?*anyopaque) callconv(.c) void {
    _ = ud;
    _ = level;
    std.debug.print("[wgpu] {s}\n", .{fromStrView(msg)});
}

pub const Context = struct {
    instance: c.WGPUInstance,
    adapter: c.WGPUAdapter,
    device: c.WGPUDevice,
    queue: c.WGPUQueue,

    const AdapterResp = struct { adapter: c.WGPUAdapter = null, done: bool = false, ok: bool = false };
    const DeviceResp = struct { device: c.WGPUDevice = null, done: bool = false, ok: bool = false };
    const MapResp = struct { done: bool = false, ok: bool = false };

    fn onAdapter(status: c.WGPURequestAdapterStatus, adapter: c.WGPUAdapter, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
        _ = ud2;
        const r: *AdapterResp = @ptrCast(@alignCast(ud1.?));
        r.adapter = adapter;
        r.ok = status == c.WGPURequestAdapterStatus_Success;
        r.done = true;
        if (!r.ok) std.debug.print("adapter request failed: {s}\n", .{fromStrView(msg)});
    }
    fn onDevice(status: c.WGPURequestDeviceStatus, device: c.WGPUDevice, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
        _ = ud2;
        const r: *DeviceResp = @ptrCast(@alignCast(ud1.?));
        r.device = device;
        r.ok = status == c.WGPURequestDeviceStatus_Success;
        r.done = true;
        if (!r.ok) std.debug.print("device request failed: {s}\n", .{fromStrView(msg)});
    }
    fn onMap(status: c.WGPUMapAsyncStatus, msg: c.WGPUStringView, ud1: ?*anyopaque, ud2: ?*anyopaque) callconv(.c) void {
        _ = ud2;
        const r: *MapResp = @ptrCast(@alignCast(ud1.?));
        r.ok = status == c.WGPUMapAsyncStatus_Success;
        r.done = true;
        if (!r.ok) std.debug.print("buffer map failed: {s}\n", .{fromStrView(msg)});
    }

    pub fn init() !Context {
        c.wgpuSetLogLevel(c.WGPULogLevel_Warn);
        c.wgpuSetLogCallback(onLog, null);

        const instance = c.wgpuCreateInstance(null) orelse return error.NoInstance;

        var ar = AdapterResp{};
        _ = c.wgpuInstanceRequestAdapter(instance, null, .{
            .mode = c.WGPUCallbackMode_AllowProcessEvents,
            .callback = onAdapter,
            .userdata1 = &ar,
        });
        while (!ar.done) c.wgpuInstanceProcessEvents(instance);
        if (!ar.ok) return error.NoAdapter;
        const adapter = ar.adapter.?;

        // Request the adapter's full limits so we get its real maximums (the
        // default device limits cap storage buffers at 8 per stage; the fused ore
        // kernel + spot-bin buffers need more, and Apple GPUs support far more).
        var limits = std.mem.zeroes(c.WGPULimits);
        _ = c.wgpuAdapterGetLimits(adapter, &limits);
        const dev_desc = std.mem.zeroInit(c.WGPUDeviceDescriptor, .{ .requiredLimits = &limits });

        var dr = DeviceResp{};
        _ = c.wgpuAdapterRequestDevice(adapter, &dev_desc, .{
            .mode = c.WGPUCallbackMode_AllowProcessEvents,
            .callback = onDevice,
            .userdata1 = &dr,
        });
        while (!dr.done) c.wgpuInstanceProcessEvents(instance);
        if (!dr.ok) return error.NoDevice;
        const device = dr.device.?;

        return .{ .instance = instance, .adapter = adapter, .device = device, .queue = c.wgpuDeviceGetQueue(device) };
    }

    pub fn deinit(self: *Context) void {
        c.wgpuQueueRelease(self.queue);
        c.wgpuDeviceRelease(self.device);
        c.wgpuAdapterRelease(self.adapter);
        c.wgpuInstanceRelease(self.instance);
    }

    pub fn adapterName(self: *Context) []const u8 {
        var info = std.mem.zeroes(c.WGPUAdapterInfo);
        if (c.wgpuAdapterGetInfo(self.adapter, &info) == c.WGPUStatus_Success) {
            return fromStrView(info.device); // borrowed; caller prints immediately
        }
        return "unknown";
    }

    pub fn makeBuffer(self: *Context, size: u64, usage: c.WGPUBufferUsage) c.WGPUBuffer {
        var d = std.mem.zeroInit(c.WGPUBufferDescriptor, .{ .size = size, .usage = usage });
        return c.wgpuDeviceCreateBuffer(self.device, &d);
    }

    /// Create a storage buffer and upload `data` into it (usage gets CopyDst).
    pub fn uploadBuffer(self: *Context, comptime T: type, data: []const T, usage: c.WGPUBufferUsage) c.WGPUBuffer {
        const size: u64 = data.len * @sizeOf(T);
        const buf = self.makeBuffer(size, usage | c.WGPUBufferUsage_CopyDst);
        c.wgpuQueueWriteBuffer(self.queue, buf, 0, data.ptr, size);
        return buf;
    }

    /// Compile a WGSL compute pipeline. Returns the pipeline; the shader module
    /// is released internally (the pipeline retains what it needs).
    pub fn computePipeline(self: *Context, wgsl_src: []const u8, entry: []const u8) !c.WGPUComputePipeline {
        var wgsl = std.mem.zeroInit(c.WGPUShaderSourceWGSL, .{
            .chain = .{ .sType = c.WGPUSType_ShaderSourceWGSL },
            .code = strView(wgsl_src),
        });
        var sm_desc = std.mem.zeroInit(c.WGPUShaderModuleDescriptor, .{ .nextInChain = &wgsl.chain });
        const module = c.wgpuDeviceCreateShaderModule(self.device, &sm_desc) orelse return error.ShaderModule;
        defer c.wgpuShaderModuleRelease(module);
        var cp = std.mem.zeroInit(c.WGPUComputePipelineDescriptor, .{
            .compute = .{ .module = module, .entryPoint = strView(entry) },
        });
        return c.wgpuDeviceCreateComputePipeline(self.device, &cp) orelse error.Pipeline;
    }

    pub fn poll(self: *Context) void {
        _ = c.wgpuDevicePoll(self.device, 1, null);
    }

    /// Map a MapRead buffer for reading, blocking (poll loop) until the GPU has
    /// finished producing it. Returns the mapped range; caller must `unmap`.
    pub fn mapRead(self: *Context, staging: c.WGPUBuffer, size: u64) ![*]const u8 {
        var mr = MapResp{};
        _ = c.wgpuBufferMapAsync(staging, c.WGPUMapMode_Read, 0, size, .{
            .mode = c.WGPUCallbackMode_AllowProcessEvents,
            .callback = onMap,
            .userdata1 = &mr,
        });
        while (!mr.done) self.poll();
        if (!mr.ok) return error.MapFailed;
        const mapped = c.wgpuBufferGetConstMappedRange(staging, 0, size) orelse return error.NoMappedRange;
        return @ptrCast(mapped);
    }

    pub fn unmap(self: *Context, staging: c.WGPUBuffer) void {
        _ = self;
        c.wgpuBufferUnmap(staging);
    }

    /// Map a MapRead buffer and copy its contents into `out`.
    pub fn readBuffer(self: *Context, staging: c.WGPUBuffer, comptime T: type, out: []T) !void {
        const size: u64 = out.len * @sizeOf(T);
        const mapped = try self.mapRead(staging, size);
        const src: [*]const T = @ptrCast(@alignCast(mapped));
        @memcpy(out, src[0..out.len]);
        self.unmap(staging);
    }
};
