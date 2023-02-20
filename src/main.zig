const Formula = @import("./Formula.zig");
const AdequateSetFormula = Formula.AdequateSetFormula;
const std = @import("std");
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

    pub fn init(allocator: Allocator) Self {
        return Self{
            .graph = ArrayList(State).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.graph.items) |elem| {
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
        state_id: u64, // id might differ from arraylist location so here
        atoms: ArrayList(u64),
        outgoing_edges: ArrayList(*State),
        incoming_edges: ArrayList(*State),
        //Q: Does the graph representation need to know incoming edges?
        // Incorrect behaviour inbound if state_id is identical to some other state_id
        pub fn init(state_id: u64, allocator: Allocator) State {
            return struct {
                .id = state_id,
                .atoms = ArrayList(u64).init(allocator),
                .outgoing_edges = ArrayList(*State).init(allocator) catch unreachable,
                .incoming_edges = ArrayList(*State).init(allocator) catch unreachable,
            };
        }
    };

    // Public interface
    // initialize_graph( list_of_state_identifiers, list_of_list_of_atoms, list_of_pairs_of_identifiers  )
    // add_state(identifier, list_of_identiefiers_outgoing, list_of_identifiers_going_in)

    // add_state(identifier)
    // Cannot fail other than memory error
    // Cannot fail if identifier is already present
    pub fn add_state(self: *Self, id: u64) *State {
        try self.graph.append(State.init(id, self.allocator)) catch unreachable;
        return self.graph.items[self.graph.items.len - 1];
    }

    pub fn find_state(self: *Self, id: u64) *State {
        for (self.graph) |state| {
            if (state.id == id) {
                return &state;
            }
        }
    }

    pub fn add_atoms_to_state(state: *State, atoms: []u64) void {
        try state.atoms.appendSlice(atoms) catch unreachable;
    }

    pub fn add_connection(from: *State, to: *State) void {
        from.outgoing_edges.append(to);
        to.incoming_edges.append(from);
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
        for (self.graph) |state| {
            tmp_states.append(state.id);
        }
        sort.sort(u64, tmp_states.items, {}, comptime sort.asc(u64));

        var initial_set = Set.initWithSortedList(tmp_states.items, calculation_allocator);

        tmp_states.deinit();

        var tmp_result = self.SATHelper(formula, initial_set, calculation_allocator);
        defer tmp_result.deinit();
        return tmp_result.arr.clone(result_allocator);
    }

    pub fn SATHelper(self: *Self, formula: *AdequateSetFormula, set: *Set, calculation_allocator: Allocator) *Set {
        switch (formula.*) {
            .EX => {
                var X = self.SAT(formula.EX.args[0], set, calculation_allocator);
                var tmp = Set.initEmptySet(calculation_allocator);
                for (X) |x| {
                    var acc = tmp;
                    defer acc.deinit();
                    var arrayList = ArrayList(u64).init(calculation_allocator);

                    for (x.outgoing_edges) |state| {
                        arrayList.append(state.id);
                    }
                    defer arrayList.deinit();
                    sort.sort(u64, arrayList.items, {}, comptime sort.asc(u64));
                    var setfromlist = Set.initWithSortedList(arrayList.items, calculation_allocator);
                    defer setfromlist.deinit();
                    tmp = acc.setUnion(setfromlist);
                }
                return tmp;
            },
            .AND => {
                var f1 = formula.AND.args[0];
                var f2 = formula.AND.args[1];
                var s1 = SATHelper(f1, set, calculation_allocator);
                defer s1.deinit();
                return SATHelper(f2, s1, calculation_allocator);
            },

            .NOT => {
                var f1 = formula.NOT.args[0];
                var s1 = SATHelper(f1);
                defer s1.deinit();
                return SATHelper(f1, s1, calculation_allocator);
            },
            .ATOM => {
                var acc = ArrayList(u64).init(calculation_allocator);
                defer acc.deinit();
                for (set.arr) |state_id| {
                    var state = self.find(state_id);
                    for (state.atoms) |atom| {
                        if (atom.ATOM == formula.ATOM) {
                            acc.append(state_id);
                            break;
                        }
                    }
                }
                sort.sort(u64, acc.items, {}, comptime sort.asc(u64));
                return Set.initWithSortedList(acc.items);
            },
            .FALSE => {
                return Set.initEmptySet(calculation_allocator);
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

    var A = G.add_state(0);
    var B = G.add_state(1);
    // var C = G.add_state(2);
    // var D = G.add_state(3);

    G.add_connection(A, B);
    // G.add_connection(A, C);
    // G.add_connection(C, D);
    // G.add_connection(D, B);
    // try expect(A.outgoing_edges.items.len == 2);
    // try expect(A.incoming_edges.items.len == 0);

    // try expect(B.outgoing_edges.items.len == 0);
    // try expect(B.incoming_edges.items.len == 2);

    // try expect(C.outgoing_edges.items.len == 1);
    // try expect(C.incoming_edges.items.len == 1);

    // try expect(D.outgoing_edges.items.len == 1);
    // try expect(D.incoming_edges.items.len == 1);

    // pub fn add_state(self: *Self, id: u64) *State {

    // pub fn find_state(self: *Self, id: u64) *State {

    // pub fn add_atoms_to_state(state: *State, atoms: []u64) void {

    // pub fn add_connection(from: *State, to: *State) void {
}
