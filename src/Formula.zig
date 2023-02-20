const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const expect = std.testing.expect;
// const MemoryPool = std.heap.MemoryPool;

//TODO: Then it should be sufficient to take a string of formula and parse it directly
//into tree of formula
// I should check backus naur form of the formula before continuing.
// I will after the construction of the AST, I will modify the AST to have the adequate set

const Formula = union(enum) {
    const SingleArg = struct {
        args: [1]*Formula,
    };
    const DoubleArg = struct {
        args: [2]*Formula,
    };
    AX: SingleArg, // AX => [] in CTL
    EX: SingleArg, // EX => <> in CTL
    OR: DoubleArg,
    AND: DoubleArg,
    NOT: SingleArg,
    IMPLIES: DoubleArg,
    ATOM: u64,
    TRUE,
    FALSE,
};

const AdequateSetFormula = union(enum) {
    const Self = @This();
    const SingleArg = struct {
        args: [1]*Self,
    };
    const DoubleArg = struct {
        args: [2]*Self,
    };
    EX: SingleArg,
    AND: DoubleArg,
    NOT: SingleArg,
    ATOM: u64,
    FALSE,
    pub fn printPreOrderTree(self: *Self) void {
        self.preOrderTreeHelper(0);
    }
    fn preOrderTreeHelper(self: *Self, depth: u64) void {
        printSpaces(depth);
        switch (self.*) {
            .EX => {
                std.debug.print("EX\n", .{});
                preOrderTreeHelper(self.EX.args[0], depth + 1);
            },
            .AND => {
                std.debug.print("AND\n", .{});
                preOrderTreeHelper(self.AND.args[0], depth + 1);
                preOrderTreeHelper(self.AND.args[1], depth + 1);
            },
            .NOT => {
                std.debug.print("NOT\n", .{});
                preOrderTreeHelper(self.NOT.args[0], depth + 1);
            },
            .ATOM => {
                std.debug.print("ATOM({})\n", .{self.ATOM});
            },
            .FALSE => {
                std.debug.print("FALSE\n", .{});
            },
        }
    }
    fn printSpaces(spaces: u64) void {
        var i: u64 = 0;
        while (i < spaces) : (i += 1) {
            std.debug.print(" ", .{});
        }
    }
};

// TODO: The memory error handling can be made more robust, but right now it will just panic :)
const AdequateFormulaSimpleFactory = struct {
    allocator: Allocator,
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return  Self{
            .allocator = allocator,
        };
    }

    // pub fn deinit(self: *Self) void {
    //     self.allocator.deinit();
    // }

    pub fn EXp(self: *Self, formula: *AdequateSetFormula) *AdequateSetFormula {
        var EX = self.allocator.create(AdequateSetFormula) catch unreachable;
        EX.* = AdequateSetFormula{ .EX = AdequateSetFormula.SingleArg{ .args = [1]*AdequateSetFormula{formula} } };
        return EX;
    }

    pub fn ANDp(self: *Self, formula1: *AdequateSetFormula, formula2: *AdequateSetFormula) *AdequateSetFormula {
        var AND = self.allocator.create(AdequateSetFormula) catch unreachable;
        AND.* = AdequateSetFormula{ .AND = AdequateSetFormula.DoubleArg{ .args = [2]*AdequateSetFormula{ formula1, formula2 } } };
        return AND;
    }

    pub fn NOTp(self: *Self, formula: *AdequateSetFormula) *AdequateSetFormula {
        var NOT = self.allocator.create(AdequateSetFormula) catch unreachable;
        NOT.* = AdequateSetFormula{ .NOT = AdequateSetFormula.SingleArg{ .args = [1]*AdequateSetFormula{formula} } };
        return NOT;
    }

    pub fn copyNode(self: *Self, atomToSave: *Formula) *AdequateSetFormula {
        var atom = self.allocator.create(AdequateSetFormula) catch unreachable;
        switch (atomToSave.*) {
            .ATOM => {
                atom.* = AdequateSetFormula{ .ATOM = atomToSave.ATOM };
            },
            .FALSE => {
                atom.* = AdequateSetFormula{ .FALSE = {} };
            },
            else => unreachable,
        }
        return atom;
    }
};
const AdequateFormulaGenerator = struct {
    pub fn generate(raw_formula: *Formula, factory: *AdequateFormulaSimpleFactory) *AdequateSetFormula {
        return recursiveHelper(raw_formula, factory);
    }

    fn recursiveHelper(raw_formula: *Formula, fac: *AdequateFormulaSimpleFactory) *AdequateSetFormula {
        // _ = allocator;
        switch (raw_formula.*) {
            .AX => {
                // -EX-f
                // Idea: make list like so [NEG,EX,NEG,F] and traverse it in reverse and have a method called
                var f = recursiveHelper(raw_formula.AX.args[0], fac);
                // return fac.NOTp(fac.EXp(fac.NOTp(f)));
                return fac.NOTp(fac.EXp(fac.NOTp(f)));
            },
            .EX => {
                // Trivial
                var f = recursiveHelper(raw_formula.EX.args[0], fac);
                return fac.EXp(f);
            },
            .OR => {
                // not trivial
                // But solution will be better because we won't have to do set
                // merge
                // p v q => -(-p ^ -q)
                var p = recursiveHelper(raw_formula.OR.args[0], fac);
                var q = recursiveHelper(raw_formula.OR.args[1], fac);

                return fac.NOTp(fac.ANDp(fac.NOTp(p), fac.NOTp(q)));
            },
            .AND => {
                //trivial
                // p^q
                var p = recursiveHelper(raw_formula.AND.args[0], fac);
                var q = recursiveHelper(raw_formula.AND.args[1], fac);
                return fac.ANDp(p, q);
            },
            .NOT => {
                //trivial
                //-p
                var p = recursiveHelper(raw_formula.NOT.args[0], fac);
                return fac.NOTp(p);
            },
            .IMPLIES => {
                //not trivial
                // p -> q == -p v q == -(p ^ -q)
                var p = recursiveHelper(raw_formula.IMPLIES.args[0], fac);
                var q = recursiveHelper(raw_formula.IMPLIES.args[1], fac);
                return fac.NOTp(fac.ANDp(p, fac.NOTp(q)));
            },
            .TRUE => {
                var tmpfalse = Formula{ .FALSE = {} };
                return fac.NOTp(fac.copyNode(&tmpfalse));
            },
            // Base case
            else => {
                return fac.copyNode(raw_formula);
            },
        }
    }
};
pub fn test_allocate_two_nodes(allocator: Allocator) !*AdequateSetFormula {
    var leaf = try allocator.create(AdequateSetFormula);
    leaf.* = AdequateSetFormula{ .FALSE = {} };

    var top = try allocator.create(AdequateSetFormula);
    top.* = AdequateSetFormula{ .NOT = AdequateSetFormula.SingleArg{ .args = [1]*AdequateSetFormula{leaf} } };
    return top;
}

test "allocate simple arg" {
    const alloc = std.testing.allocator;
    var hmm = try test_allocate_two_nodes(alloc);
    // if (hmm.NOT) {
    // }
    switch (hmm.*) {
        .NOT => try testing.expect(true),
        else => try testing.expect(false),
    }
    switch (hmm.NOT.args[0].*) {
        .FALSE => try testing.expect(true),
        else => try testing.expect(false),
    }

    alloc.destroy(hmm.NOT.args[0]);
    alloc.destroy(hmm);

    // hmm.NOT.args[0].FALSE
}
test "Basic tree" {
    var hmm = Formula{ .OR = Formula.DoubleArg{ .args = undefined } };
    var atom1 = Formula{ .ATOM = 1 };
    var atom2 = Formula{ .ATOM = 2 };
    hmm.OR.args[0] = &atom1;
    hmm.OR.args[1] = &atom2;
    try testing.expect(hmm.OR.args[0].ATOM == 1);
    try testing.expect(hmm.OR.args[1].ATOM == 2);

    switch (hmm) {
        Formula.OR => try testing.expect(true),
        else => try testing.expect(false),
    }
    switch (hmm.OR.args[0].*) {
        .ATOM => try testing.expect(true),
        else => try testing.expect(false),
    }
    switch (hmm.OR.args[1].*) {
        .ATOM => try testing.expect(true),
        else => try testing.expect(false),
    }
}

test "Make simple adequate tree from non-adequate tree" {
    var root_unpolished = Formula{ .OR = Formula.DoubleArg{ .args = undefined } };
    var atom1 = Formula{ .ATOM = 1 };
    var atom2 = Formula{ .ATOM = 2 };
    root_unpolished.OR.args[0] = &atom1;
    root_unpolished.OR.args[1] = &atom2;
    var AAllocator = ArenaAllocator.init(std.testing.allocator);
    defer AAllocator.deinit();
    var fac = AdequateFormulaSimpleFactory.init(AAllocator.allocator());
    // defer fac.deinit();
    const formula = AdequateFormulaGenerator.generate(&root_unpolished, &fac);
    // try expect(formula.root.NOT == AdequateSetFormula.NOT)
    std.debug.print("\nany argument ====================:{any}\n", .{formula.*});
    switch (formula.*) {
        .NOT => try expect(true),
        else => try expect(false),
    }
    AdequateSetFormula.printPreOrderTree(formula);
}
test "Make  adequate tree from non-adequate tree" {
    var root_unpolished = Formula{ .OR = Formula.DoubleArg{ .args = undefined } };
    var atom1 = Formula{ .ATOM = 1 };
    var atom2 = Formula{ .ATOM = 2 };
    var AX = Formula{ .AX = Formula.SingleArg{ .args = [1]*Formula{&atom2} } };
    root_unpolished.OR.args[0] = &atom1;
    root_unpolished.OR.args[1] = &AX;
    var AAllocator = ArenaAllocator.init(std.testing.allocator);
    defer AAllocator.deinit();
    var fac = AdequateFormulaSimpleFactory.init(AAllocator.allocator());
    const formula = AdequateFormulaGenerator.generate(&root_unpolished, &fac);
    // try expect(formula.root.NOT == AdequateSetFormula.NOT)
    std.debug.print("\nany argument ====================:{any}\n", .{formula.*});
    switch (formula.*) {
        .NOT => try expect(true),
        else => try expect(false),
    }
    AdequateSetFormula.printPreOrderTree(formula);
}
