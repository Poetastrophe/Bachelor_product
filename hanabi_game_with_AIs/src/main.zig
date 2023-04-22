const std = @import("std");
const ArrayList = std.ArrayList;
const hanabi = @import("./hanabi_board_game.zig");
const AI_runner = @import("./ai_simulation_runner.zig");

pub fn main() !void {
    //std.debug.print("sizeofcard:{}", .{@sizeOf(hanabi.Card)});
    var buffer2: [500]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&buffer2);
    const writer_allocator = fba2.allocator();
    var arr = ArrayList(u8).init(writer_allocator);
    _ = arr;

    var buffer: [AI_runner.BytesPerGame * 3]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var seed = [_]u8{0} ** 32;
    // var game = hanabi.Game.initMiniHanabi(fba_allocator, 5, seed);
    var game = hanabi.Game.init(fba_allocator, 5, seed);

    var simulation_runner = AI_runner.SimulationRunner.init(game, allocator, std.heap.c_allocator);
    defer simulation_runner.deinit();

    for ([_]u8{0} ** 100) |_| {
        //std.debug.print("=======round {}=======", .{i});
        // var timer = try std.time.Timer.start();

        const resGame = simulation_runner.play_a_round(allocator);
        defer resGame.deinit();
        // resGame.to_string(std.io.getStdErr().writer());
        if (resGame.game_is_over) {
            //std.debug.print("Game over", .{});
            break;
        }

        // var end_time = timer.read();
        //std.debug.print("\n\n Initial time and space nanoseconds:{}\n", .{end_time});
        //std.debug.print("\n\n Initial time and space in seconds:{}\n", .{@intToFloat(f128, end_time) / 1E9});
    }
    //std.debug.print("{s}", .{arr.items});
}

test "check for memory leaks minihanabi" {
    //std.debug.print("sizeofcard:{}", .{@sizeOf(hanabi.Card)});
    var buffer2: [500]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&buffer2);
    const writer_allocator = fba2.allocator();
    var arr = ArrayList(u8).init(writer_allocator);
    _ = arr;

    var buffer: [AI_runner.BytesPerGame * 3]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var seed = [_]u8{0} ** 32;
    var game = hanabi.Game.initMiniHanabi(fba_allocator, 5, seed);

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!general_purpose_allocator.deinit());

    const allocator = general_purpose_allocator.allocator();

    var simulation_runner = AI_runner.SimulationRunner.init(game, allocator, allocator);
    defer simulation_runner.deinit();

    for ([_]u8{0} ** 100) |_| {
        //std.debug.print("=======round {}=======", .{i});
        // var timer = try std.time.Timer.start();

        const resGame = simulation_runner.play_a_round(allocator);
        defer resGame.deinit();
        // resGame.to_string(std.io.getStdErr().writer());
        if (resGame.game_is_over) {
            //std.debug.print("Game over", .{});
            break;
        }

        // var end_time = timer.read();
        //std.debug.print("\n\n Initial time and space nanoseconds:{}\n", .{end_time});
        //std.debug.print("\n\n Initial time and space in seconds:{}\n", .{@intToFloat(f128, end_time) / 1E9});
    }
    //std.debug.print("{s}", .{arr.items});
}
