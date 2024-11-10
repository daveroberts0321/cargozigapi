const std = @import("std");

pub fn build(b: *std.Build) void {
    const utils_mod = b.createModule(.{
        .root_source_file = b.path("src/utils/mod.zig"),
    });

    const models_mod = b.createModule(.{
        .root_source_file = b.path("src/models/mod.zig"),
    });
    models_mod.addImport("utils", utils_mod);

    const handlers_mod = b.createModule(.{
        .root_source_file = b.path("src/handlers/mod.zig"),
    });
    handlers_mod.addImport("utils", utils_mod);
    handlers_mod.addImport("models", models_mod);

    const exe = b.addExecutable(.{
        .name = "cargoSpaceAvailable",
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    exe.root_module.addImport("models", models_mod);
    exe.root_module.addImport("utils", utils_mod);
    exe.root_module.addImport("handlers", handlers_mod);
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
