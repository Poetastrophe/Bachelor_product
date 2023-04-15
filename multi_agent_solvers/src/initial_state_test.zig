const std = @import("std");
const sort = std.sort;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;
const distinct_combinations = @import("combination_helpers.zig").distinct_combinations;

pub fn initial_state_test() void {
    var timer = try std.time.Timer.start();

    const k = 4;
    const cards = [_]u64{ 1, 2, 3, 4, 5 };
    const count = [_]u64{ 3, 2, 2, 2, 1 };
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
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

    std.debug.print("\n\nnanoseconds:{}\n", .{timer.read()});
}

const CardSet = struct {
    const Self = @This();
    card_encoding: [25]u2,

    pub fn subtract(self: Self, other: Self) Self { //Could be optimized by vector operations
        var i: usize = 0;
        // var res: CardSet = self;
        while (i < self.card_encoding.len) : (i += 1) {
            self[i] -= other[i];
        }
        return self;
    }
    pub fn getWholeDeckSet() Self {
        return Self{ .card_encoding = [_]u2{ 3, 2, 2, 2, 1 } ** 5 };
    }
};

test "CardSet subtract" {
    var allcards = CardSet.getWholeDeckSet();
    std.debug.print("allcards:{any}", .{allcards});
}
