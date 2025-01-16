const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const windows = b.resolveTargetQuery(.{ .os_tag = .windows, .abi = .msvc });
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "pong",
        .root_source_file = b.path("src/main.zig"),
        .target = if (builtin.os.tag == .windows) windows else target,
        .optimize = optimize,
    });

    exe.linkLibC();

    if (builtin.os.tag == .windows) {
        exe.addIncludePath(b.path("thirdparty/glfw/include"));
        exe.addLibraryPath(b.path("thirdparty/glfw/build/src/Release"));

        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("opengl32");
    } else {
        exe.linkSystemLibrary("glfw");
    }

    exe.addIncludePath(b.path("thirdparty/glad/include"));
    exe.addCSourceFile(.{ .file = b.path("thirdparty/glad/src/glad.c") });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    b.step("run", "Run the app").dependOn(&run_cmd.step);
}
