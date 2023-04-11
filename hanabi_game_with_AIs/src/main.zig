const std = @import("std");
const hanabi = @import("./hanabi_board_game.zig");

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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var seed = [_]u8{1} ** 32;
    var game = hanabi.Game.init(arena.allocator(), 5, seed);
    game.simulate(arena.allocator());
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
