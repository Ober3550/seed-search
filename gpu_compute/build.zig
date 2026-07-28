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

    // The CPU noise oracle lives in surface_generator; import noise.zig directly
    // (it pulls in rng.zig relatively) so the conformance test can call it.
    const noise_mod = b.addModule("noise", .{
        .root_source_file = b.path("../surface_generator/src/noise.zig"),
        .target = target,
    });

    // Links wgpu-native (dylib install_name is @rpath/..., so bake an rpath) onto
    // whichever exe we build.
    const linkWgpu = struct {
        fn apply(e: *std.Build.Step.Compile, bb: *std.Build, i: []const u8, l: []const u8) void {
            e.root_module.addIncludePath(bb.path(i));
            e.root_module.addLibraryPath(bb.path(l));
            e.root_module.linkSystemLibrary("wgpu_native", .{});
            e.root_module.addRPath(bb.path(l));
        }
    }.apply;

    // Phase 0 — add-arrays toolchain proof.
    const exe = b.addExecutable(.{
        .name = "gpu_compute",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    linkWgpu(exe, b, inc, lib);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the Phase 0 wgpu compute proof");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    // Phase 1 — CPU-vs-GPU multioctave noise conformance.
    const conf = b.addExecutable(.{
        .name = "noise_conformance",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/noise_conformance.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{.{ .name = "noise", .module = noise_mod }},
        }),
    });
    linkWgpu(conf, b, inc, lib);
    b.installArtifact(conf);

    const conf_step = b.step("conformance", "Run the Phase 1 noise conformance test");
    const conf_cmd = b.addRunArtifact(conf);
    conf_step.dependOn(&conf_cmd.step);
    conf_cmd.step.dependOn(b.getInstallStep());
}
