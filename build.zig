const std = @import("std");
pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("tmp", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const graph_tests = b.addTest("src/Graph.zig");
    graph_tests.setBuildMode(mode);

    const formula_tests = b.addTest("src/Formula.zig");
    formula_tests.setBuildMode(mode);

    const parser_tests = b.addTest("src/Parser.zig");
    parser_tests.setBuildMode(mode);

    const tokenizer_tests = b.addTest("src/Tokenizer.zig");
    tokenizer_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&formula_tests.step);
    test_step.dependOn(&graph_tests.step);
    test_step.dependOn(&parser_tests.step);
    test_step.dependOn(&tokenizer_tests.step);
}
