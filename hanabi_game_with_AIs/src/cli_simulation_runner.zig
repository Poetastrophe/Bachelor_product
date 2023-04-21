const std = @import("std");
const hanabi = @import("./hanabi_board_game.zig");

pub fn cli_simulation() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var seed = [_]u8{1} ** 32;
    var game = hanabi.Game.init(arena.allocator(), 5, seed);
    game.simulate(arena.allocator());
}
