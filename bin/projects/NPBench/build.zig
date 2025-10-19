const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseFast;

    // Create module for C++ sources
    const module = b.addModule("NPBench", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // C++ compiler flags
    const cpp_flags = [_][]const u8{
        "-std=c++20",
    };

    // Add all generated C++ files
    module.addCSourceFile(.{
        .file = b.path("generated/NPBench.cpp"),
        .flags = &cpp_flags,
    });
    module.addCSourceFile(.{
        .file = b.path("generated/UNPBench.cpp"),
        .flags = &cpp_flags,
    });

    // Add runtime source
    module.addCSourceFile(.{
        .file = b.path("runtime/runtime.cpp"),
        .flags = &cpp_flags,
    });

    module.addIncludePath(b.path("runtime"));

    // Create executable
    const exe = b.addExecutable(.{
        .name = "NPBench",
        .root_module = module,
    });

    // Link C++ standard library
    exe.linkLibCpp();

    b.installArtifact(exe);
}
