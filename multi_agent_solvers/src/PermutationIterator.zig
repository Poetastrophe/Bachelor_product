const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;
const print = std.debug.print;

// self.arr will always be the internal representation of the current permutation and
// it will not return a copy of the answer, but only a slice to self.arr

const HeapsAlgorithm = struct {
    const Self = @This();
    stack_state: ArrayList(u8),
    arr: ArrayList(u8),
    is_first_iter: bool = true,
    pub fn init(allocator: Allocator, N: u64) Self {
        var stack_state = ArrayList(u8).initCapacity(allocator, N) catch unreachable;
        var i: usize = 0;
        while (i < N) : (i += 1) {
            stack_state.append(0) catch unreachable;
        }
        var arr = ArrayList(u8).initCapacity(allocator, N) catch unreachable;
        i = 0;
        while (i < N) : (i += 1) {
            arr.append(@truncate(u8, i)) catch unreachable;
        }

        return Self{ .stack_state = stack_state, .arr = arr };
    }
    pub fn deinit(self: *Self) void {
        self.stack_state.deinit();
        self.arr.deinit();
    }

    pub fn next(self: *Self) ?[]u8 {
        if (self.is_first_iter) {
            self.is_first_iter = false;
            return self.arr.items;
        }
        const N = self.arr.items.len;
        var i: u64 = 1;
        while (i < N) : (i += 1) {
            if (self.stack_state.items[i] < i) { //
                if (i % 2 == 0) {
                    self.swap(0, i);
                } else {
                    self.swap(self.stack_state.items[i], i);
                }
                self.stack_state.items[i] += 1;
                // std.mem.copy(u8, res[0..N], self.arr[0..N]);
                return self.arr.items;
            } else {
                self.stack_state.items[i] = 0;
            }
        }
        return null;
    }

    fn swap(self: *Self, i: u64, j: u64) void {
        const tmp = self.arr.items[i];
        self.arr.items[i] = self.arr.items[j];
        self.arr.items[j] = tmp;
    }
};

//pub fn HeapsAlgorithm(comptime N: u64) type {
//    return struct {
//        const Self = @This();
//        stack_state: [N]u8 = [_]u8{0} ** N,

//        is_first_iter: bool = true,

//        arr: [N]u8 = iota: {
//            var arrtmp = [_]u8{0} ** N;
//            var i = 0;
//            while (i < N) : (i += 1) {
//                arrtmp[i] = i;
//            }
//            break :iota arrtmp;
//        },

//        pub fn next(self: *Self) ?[N]u8 {
//            var res: [N]u8 = undefined;
//            if (self.is_first_iter) {
//                self.is_first_iter = false;
//                std.mem.copy(u8, res[0..N], self.arr[0..N]);
//                return res;
//            }
//            var i: u64 = 1;
//            while (i < N) : (i += 1) {
//                if (self.stack_state[i] < i) { //
//                    if (i % 2 == 0) {
//                        self.swap(0, i);
//                    } else {
//                        self.swap(self.stack_state[i], i);
//                    }
//                    self.stack_state[i] += 1;
//                    std.mem.copy(u8, res[0..N], self.arr[0..N]);
//                    return res;
//                } else {
//                    self.stack_state[i] = 0;
//                }
//            }
//            return null;
//        }

//        inline fn swap(self: *Self, i: u64, j: u64) void {
//            const tmp = self.arr[i];
//            self.arr[i] = self.arr[j];
//            self.arr[j] = tmp;
//        }
//    };
//}

pub fn less_than_size_N(comptime N: u64) type {
    return struct {
        fn lessThanArr(_: void, lhs: [N]u8, rhs: [N]u8) bool {
            var i: u64 = 0;
            while (i < N) : (i += 1) {
                if (lhs[i] < rhs[i]) {
                    return true;
                } else if (lhs[i] > rhs[i]) {
                    return false;
                }
            }
            return false;
        }
    };
}

//// Testing for uniqueness is done as follows:
//// 0. Does the number of permutations match the theoretical number of permutations
//// 1. Is all the elems different?
//// 2. Is all the elems a correct permutation?
fn correctness_test(comptime NUMBER: u64) !void {
    // 0. Does the number of permutations match the theoretical number of permutations
    comptime var PROD: u64 = 1;
    comptime var K: u64 = 0;
    inline while (K < NUMBER) : (K += 1) {
        PROD *= (K + 1);
    }
    var iterator01 = HeapsAlgorithm.init(std.testing.allocator, NUMBER);
    defer iterator01.deinit();
    var list: [PROD][K]u8 = undefined;
    var unique_i: u64 = 0;
    while (iterator01.next()) |tmp| : (unique_i += 1) {
        std.mem.copy(u8, list[unique_i][0..NUMBER], tmp[0..tmp.len]);
    }
    try expectEqual(PROD, unique_i);

    // 1. Is all the elems different?
    std.sort.sort([NUMBER]u8, list[0..list.len], {}, less_than_size_N(NUMBER).lessThanArr);
    var i: u64 = 0;
    //Check pairs
    while (i < list.len - 1) : (i += 1) {
        try expect(!std.mem.eql(u8, list[i][0..NUMBER], list[i + 1][0..NUMBER]));
    }
    const vals = iota: {
        var arrtmp = [_]u8{0} ** NUMBER;
        comptime var j = 0;
        inline while (j < NUMBER) : (j += 1) {
            arrtmp[j] = j;
        }
        break :iota arrtmp;
    };

    // 2. Is all the elems a correct permutation?
    for (list) |elem| {
        outer: for (vals) |val| {
            for (elem) |indice| {
                if (val == indice) {
                    continue :outer;
                }
            }
            unreachable; // Test shouldn't reach here
        }
    }
}

//test "speedtest" {
//    var unique_i: u64 = 0;
//    var iterator01 = HeapsAlgorithm(7){};
//    // const start = std.time.nanoTimestamp();
//    while (iterator01.next()) |elem| : (unique_i += 1) {
//        _ = elem;
//        // print("\n{any}\n",.{elem});
//    }
//    // const end = std.time.nanoTimestamp();
//    // const seconds_with_two_significant_digits = @intToFloat(f128, try std.math.divFloor(i128, (end - start), 1000)) / 1000000.0;
//    // print("\ntime_passed = {}\n", .{seconds_with_two_significant_digits});
//}

//test "speedtestvsbenchmark" {
//    const size = 7;
//    {
//        var unique_i: u64 = 0;
//        var iterator01 = HeapsAlgorithm(size){};
//        // const start = std.time.nanoTimestamp();
//        while (iterator01.next()) |elem| : (unique_i += 1) {
//            _ = elem;
//            // print("\n{any}\n", .{elem});
//        }
//        // const end = std.time.nanoTimestamp();
//        // const seconds_with_two_significant_digits = @intToFloat(f128, try std.math.divFloor(i128, (end - start), 1000)) / 1000000.0;
//        // print("\ntime_passed for heapsalgorithm = {}\n", .{seconds_with_two_significant_digits});
//    }
//    {
//        var unique_i: u64 = 0;
//        var iterator01 = NaiveBenchmark(size){};
//        // const start = std.time.nanoTimestamp();
//        while (iterator01.next()) |elem| : (unique_i += 1) {
//            _ = elem;
//            // print("\n{any}\n", .{elem});
//        }
//        // const end = std.time.nanoTimestamp();
//        // const seconds_with_two_significant_digits = @intToFloat(f128, try std.math.divFloor(i128, (end - start), 1000)) / 1000000.0;
//        // print("\ntime_passed for naivebenchmark = {}\n", .{seconds_with_two_significant_digits});
//    }
//}

//pub fn NaiveBenchmark(comptime N: u8) type {
//    return struct {
//        const Self = @This();
//        arr: [N]u8 = [_]u8{0} ** N,

//        fn has_unique_indices(self: *const Self) bool {
//            for (self.arr) |_, i| {
//                var count: u64 = 0;
//                for (self.arr) |elem| {
//                    if (elem == i) {
//                        count += 1;
//                    }
//                }
//                if (count != 1) {
//                    return false;
//                }
//            }
//            return true;
//        }

//        //TODO rework this
//        pub fn addOne(self: *Self) void {
//            if (std.mem.eql(u8, self.arr[0..N], ([_]u8{N - 1} ** N)[0..N])) {
//                return;
//            }
//            var rev_i = self.arr.len - 1;
//            while (true) {
//                self.arr[rev_i] = (self.arr[rev_i] + 1) % N;
//                if (self.arr[rev_i] == 0 and rev_i != 0) {
//                    rev_i -= 1;
//                } else {
//                    return;
//                }
//            }
//        }

//        pub fn next(self: *Self) ?[N]u8 {
//            self.addOne();
//            while (!self.has_unique_indices()) {
//                if (std.mem.eql(u8, self.arr[0..N], ([_]u8{N - 1} ** N)[0..N])) {
//                    return null;
//                }
//                self.addOne();
//            }
//            return self.arr;
//        }
//    };
//}

test "test correctness for small n" {
    try correctness_test(2);
    try correctness_test(3);
    try correctness_test(4);
    try correctness_test(5);
    try correctness_test(6);
    try correctness_test(7);
}
