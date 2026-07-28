const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // zigimg for PNG encoding (src/png.zig).
    const zigimg = b.dependency("zigimg", .{ .target = target, .optimize = optimize }).module("zigimg");

    const mod = b.addModule("surface_generator", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{.{ .name = "zigimg", .module = zigimg }},
    });

    const exe = b.addExecutable(.{
        .name = "surfacegen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "surface_generator", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run surfacegen");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    // Universe generator (zone controls from world seed + tags), shared with
    // the zone-driver mode of segen.
    const universe_mod = b.addModule("universe_gen", .{
        .root_source_file = b.path("../universe_generator/zig/gen.zig"),
        .target = target,
    });

    // SE surface generator (Space Exploration zones).
    const se_exe = b.addExecutable(.{
        .name = "segen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/se_main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "surface_generator", .module = mod },
                .{ .name = "universe_gen", .module = universe_mod },
            },
        }),
    });
    b.installArtifact(se_exe);
    const se_run_step = b.step("segen", "Run SE surface generator");
    const se_run_cmd = b.addRunArtifact(se_exe);
    se_run_step.dependOn(&se_run_cmd.step);
    se_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| se_run_cmd.addArgs(args);

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
