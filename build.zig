const std = @import("std");

pub fn build(b: *std.Build) void {
    const models_mod = b.createModule(.{
        .root_source_file = b.path("src/models/mod.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "cargoSpaceAvailable",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    exe.root_module.addImport("models", models_mod);
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
