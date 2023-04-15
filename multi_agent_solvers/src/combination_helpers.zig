const std = @import("std");
const sort = std.sort;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;
const CardEncodingArrSize = 25;

// zig fmt: off
const CardEncoding = [CardEncodingArrSize]u2; //TODO: encoding actually not
                                              // compact, due to the fact that 1
                                              // byte is the smallest natural
                                              // alignment, and so we have 6 bits
                                              // wasted per element. I can use
                                              // array_list_compact from the std.
// zig fmt: on

const CardEncodingSlice = []u2;

fn combinations(comptime NumberOfDistinctElements: u64, taken_into_account: []u64, distinct_pool: []u64, sumarr: []u64, k: u64, cur_id: usize, acc: *ArrayList([NumberOfDistinctElements]u64)) void {
    // _ = taken_into_account;
    // _ = distinct_pool;
    // _ = sum_arr;
    // _ = cur_id;
    // _ = acc;
    // _ = k;

    if (k == 0) {
        var tmp: [NumberOfDistinctElements]u64 = undefined;
        std.mem.copy(u64, &tmp, taken_into_account);
        _ = acc.append(tmp) catch unreachable;
        if (cur_id < taken_into_account.len) {
            taken_into_account[cur_id] = 0;
        }
        return;
    }
    // if (cur_id == taken_into_account.len) {
    // return;
    // }

    const take = math.min(distinct_pool[cur_id], k);

    var i: u64 = 0;
    while (i < take + 1) : (i += 1) {
        taken_into_account[cur_id] = take - i;
        if (sumarr[cur_id + 1] < k - (take - i)) {
            taken_into_account[cur_id] = 0;
            return;
        }
        combinations(NumberOfDistinctElements, taken_into_account, distinct_pool, sumarr, k - (take - i), cur_id + 1, acc);
    }

    taken_into_account[cur_id] = 0;
}

pub fn distinct_combinations_assuming_encoding(elements: CardEncoding, choose_k: u64, allocator: Allocator) ArrayList(CardEncoding) {
    // _ = choose_k;
    // _ = NumberOfDistinctElements;
    // _ = allocator;
    var distinct_pool: CardEncoding = elements;
    // var fba = std.heap.FixedBufferAllocator.init(&distinct_elements_pool_buffer);
    // var distinct_pool = ArrayList(u64).init(fba);
    // std.debug.print("distinct pool:{any}\n", .{distinct_pool});

    var sumarr = [_]u64{0} ** (CardEncodingArrSize + 1);

    var j: usize = 0;

    while (j < CardEncodingArrSize) : (j += 1) {
        const n = CardEncodingArrSize;
        sumarr[n - 1 - j] = sumarr[n - j] + distinct_pool[n - 1 - j];
    }
    // std.debug.print("summarr:{any}\n", .{sumarr});

    var taken_into_account = [_]u2{0} ** CardEncodingArrSize;
    var acc = ArrayList(CardEncoding).init(allocator);
    combinations_assuming_encoding(&taken_into_account, &distinct_pool, &sumarr, choose_k, 0, &acc);
    return acc;
}

pub fn combinations_assuming_encoding(taken_into_account: CardEncodingSlice, distinct_pool: CardEncodingSlice, sumarr: []u64, k: u64, cur_id: usize, acc: *ArrayList(CardEncoding)) void {
    // _ = taken_into_account;
    // _ = distinct_pool;
    // _ = sum_arr;
    // _ = cur_id;
    // _ = acc;
    // _ = k;

    if (k == 0) {
        var tmp: CardEncoding = undefined;
        std.mem.copy(u2, &tmp, taken_into_account);
        _ = acc.append(tmp) catch unreachable;
        if (cur_id < taken_into_account.len) {
            taken_into_account[cur_id] = 0;
        }
        return;
    }
    // if (cur_id == taken_into_account.len) {
    // return;
    // }

    const take = @truncate(u2, math.min(distinct_pool[cur_id], k)); //Since I know the encoding is u2, I can always know that it can fit into u2
    const nonOverflowTake: u32 = take;

    var i: u32 = 0;
    while (i < nonOverflowTake + 1) : (i += 1) {
        taken_into_account[cur_id] = take - @truncate(u2, i);
        if (sumarr[cur_id + 1] < k - (take - i)) {
            taken_into_account[cur_id] = 0;
            return;
        }
        combinations_assuming_encoding(taken_into_account, distinct_pool, sumarr, k - (take - i), cur_id + 1, acc);
    }

    taken_into_account[cur_id] = 0;
}

// Take input a produce a list of combinations, in as simple form as possible from the input list
// Reason: Easier to create a pipeline, as well as splitting up the work between
// multiple threads. If these needs to be converted into cards
pub fn distinct_combinations(elements: []u64, choose_k: u64, comptime NumberOfDistinctElements: u64, allocator: Allocator) ArrayList([NumberOfDistinctElements]u64) {
    // _ = choose_k;
    // _ = NumberOfDistinctElements;
    // _ = allocator;
    const asc_u64 = sort.asc(u64);
    sort.sort(u64, elements, {}, asc_u64);
    // std.debug.print("sorted:{any}\n", .{elements});
    var distinct_pool: [NumberOfDistinctElements]u64 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&distinct_elements_pool_buffer);
    // var distinct_pool = ArrayList(u64).init(fba);
    var counter: u64 = 0;
    var dp_i: usize = 0;
    var i: usize = 1;
    while (i < elements.len) : (i += 1) {
        if (elements[i] == elements[i - 1]) {
            counter += 1;
        } else if (elements[i] != elements[i - 1]) {
            distinct_pool[dp_i] = counter + 1;
            dp_i += 1;
            counter = 0;
        }
    }
    if (elements[i - 1] != elements[i - 2]) {
        distinct_pool[dp_i] = 1;
    }
    // std.debug.print("distinct pool:{any}\n", .{distinct_pool});

    var sumarr = [_]u64{0} ** (NumberOfDistinctElements + 1);

    var j: usize = 0;

    while (j < NumberOfDistinctElements) : (j += 1) {
        const n = NumberOfDistinctElements;
        sumarr[n - 1 - j] = sumarr[n - j] + distinct_pool[n - 1 - j];
    }
    // std.debug.print("summarr:{any}\n", .{sumarr});

    var taken_into_account = [_]u64{0} ** NumberOfDistinctElements;
    var acc = ArrayList([NumberOfDistinctElements]u64).init(allocator);
    combinations(NumberOfDistinctElements, &taken_into_account, &distinct_pool, &sumarr, choose_k, 0, &acc);
    return acc;
}

test "combinations" {
    var elems = [_]u64{ 5, 1, 1, 2, 3, 5 };
    var arr = distinct_combinations(&elems, 3, 4, std.testing.allocator);
    defer arr.deinit();
    for (arr.items) |a| {
        std.debug.print("\nhmm:{any}\n", .{a});
    }
}
fn testBigTimeCombinations() void {
    const k = 4;
    const cards = [_]u64{ 1, 2, 3, 4, 5 };
    const count = [_]u64{ 3, 2, 2, 2, 1 };
    var allCards = ArrayList(u64).init(std.testing.allocator);
    defer allCards.deinit();

    for (cards) |_, i| {
        var h: u64 = 0;
        while (h < count[i]) : (h += 1) {
            for (cards) |_, c| {
                _ = allCards.append(c * 10 + cards[i]) catch unreachable;
            }
        }
    }
    var arr2 = distinct_combinations(allCards.items, k, 25, std.testing.allocator);
    defer arr2.deinit();

    // for (arr2.items) |elem| {
    // std.debug.print("val:{any}\n", .{elem});
    // }
    std.debug.print("\nlength:{}\n", .{arr2.items.len});
}
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

pub const CardSet = struct {
    const Self = @This();
    card_encoding: CardEncoding,

    pub fn setDifference(self: Self, other: Self) Self { //Could be optimized by vector operations
        var i: usize = 0;
        var res: CardSet = self;
        while (i < self.card_encoding.len) : (i += 1) {
            res.card_encoding[i] -= other.card_encoding[i];
        }
        return res;
    }
    pub fn getWholeDeckSet() Self {
        return Self{ .card_encoding = [_]u2{ 3, 2, 2, 2, 1 } ** 5 };
    }

    pub fn emptySet() Self {
        return Self{ .card_encoding = [_]u2{ 0, 0, 0, 0, 0 } ** 5 };
    }

    pub fn get(self: Self, index: u5) u2 {
        return self.card_encoding[index];
    }
    pub fn set(self: *Self, index: u5, val: u2) void {
        self.card_encoding[index] = val;
    }
};

test "CardSet setDifference" {
    var allcards = CardSet.getWholeDeckSet();
    std.debug.print("\nallcards:\n{any}\n", .{allcards});
    var someCards = CardSet{ .card_encoding = [_]u2{ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } };
    var remaining = allcards.setDifference(someCards);

    std.debug.print("\nrem:\n{any}\n", .{remaining});

    std.debug.print("\n\nsizeofu2:{}\n", .{@sizeOf(@TypeOf(someCards.card_encoding))});
    std.debug.print("\n\nsizeofu32:{}\n", .{@sizeOf([25]u8)});
}

test "CardEncoding combinations " {
    var allcards = CardSet.getWholeDeckSet();
    var timer = try std.time.Timer.start();
    var res = distinct_combinations_assuming_encoding(allcards.card_encoding, 6, std.testing.allocator);
    defer res.deinit();
    // try std.testing.expect(res.items.len == 18480);
    std.debug.print("\n\nnanosecondsmorecompact:{}\n", .{timer.read()});

    // std.debug.print("\nrem:\n{any}\n", .{remaining});
}

test "combinations big time" {
    var timer = try std.time.Timer.start();
    testBigTimeCombinations();
    // var div: u64 = 1E9;
    std.debug.print("\n\nnanoseconds:{}\n", .{timer.read()});
}
