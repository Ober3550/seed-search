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
});

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
