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

    const exe = b.addExecutable("multi_agent_solvers", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.linkLibC();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const combi_test = b.addTest("src/combination_helpers.zig");
    combi_test.setTarget(target);
    combi_test.setBuildMode(mode);

    const agent_test = b.addTest("src/agent.zig");
    agent_test.setTarget(target);
    agent_test.setBuildMode(mode);

    const perm_test = b.addTest("src/PermutationIterator.zig");
    // agent_test.linkLibC();
    perm_test.setTarget(target);
    perm_test.setBuildMode(mode);

    const test_step = b.step("test", "Run fast unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&combi_test.step);
    test_step.dependOn(&agent_test.step);
    test_step.dependOn(&perm_test.step);

    const big_test_step = b.step("big", "Run slow but highly optimized big tests");
    const big_test = b.addTest("src/bigtest.zig");
    big_test.linkLibC();
    big_test.setTarget(target);
    big_test.setBuildMode(mode);
    big_test_step.dependOn(&big_test.step);
}
