const Formula = @import("./Formula.zig");
const std = @import("std");
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
        outgoing_edges: ArrayList(State),
        incoming_edges: ArrayList(State),
        //Q: Does the graph representation need to know incoming edges?

    };

    const SetOfStateIdentifiers = struct {
        //TODO: Trivial if StateIdentifiers are sorted, guaranteed O(n) to merge two sets of total n elements
        //Union
        // Gørtz has shown how to do this with union-find in https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.88.6803
        //SetDifference
    };

    // Public interface
    // initialize_graph( list_of_state_identifiers, list_of_list_of_atoms, list_of_pairs_of_identifiers  )
    // add_state(identifier, list_of_identiefiers_outgoing, list_of_identifiers_going_in)

    // add_state(identifier)
    // Cannot fail other than memory error
    // Cannot fail if identifier is already present

    // add_atoms_to_states(list_of_state_ids, list_of_atoms)
    // Can fail if some identifier is wrong
    // And memory
    // Cannot fail if booleans already exist in state_ids

    //remove_state // Might be useful when extending with epistemic logic? So that I can make a copy of a graph and then do a new thing
    // If I understood correctly a graph is never removed so I could just us e memory pool

    // add_connection(from:identifier, to: identifier)
    // Can fail if lack memory, will not fail if the connection is already there.

    //pub fn SAT(self:*Self, formula:*AdequateSetFormula)

    //pub fn SATHelper(self:*Self, formula:*AdequateSetFormula, Set:Set of state identifiers)
    // pub fn createState(
    // pub fn getNeighbourIterator

};

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
