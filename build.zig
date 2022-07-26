const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lpc_patch_elf = b.addExecutable("lpc-patchelf", "src/patchelf.zig");
    lpc_patch_elf.setBuildMode(mode);
    lpc_patch_elf.setTarget(target);
    lpc_patch_elf.install();
}
