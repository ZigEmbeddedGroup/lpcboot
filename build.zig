const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lpc_patch_elf = b.addExecutable(.{
        .name = "lpc-patchelf",
        .root_source_file = .{ .path = "src/patchelf.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lpc_patch_elf);
}
