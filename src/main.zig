const std = @import("std");
const testing = std.testing;

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
    AX: SingleArg,
    EX: SingleArg,
    OR: DoubleArg,
    AND: DoubleArg,
    NOT: SingleArg,
    IMPLIES: DoubleArg,
    ATOM: u64,
};

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
}
