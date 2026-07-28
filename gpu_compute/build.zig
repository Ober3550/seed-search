const std = @import("std");

// Maps a resolved target to the wgpu-native prebuilt directory under vendor/.
// fetch-wgpu.sh downloads these; only the host triple is required to build.
fn vendorTriple(t: std.Target) []const u8 {
    return switch (t.os.tag) {
        .macos => switch (t.cpu.arch) {
            .aarch64 => "wgpu-macos-aarch64",
            .x86_64 => "wgpu-macos-x86_64",
            else => @panic("unsupported macOS arch — add it to fetch-wgpu.sh + vendorTriple"),
        },
        .linux => switch (t.cpu.arch) {
            .aarch64 => "wgpu-linux-aarch64",
            .x86_64 => "wgpu-linux-x86_64",
            else => @panic("unsupported linux arch"),
        },
        .windows => switch (t.cpu.arch) {
            .x86_64 => "wgpu-windows-x86_64-msvc",
            .aarch64 => "wgpu-windows-aarch64-msvc",
            else => @panic("unsupported windows arch"),
        },
        else => @panic("unsupported OS for wgpu-native"),
    };
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const triple = vendorTriple(target.result);
    const inc = b.fmt("vendor/{s}/include", .{triple});
    const lib = b.fmt("vendor/{s}/lib", .{triple});

    const exe = b.addExecutable(.{
        .name = "gpu_compute",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    exe.root_module.addIncludePath(b.path(inc));
    exe.root_module.addLibraryPath(b.path(lib));
    exe.root_module.linkSystemLibrary("wgpu_native", .{});
    // libwgpu_native.dylib has install_name @rpath/... — bake the vendor lib
    // dir as an rpath so the loader finds it without DYLD_LIBRARY_PATH.
    exe.root_module.addRPath(b.path(lib));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the Phase 0 wgpu compute proof");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
}
