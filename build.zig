const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("Bachelor_product", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const graph_tests = b.addTest("src/graph.zig");
    main_tests.setBuildMode(mode);

    const formula_tests = b.addTest("src/Formula.zig");
    main_tests.setBuildMode(mode);



    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&formula_tests.step);
    test_step.dependOn(&graph_tests.step);
}
