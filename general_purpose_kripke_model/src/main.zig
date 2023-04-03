const std = @import("std");
const testing = std.testing;
const Tokenizer = @import("Tokenizer.zig");
const Parser = @import("Parser.zig").Parser;
const Formula = @import("Formula.zig");
const AdequateFormulaSimpleFactory = Formula.AdequateFormulaSimpleFactory;
const AdequateFormulaGenerator = Formula.AdequateFormulaGenerator;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    // var formula_raw = "IMPLIES(ATOM(1234),ATOM(8008))";
    var formula_raw = "OR(   ATOM( 1234),ATOM(8008))";
    if (Tokenizer.tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
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
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
