const std = @import("std");
const sort = std.sort;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;
const distinct_combinations = @import("combination_helpers.zig").distinct_combinations;

pub fn main() !void {
    const k = 8;
    const cards = [_]u64{ 1, 2, 3, 4, 5 };
    const count = [_]u64{ 3, 2, 2, 2, 1 };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var allCards = ArrayList(u64).init(arena.allocator());
    defer allCards.deinit();

    for (cards) |_, i| {
        var h: u64 = 0;
        while (h < count[i]) : (h += 1) {
            for (cards) |_, c| {
                _ = allCards.append(c * 10 + cards[i]) catch unreachable;
            }
        }
    }
    var arr2 = distinct_combinations(allCards.items, k, 25, arena.allocator());
    defer arr2.deinit();

    // for (arr2.items) |elem| {
    //     std.debug.print("val:{any}\n", .{elem});
    // }
    // std.debug.print("\nlength:{}\n", .{arr2.items.len});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
