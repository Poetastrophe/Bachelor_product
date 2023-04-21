const std = @import("std");
const ArrayList = std.ArrayList;
const hanabi = @import("./hanabi_board_game.zig");
const AI_runner = @import("./ai_simulation_runner.zig");

pub fn main() !void {
    // // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!

    // const RED = "\x1b[31;1m";
    // const writer = std.io.getStdOut().writer();
    // // _ = writer.write("\n") catch unreachable;
    // // _ = writer.writeByte(0) catch unreachable;
    // _ = writer.writeAll(RED) catch unreachable;
    // _ = writer.write("test") catch unreachable;
    // _ = writer.write("\n") catch unreachable;
    var buffer2: [500]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&buffer2);
    const writer_allocator = fba2.allocator();
    var arr = ArrayList(u8).init(writer_allocator);
    var writer = arr.writer();

    var buffer: [AI_runner.BytesPerGame * 3]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var seed = [_]u8{1} ** 32;
    var game = hanabi.Game.init(fba_allocator, 5, seed);

    var simulation_runner = AI_runner.SimulationRunner.init(game, fba_allocator, std.heap.page_allocator);
    var resGame = simulation_runner.play_a_round();

    resGame.to_string(writer);
    std.debug.print("{s}", .{arr.items});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
