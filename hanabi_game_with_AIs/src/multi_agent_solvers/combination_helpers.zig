const std = @import("std");
const sort = std.sort;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;
const Hanabi_game = @import("./../hanabi_board_game.zig");
const Card = Hanabi_game.Card;
const CardWithHints = Hanabi_game.CardWithHints;
const CardEncodingArrSize = 25;

// zig fmt: off
const CardEncoding = [CardEncodingArrSize]u2; //TODO 1: encoding actually not
                                              // compact, due to the fact that 1
                                              // byte is the smallest natural
                                              // alignment, and so we have 6 bits
                                              // wasted per element. I can use
                                              // array_list_compact from the std.
// zig fmt: on

const CardEncodingSlice = []u2;

fn combinations(comptime NumberOfDistinctElements: u64, taken_into_account: []u64, distinct_pool: []u64, sumarr: []u64, k: u64, cur_id: usize, acc: *ArrayList([NumberOfDistinctElements]u64)) void {
    if (k == 0) {
        var tmp: [NumberOfDistinctElements]u64 = undefined;
        std.mem.copy(u64, &tmp, taken_into_account);
        _ = acc.append(tmp) catch unreachable;
        if (cur_id < taken_into_account.len) {
            taken_into_account[cur_id] = 0;
        }
        return;
    }

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
    var distinct_pool: CardEncoding = elements;

    var sumarr = [_]u64{0} ** (CardEncodingArrSize + 1);

    var j: usize = 0;

    while (j < CardEncodingArrSize) : (j += 1) {
        const n = CardEncodingArrSize;
        sumarr[n - 1 - j] = sumarr[n - j] + distinct_pool[n - 1 - j];
    }

    var taken_into_account = [_]u2{0} ** CardEncodingArrSize;
    var acc = ArrayList(CardEncoding).init(allocator);
    combinations_assuming_encoding(&taken_into_account, &distinct_pool, &sumarr, choose_k, 0, &acc);
    return acc;
}

pub fn combinations_assuming_encoding(taken_into_account: CardEncodingSlice, distinct_pool: CardEncodingSlice, sumarr: []u64, k: u64, cur_id: usize, acc: *ArrayList(CardEncoding)) void {
    if (k == 0) {
        var tmp: CardEncoding = undefined;
        std.mem.copy(u2, &tmp, taken_into_account);
        _ = acc.append(tmp) catch unreachable;
        if (cur_id < taken_into_account.len) {
            taken_into_account[cur_id] = 0;
        }
        return;
    }

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
    const asc_u64 = sort.asc(u64);
    sort.sort(u64, elements, {}, asc_u64);

    var distinct_pool: [NumberOfDistinctElements]u64 = undefined;

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

    var sumarr = [_]u64{0} ** (NumberOfDistinctElements + 1);

    var j: usize = 0;

    while (j < NumberOfDistinctElements) : (j += 1) {
        const n = NumberOfDistinctElements;
        sumarr[n - 1 - j] = sumarr[n - j] + distinct_pool[n - 1 - j];
    }

    var taken_into_account = [_]u64{0} ** NumberOfDistinctElements;
    var acc = ArrayList([NumberOfDistinctElements]u64).init(allocator);
    combinations(NumberOfDistinctElements, &taken_into_account, &distinct_pool, &sumarr, choose_k, 0, &acc);
    return acc;
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

    //std.debug.print("\nlength:{}\n", .{arr2.items.len});
}
pub fn initial_state_test() void {
    // var timer = try std.time.Timer.start();

    const k = 4;
    const cards = [_]u64{ 1, 2, 3, 4, 5 };
    const count = [_]u64{ 3, 2, 2, 2, 1 };

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

    //std.debug.print("\n\nnanoseconds:{}\n", .{timer.read()});
}

pub const CardSet = struct {
    const COLOR_N = 5;
    const VALUE_N = 5;
    const Self = @This();
    card_encoding: CardEncoding,

    pub fn add(self: Self, other: Self) Self {
        var res: CardSet = self;
        for (other.card_encoding) |elem, i| {
            res.card_encoding[i] += elem;
        }
        return res;
    }
    pub fn setDifference(self: Self, other: Self) Self { //Could be optimized by vector operations
        var i: usize = 0;
        var res: CardSet = self;
        while (i < self.card_encoding.len) : (i += 1) {
            if (res.card_encoding[i] >= other.card_encoding[i]) {
                res.card_encoding[i] -= other.card_encoding[i];
            } else {
                res.card_encoding[i] = 0;
            }
        }
        return res;
    }

    pub const Error = error{
        OtherValueIsNotSubset,
    };

    pub fn setDifferenceAssertOtherIsSubset(self: Self, other: Self) Error.OtherValueIsNotSubset!Self {
        var i: usize = 0;
        while (i < self.card_encoding.len) : (i += 1) {
            if (self.card_encoding[i] < other.card_encoding[i]) {
                return Error.OtherValueIsNotSubset;
            }
        }
        return self.setDifference(other);
    }

    pub fn getSize(self: Self) u32 {
        var acc: u32 = 0;
        for (self.card_encoding) |card| {
            acc += card;
        }
        return acc;
    }

    pub fn getWholeDeckSet() Self {
        return Self{ .card_encoding = [_]u2{ 3, 2, 2, 2, 1 } ** COLOR_N };
    }

    pub fn getWholeDeckSetMiniHanabi() Self {
        return Self{ .card_encoding = [_]u2{ 3, 2, 1, 0, 0 } ** COLOR_N ++ [_]u2{0} ** 5 };
    }

    pub fn emptySet() Self {
        return Self{ .card_encoding = [_]u2{ 0, 0, 0, 0, 0 } ** COLOR_N };
    }

    pub fn toCardList(self: Self, allocator: Allocator) ArrayList(Card) {
        var res = ArrayList(Card).init(allocator);
        for (self.card_encoding) |card_count, card_id| {
            var i: u64 = 0;
            while (i < card_count) : (i += 1) {
                res.append(idPositionToCard(card_id)) catch unreachable;
            }
        }
        return res;
    }
    pub fn idPositionToCard(index: usize) Card {
        const colorindex = index / COLOR_N;
        const valueindex = index % VALUE_N;
        const color = @intToEnum(Hanabi_game.Color, colorindex);
        const value = @intToEnum(Hanabi_game.Value, valueindex);
        return Card{ .color = color, .value = value };
    }
    pub fn cardToIdPosition(card: Card) u5 {
        var color: u5 = undefined;
        switch (card.color) {
            .red => color = 0,
            .blue => color = 1,
            .green => color = 2,
            .yellow => color = 3,
            .white => color = 4,
            .unknown => unreachable,
        }
        const value: u5 = switch (card.value) {
            .one => 0,
            .two => 1,
            .three => 2,
            .four => 3,
            .five => 4,
            .unknown => unreachable,
        };
        return color * COLOR_N + value;
    }

    pub fn createUsingSliceOfCards(cards: []Card) Self {
        var res = CardSet.emptySet();
        for (cards) |c| {
            res = res.insertCard(c);
        }
        return res;
    }

    pub fn createUsingEncoding(card: CardEncoding) Self {
        return CardSet{ .card_encoding = card };
    }
    pub fn insertCard(self: Self, card: Card) Self {
        var res = self;
        res.card_encoding[cardToIdPosition(card)] += 1;
        return res;
    }

    pub fn get(self: Self, index: u5) u2 {
        return self.card_encoding[index];
    }

    pub fn set(self: Self, index: u5, val: u2) Self {
        var res = self;
        res.card_encoding[index] = val;
        return res;
    }
};

test "CardSet setDifference" {
    var allcards = CardSet.getWholeDeckSet();
    //std.debug.print("\nallcards:\n{any}\n", .{allcards});
    var someCards = CardSet{ .card_encoding = [_]u2{ 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } };
    var remaining = allcards.setDifference(someCards);
    _ = remaining;

    //std.debug.print("\nrem:\n{any}\n", .{remaining});

    //std.debug.print("\n\nsizeofu2:{}\n", .{@sizeOf(@TypeOf(someCards.card_encoding))});
    //std.debug.print("\n\nsizeofu32:{}\n", .{@sizeOf([25]u8)});
}

test "CardEncoding combinations " {
    var allcards = CardSet.getWholeDeckSet();
    var timer = try std.time.Timer.start();
    _ = timer;
    var res = distinct_combinations_assuming_encoding(allcards.card_encoding, 6, std.testing.allocator);
    defer res.deinit();

    //std.debug.print("\n\nnanosecondsmorecompact:{}\n", .{timer.read()});
}

test "combinations big time" {
    // var timer = try std.time.Timer.start();
    testBigTimeCombinations();

    //std.debug.print("\n\nnanoseconds:{}\n", .{timer.read()});
}
