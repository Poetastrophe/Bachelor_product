const Formula = @import("./Formula.zig");
const Tokenizer = @import("./Tokenizer.zig");
const Parser = @import("./Parser.zig").Parser;
const AdequateSetFormula = Formula.AdequateSetFormula;
const AdequateFormulaSimpleFactory = Formula.AdequateFormulaSimpleFactory;
const AdequateFormulaGenerator = Formula.AdequateFormulaGenerator;
const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;
const sort = std.sort;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// const StateList = struct {
// graph: ArrayList(Arraylist(State));
// };

const Graph = struct {
    const Self = @This();

    graph: ArrayList(State),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .graph = ArrayList(State).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.graph.items) |*elem| {
            elem.deinit();
        }
        self.graph.deinit();
    }

    const State = struct {
        //TODO: List could eventually be sorted, so it is trivial to look up
        //specific state. Other options like hashmap or binary search tree is also
        //an option, better not play it too fancy

        //TODO: List can be sorted eventually
        //Only true atoms goes here
        //Id is always identical to position in array
        atoms: ArrayList(u64),
        outgoing_edges: ArrayList(usize),
        incoming_edges: ArrayList(usize),
        //Q: Does the graph representation need to know incoming edges?
        // Incorrect behaviour inbound if state_id is identical to some other state_id
        pub fn init(allocator: Allocator) State {
            return State{
                .atoms = ArrayList(u64).init(allocator),
                .outgoing_edges = ArrayList(usize).init(allocator),
                .incoming_edges = ArrayList(usize).init(allocator),
            };
        }
        pub fn deinit(state: *State) void {
            state.atoms.deinit();
            state.outgoing_edges.deinit();
            state.incoming_edges.deinit();
        }
    };

    // Public interface
    // initialize_graph( list_of_state_identifiers, list_of_list_of_atoms, list_of_pairs_of_identifiers  )
    pub fn initialize_preconfigured_graph(list_of_list_of_atoms: []ArrayList(u64), list_of_from_to_connections: [][2]u64, allocator: Allocator) Self {
        var res = Self.init(allocator);
        var i: usize = 0;
        while (i < list_of_list_of_atoms.len) : (i += 1) {
            _ = res.add_state();
            var list = list_of_list_of_atoms[i].items;
            res.add_atoms_to_state(i, list);
        }

        for (list_of_from_to_connections) |from_to| {
            //TODO: just make state_ids and arrays contigouos. No need to complicate it.
            res.add_connection(from_to[0], from_to[1]);
        }
        return res;
    }
    // add_state(identifier, list_of_identiefiers_outgoing, list_of_identifiers_going_in)

    // add_state(identifier)
    // Cannot fail other than memory error
    // Cannot fail if identifier is already present
    pub fn add_state(self: *Self) usize {
        _ = self.graph.append(State.init(self.allocator)) catch unreachable;
        return self.graph.items.len - 1;
    }

    pub fn get_state(self: *Self, id: u64) State {
        return self.graph.items[id];
    }

    pub fn add_atoms_to_state(self: *Self, state_index: usize, atoms: []u64) void {
        self.graph.items[state_index].atoms.appendSlice(atoms) catch unreachable;
    }

    pub fn add_connection(self: *Self, from: usize, to: usize) void {
        self.graph.items[from].outgoing_edges.append(to) catch unreachable;
        self.graph.items[to].incoming_edges.append(from) catch unreachable;
    }

    // add_atoms_to_state(state, list_of_atoms)
    // Can fail if some identifier is wrong
    // And memory
    // Cannot fail if booleans already exist in state_id, idempotence

    //remove_state // Might be useful when extending with epistemic logic? So that I can make a copy of a graph and then do a new thing
    // If I understood correctly a graph is never removed so I could just us e memory pool

    // add_connection(from:identifier, to: identifier)
    // Can fail if lack memory, will not fail if the connection is already there.

    pub fn SAT(self: *Self, formula: *AdequateSetFormula, calculation_allocator: Allocator, result_allocator: Allocator) ArrayList(u64) {
        var tmp_states = ArrayList(u64).init(calculation_allocator);
        var i: u64 = 0;
        while (i < self.graph.items.len) : (i += 1) {
            tmp_states.append(i) catch unreachable;
        }
        // sort.sort(u64, tmp_states.items, {}, comptime sort.asc(u64));

        var initial_set = Set.initWithSortedList(tmp_states.items, calculation_allocator);

        tmp_states.deinit();

        var tmp_result = self.SATHelper(formula, initial_set, calculation_allocator);
        defer tmp_result.deinit();
        var result_arr = ArrayList(u64).init(result_allocator);
        result_arr.appendSlice(tmp_result.arr.items) catch unreachable;
        return result_arr;
    }

    pub fn getStateSet(self: *Self, allocator: Allocator) Set {
        var set = Set.initEmptySet(allocator);
        var i: usize = 0;
        while (i < self.graph.items.len) : (i += 1) {
            set.arr.append(i) catch unreachable;
        }
        return set;
    }
    pub fn SATHelper(self: *Self, formula: *AdequateSetFormula, set: Set, calculation_allocator: Allocator) Set {
        switch (formula.*) {
            .EX => {
                std.debug.print("\neval:EX with set:{any}", .{set.arr.items});
                var X = self.SATHelper(formula.EX.args[0], set, calculation_allocator);
                defer X.deinit();
                var tmp = Set.initEmptySet(calculation_allocator);
                // std.debug.print("\n set: {any}\n", .{set.arr.items});
                // std.debug.print("\n X args[0]\n", .{});
                // formula.EX.args[0].printPreOrderTree();
                // std.debug.print("\n ARR: {any}\n", .{X.arr.items});
                for (X.arr.items) |x| {
                    var acc = tmp;
                    defer acc.deinit();
                    var arrayList = ArrayList(u64).init(calculation_allocator);
                    defer arrayList.deinit();

                    for (self.get_state(x).incoming_edges.items) |state| {
                        arrayList.append(state) catch unreachable;
                    }
                    sort.sort(u64, arrayList.items, {}, comptime sort.asc(u64));
                    var setfromlist = Set.initWithSortedList(arrayList.items, calculation_allocator);
                    defer setfromlist.deinit();
                    tmp = acc.setUnion(setfromlist, calculation_allocator);
                }
                std.debug.print("\nend of eval:EX with set:{any}", .{tmp.arr.items});
                return tmp;
            },
            .AND => {
                std.debug.print("\neval:AND with set:{any}", .{set.arr.items});
                var f1 = formula.AND.args[0];
                var f2 = formula.AND.args[1];
                var s1 = self.SATHelper(f1, set, calculation_allocator);
                defer s1.deinit();
                var result = self.SATHelper(f2, s1, calculation_allocator);
                // defer s2.deinit();
                // var result = Set.setIntersection(s1, s2, calculation_allocator);

                std.debug.print("\nend of eval:AND with set:{any}", .{result.arr.items});
                return result;
            },

            .NOT => {
                std.debug.print("\neval:NOT with set:{any}", .{set.arr.items});
                var f1 = formula.NOT.args[0];
                var s1 = self.SATHelper(f1, set, calculation_allocator);
                defer s1.deinit();
                // var allSet = self.getStateSet(calculation_allocator);
                // defer allSet.deinit();
                var result = Set.setDifference(set, s1, calculation_allocator);
                std.debug.print("\nend of eval:NOT with set:{any}", .{result.arr.items});
                return result;
            },
            .ATOM => {
                std.debug.print("\neval:ATOM with set:{any}", .{set.arr.items});
                var acc = ArrayList(u64).init(calculation_allocator);
                defer acc.deinit();
                for (set.arr.items) |state_id| {
                    var state = self.get_state(state_id);
                    for (state.atoms.items) |atom| {
                        if (atom == formula.ATOM) {
                            acc.append(state_id) catch unreachable;
                            break;
                        }
                    }
                }
                // sort.sort(u64, acc.items, {}, comptime sort.asc(u64));
                var pointer = Set.initWithSortedList(acc.items, calculation_allocator);
                std.debug.print("\nend of eval:ATOM with set:{any}", .{pointer.arr.items});
                return pointer;
            },
            .FALSE => {
                std.debug.print("\neval:FALSE with set:{any}", .{set.arr.items});
                var pointer = Set.initEmptySet(calculation_allocator);
                std.debug.print("\nend of eval:FALSE with set:{any}", .{pointer.arr.items});
                return pointer;
            },
        }
    }
    // pub fn createState(
    // pub fn getNeighbourIterator

    // SAT, could be a function containing
    //SAT(f,current_set)
    // returns a set of States

    // Idea

    //EX function: EX f

    //acc = empty_set
    // X=SAT(f,S)
    // for x in X{
    //    acc = union_sets(acc, x.incoming_edges)
    // }
    // return acc

    //False function: _|_
    // return empty set

    //Not function: not f
    //return Setdifference(S,SAT(f,S))

    //AND function: f1 and f2
    //S1 = SAT(f1,S)
    //return SAT(f2,S1)

    //atomic function: p
    //return L(S,p)

    pub fn print(self: *Self) void {
        var i: u64 = 0;

        for (self.graph.items) |state| {
            std.debug.print("State\t{}\t{any}\t{any}\n", .{ i, state.atoms.items, state.outgoing_edges.items });
            i += 1;
        }
    }
};

const Set = struct {
    const Self = @This();
    arr: ArrayList(u64),

    pub fn initEmptySet(allocator: Allocator) Self {
        return Self{
            .arr = ArrayList(u64).init(allocator),
        };
    }

    //Assumes sorted list and no duplicates
    // Can logically fail if list is not sorted
    // Can logically fail if list contains duplicates
    pub fn initWithSortedList(list: []u64, allocator: Allocator) Self {
        var result = Self.initEmptySet(allocator);
        _ = result.arr.appendSlice(list) catch unreachable;
        return result;
    }

    pub fn deinit(self: *Self) void {
        self.arr.deinit();
    }

    pub fn setUnion(self: Self, other: Self, allocator: Allocator) Self {
        var i_1: usize = 0;
        var i_2: usize = 0;
        var result = Self.initEmptySet(allocator);

        while (i_1 < self.arr.items.len and i_2 < other.arr.items.len) {
            if (self.arr.items[i_1] < other.arr.items[i_2]) {
                result.arr.append(self.arr.items[i_1]) catch unreachable;
                i_1 += 1;
            } else if (self.arr.items[i_1] == other.arr.items[i_2]) {
                result.arr.append(self.arr.items[i_1]) catch unreachable;
                i_1 += 1;
                i_2 += 1;
            } else {
                result.arr.append(other.arr.items[i_2]) catch unreachable;
                i_2 += 1;
            }
        }
        result.arr.appendSlice(self.arr.items[i_1..]) catch unreachable;
        result.arr.appendSlice(other.arr.items[i_2..]) catch unreachable;

        return result;
    }

    pub fn setDifference(self: Self, other: Self, allocator: Allocator) Self {
        var i_1: usize = 0;
        var i_2: usize = 0;
        var result = Self.initEmptySet(allocator);

        while (i_1 < self.arr.items.len and i_2 < other.arr.items.len) {
            if (self.arr.items[i_1] < other.arr.items[i_2]) {
                result.arr.append(self.arr.items[i_1]) catch unreachable;
                i_1 += 1;
            } else if (self.arr.items[i_1] == other.arr.items[i_2]) {
                i_1 += 1;
                i_2 += 1;
            } else {
                i_2 += 1;
            }
        }
        result.arr.appendSlice(self.arr.items[i_1..]) catch unreachable;

        return result;
    }

    pub fn setIntersection(self: Self, other: Self, allocator: Allocator) Self {
        var i_1: usize = 0;
        var i_2: usize = 0;
        var result = Self.initEmptySet(allocator);

        while (i_1 < self.arr.items.len and i_2 < other.arr.items.len) {
            if (self.arr.items[i_1] < other.arr.items[i_2]) {
                i_1 += 1;
            } else if (self.arr.items[i_1] == other.arr.items[i_2]) {
                result.arr.append(self.arr.items[i_1]) catch unreachable;
                i_1 += 1;
                i_2 += 1;
            } else {
                i_2 += 1;
            }
        }
        result.arr.appendSlice(self.arr.items[i_1..]) catch unreachable;

        return result;
    }
};

test "Set union basic" {
    var arr = [_]u64{ 1, 2, 3, 4, 7, 9 };
    var arr2 = [_]u64{ 5, 6, 8 };

    var allocator = testing.allocator;
    var S1 = Set.initWithSortedList(arr[0..], allocator);
    defer S1.deinit();
    var S2 = Set.initWithSortedList(arr2[0..], allocator);
    defer S2.deinit();
    // std.debug.print("initialized 2 variables", .{});
    var S3 = Set.setUnion(S1, S2, allocator);
    defer S3.deinit();
    // std.debug.print("initialized variables", .{});
    // std.debug.print("\n hmm:{any} \n", .{S3.arr.items});
    var i: u64 = 0;
    while (i < 9) : (i += 1) {
        try testing.expect(S3.arr.items[i] == i + 1);
    }
}

test "Set difference basic" {
    var arr = [_]u64{ 1, 2, 3, 4, 7, 9 };
    var arr2 = [_]u64{ 1, 4, 9, 10 };

    var allocator = testing.allocator;
    var S1 = Set.initWithSortedList(arr[0..], allocator);
    defer S1.deinit();
    var S2 = Set.initWithSortedList(arr2[0..], allocator);
    defer S2.deinit();
    // std.debug.print("initialized 2 variables", .{});
    var S3 = Set.setDifference(S1, S2, allocator);
    defer S3.deinit();
    // std.debug.print("initialized variables", .{});
    // std.debug.print("\n hmm:{any} \n", .{S3.arr.items});
    var expected_res = [_]u64{ 2, 3, 7 };
    var i: u64 = 0;
    while (i < 3) : (i += 1) {
        try testing.expect(S3.arr.items[i] == expected_res[i]);
    }
}

test "Graph basic" {

    // Draws the graph
    //A -> B<-D
    //  -> C -^

    //A = 0
    //B = 1
    //C = 2
    //D = 3
    var G = Graph.init(testing.allocator);
    defer G.deinit();

    var A = G.add_state();
    var B = G.add_state();
    // _ = G.add_state(0);
    // _ = G.add_state(1);

    var C = G.add_state();
    var D = G.add_state();

    G.add_connection(A, B);
    G.add_connection(A, C);
    G.add_connection(C, D);
    G.add_connection(D, B);
    try expect(G.graph.items[A].outgoing_edges.items.len == 2);
    try expect(G.graph.items[A].incoming_edges.items.len == 0);
    try expect(G.graph.items[B].outgoing_edges.items.len == 0);
    try expect(G.graph.items[B].incoming_edges.items.len == 2);
    try expect(G.graph.items[C].outgoing_edges.items.len == 1);
    try expect(G.graph.items[C].incoming_edges.items.len == 1);
    try expect(G.graph.items[D].outgoing_edges.items.len == 1);
    try expect(G.graph.items[D].incoming_edges.items.len == 1);

    try expect(G.graph.items[A].outgoing_edges.items[0] == B);
    try expect(G.graph.items[A].outgoing_edges.items[1] == C);

    try expect(G.graph.items[B].incoming_edges.items[0] == A);
    try expect(G.graph.items[B].incoming_edges.items[1] == D);

    try expect(G.graph.items[C].incoming_edges.items[0] == A);
    try expect(G.graph.items[C].outgoing_edges.items[0] == D);

    try expect(G.graph.items[D].incoming_edges.items[0] == C);
    try expect(G.graph.items[D].outgoing_edges.items[0] == B);

    // pub fn add_state(self: *Self, id: u64) *State {

    // pub fn find_state(self: *Self, id: u64) *State {

    // pub fn add_atoms_to_state(state: *State, atoms: []u64) void {

    // pub fn add_connection(from: *State, to: *State) void {
}
test "init preconfigured" {

    // new take on Benthem, Blackburn, figure 5

    var atomList = ArrayList(ArrayList(u64)).init(std.testing.allocator);
    defer atomList.deinit();
    var i: u64 = 0;
    while (i < 4) : (i += 1) {
        try atomList.append(ArrayList(u64).init(std.testing.allocator));
    }
    defer {
        for (atomList.items) |elem| {
            elem.deinit();
        }
    }

    var p: u64 = 1234;
    try atomList.items[0].append(p);
    try atomList.items[1].append(p);

    var nblist = ArrayList([2]u64).init(std.testing.allocator);
    defer nblist.deinit();

    try nblist.append([_]u64{ 0, 2 });
    try nblist.append([_]u64{ 0, 3 });
    try nblist.append([_]u64{ 3, 3 });
    try nblist.append([_]u64{ 3, 1 });
    try nblist.append([_]u64{ 1, 0 });

    var G = Graph.initialize_preconfigured_graph(atomList.items, nblist.items, std.testing.allocator);
    defer G.deinit();
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    G.print();
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});

    // G. SAT setup
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    // var formula_raw = "IMPLIES(ATOM(1234),ATOM(8008))";
    var formula_raw = "EX(AX(EX(ATOM(1234))))";
    if (Tokenizer.tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        std.debug.print("\n=========YOUR MOVE=========\n", .{});
        defer tokenizedArr.deinit();

        std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();

        var fac = AdequateFormulaSimpleFactory.init(allocator);
        const adeformula = AdequateFormulaGenerator.generate(formula, &fac);

        std.debug.print("\n", .{});
        adeformula.printPreOrderTree();

        var result = G.SAT(adeformula, allocator, allocator);
        var expected = [_]u64{ 0, 3 };
        std.debug.print("RESULT:{any}", .{result});
        try expect(mem.eql(u64, result.items, expected[0..expected.len]));
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "test more advanced figure" {

    //    //5<
    //    //^ \
    //    //v  \
    //    //3   \
    //    //^    4
    //    //v    ^
    //    //1 -> 2
    //    //^    ^
    //    //0 -> 6

    //        var atomList = ArrayList(ArrayList(u64)).init(std.testing.allocator);
    //        defer atomList.deinit();
    //        var i: u64 = 0;
    //        while (i < 6) : (i += 1) {
    //            try atomList.append(ArrayList(u64).init(std.testing.allocator));
    //        }
    //        defer {
    //            for (atomList.items) |elem| {
    //                elem.deinit();
    //            }
    //        }

    //        var p: u64 = 1234;
    //        var q: u64 = 8008;
    //        var r: u64 = 42;
    //        try atomList.items[0].append(p);
    //        try atomList.items[0].append(q);
    //        try atomList.items[0].append(r);

    //        try atomList.items[1].append(q);
    //        try atomList.items[2].append(q);
    //        try atomList.items[3].append(p);
    //        try atomList.items[3].append(q);

    //        var nblist = ArrayList([2]u64).init(std.testing.allocator);
    //        defer nblist.deinit();

    //        try nblist.append([_]u64{ 0, 2 });
    //        try nblist.append([_]u64{ 0, 3 });
    //        try nblist.append([_]u64{ 3, 3 });
    //        try nblist.append([_]u64{ 3, 1 });
    //        try nblist.append([_]u64{ 1, 0 });

    //        var G = Graph.initialize_preconfigured_graph(atomList.items, nblist.items, std.testing.allocator);
    //        defer G.deinit();
    //        std.debug.print("\n", .{});
    //        std.debug.print("\n", .{});
    //        std.debug.print("\n", .{});
    //        G.print();
    //        std.debug.print("\n", .{});
    //        std.debug.print("\n", .{});
    //        std.debug.print("\n", .{});

    //        // G. SAT setup
    //        var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    //        defer arena_instance.deinit();
    //        const allocator = arena_instance.allocator();

    //        // var formula_raw = "AND(EX(ATOM(1234)),AX(ATOM(8008)))";
    //        var formula_raw = "AND(EX(ATOM(1234)),AX(ATOM(8008)))";
    //        if (Tokenizer.tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
    //            std.debug.print("\n=========YOUR MOVE=========\n", .{});
    //            defer tokenizedArr.deinit();

    //            std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
    //            var parser = Parser.init(tokenizedArr.items);
    //            var formula = parser.parseExpression(allocator) catch unreachable;
    //            std.debug.print("\n", .{});
    //            formula.printPreOrderTree();

    //            var fac = AdequateFormulaSimpleFactory.init(allocator);
    //            const adeformula = AdequateFormulaGenerator.generate(formula, &fac);

    //            std.debug.print("\n", .{});
    //            adeformula.printPreOrderTree();

    //            var result = G.SAT(adeformula, allocator, allocator);
    //            var expected = [_]u64{ 0, 3 };
    //            std.debug.print("RESULT:{any}", .{result});
    //            try expect(mem.eql(u64, result.items, expected[0..expected.len]));
    //        } else |err| switch (err) {
    //            // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
    //            Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
    //            else => unreachable,
    //        }
}

test "test made up figure" {

    //Benthem, Blackburn, figure 5

    // 0 <-- 1
    // | \   ^
    // v  v  |
    // 2  3--|

    // 0:p
    //1:q
    //2:q
    //3:p,q

    var atomList = ArrayList(ArrayList(u64)).init(std.testing.allocator);
    defer atomList.deinit();
    var i: u64 = 0;
    while (i < 4) : (i += 1) {
        try atomList.append(ArrayList(u64).init(std.testing.allocator));
    }
    defer {
        for (atomList.items) |elem| {
            elem.deinit();
        }
    }

    var p: u64 = 1234;
    var q: u64 = 8008;
    try atomList.items[0].append(p);
    try atomList.items[1].append(q);
    try atomList.items[2].append(q);
    try atomList.items[3].append(p);
    try atomList.items[3].append(q);

    var nblist = ArrayList([2]u64).init(std.testing.allocator);
    defer nblist.deinit();

    try nblist.append([_]u64{ 0, 2 });
    try nblist.append([_]u64{ 0, 3 });
    try nblist.append([_]u64{ 3, 3 });
    try nblist.append([_]u64{ 3, 1 });
    try nblist.append([_]u64{ 1, 0 });

    var G = Graph.initialize_preconfigured_graph(atomList.items, nblist.items, std.testing.allocator);
    defer G.deinit();
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    G.print();
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});

    // G. SAT setup
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    // var formula_raw = "AND(EX(ATOM(1234)),AX(ATOM(8008)))";
    var formula_raw = "AND(EX(ATOM(1234)),AX(ATOM(8008)))";
    if (Tokenizer.tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        std.debug.print("\n=========YOUR MOVE=========\n", .{});
        defer tokenizedArr.deinit();

        std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();

        var fac = AdequateFormulaSimpleFactory.init(allocator);
        const adeformula = AdequateFormulaGenerator.generate(formula, &fac);

        std.debug.print("\n", .{});
        adeformula.printPreOrderTree();

        var result = G.SAT(adeformula, allocator, allocator);
        var expected = [_]u64{ 0, 3 };
        std.debug.print("RESULT:{any}", .{result});
        try expect(mem.eql(u64, result.items, expected[0..expected.len]));
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}
