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

    const exe = b.addExecutable("hanabi_game_with_AIs", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.linkLibC();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // const log_step = b.step("log", "Produce timer logs for each method");
    // log_step.makeFn

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const hanabi_tests = b.addTest("src/hanabi_board_game.zig");
    hanabi_tests.setTarget(target);
    hanabi_tests.setBuildMode(mode);

    const combi_test = b.addTest("src/multi_agent_solvers/combination_helpers.zig");
    combi_test.setTarget(target);
    combi_test.setBuildMode(mode);

    const agent_test = b.addTest("src/multi_agent_solvers/agent.zig");
    agent_test.setTarget(target);
    agent_test.setBuildMode(mode);

    const perm_test = b.addTest("src/multi_agent_solvers/PermutationIterator.zig");
    // agent_test.linkLibC();
    perm_test.setTarget(target);
    perm_test.setBuildMode(mode);

    const test_step = b.step("test", "Run fast unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&hanabi_tests.step);
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&combi_test.step);
    test_step.dependOn(&agent_test.step);
    test_step.dependOn(&perm_test.step);

    const big_test = b.addTest("src/bigtest.zig");

    big_test.linkLibC();
    big_test.setTarget(target);
    big_test.setBuildMode(mode);

    // const initial_state_test = b.addTest("src/tests/initial_state_test.zig");
    // initial_state_test.setTarget(target);
    // initial_state_test.setBuildMode(mode);

    const big_test_step = b.step("big", "Run slow but highly optimized big tests");
    big_test_step.dependOn(&big_test.step);
    // big_test_step.dependOn(&initial_state_test.step);
}
