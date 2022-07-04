const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    b.prominent_compile_errors = true;
    b.use_stage1 = false;

    const lib = b.addStaticLibrary("demangle", null);
    lib.setBuildMode(mode);
    lib.addCSourceFile("src/rust-demangle.c", &[_][]const u8{ "-std=c99", "-Os" });
    lib.linkLibC();
    lib.install();

    const exe = b.addExecutable("demangled", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkLibrary(lib);
    exe.linkLibC();
    exe.install();

    b.default_step.dependOn(&exe.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.linkLibrary(lib);
    main_tests.linkLibC();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
