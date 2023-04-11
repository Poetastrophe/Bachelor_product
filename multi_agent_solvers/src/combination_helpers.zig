const std = @import("std");
const sort = std.sort;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const math = std.math;

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
    //     std.debug.print("val:{any}\n", .{elem});
    // }
    std.debug.print("\nlength:{}\n", .{arr2.items.len});
}
test "combinations big time" {
    var timer = try std.time.Timer.start();
    testBigTimeCombinations();
    // var div: u64 = 1E9;
    std.debug.print("\n\nnanoseconds:{}\n", .{timer.read()});
}
