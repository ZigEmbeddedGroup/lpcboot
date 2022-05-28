const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lpc_patch_elf = b.addExecutable("lpc-patchelf", "src/patchelf.zig");
    lpc_patch_elf.setBuildMode(mode);
    lpc_patch_elf.setTarget(target);
    lpc_patch_elf.install();

    const lib = b.addStaticLibrary("lpcboot", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
