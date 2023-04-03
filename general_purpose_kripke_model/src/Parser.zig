const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const expect = std.testing.expect;
const Token = @import("Tokenizer.zig").Token;
const Tokenizer = @import("Tokenizer.zig");
const TokenTag = @import("Tokenizer.zig").TokenTag;
const Formula = @import("Formula.zig").Formula;
const tokenizeFormula = @import("Tokenizer.zig").tokenizeFormula;

pub const IncorrectFormattingError = error{
    TokenizedInputGivesInvalidParseTree,
};

pub const Parser = struct {
    const Self = @This();
    index: usize,
    tokenArr: []const Token,
    pub fn init(tokenArr: []const Token) Self {
        return Self{
            .index = 0,
            .tokenArr = tokenArr,
        };
    }
    pub fn accept(self: *Self, tag: TokenTag) bool {
        if (tag == self.tokenArr[self.index].tag) {
            self.index += 1;
            return true;
        }
        return false;
    }
    pub fn expect(self: *Self, tag: TokenTag) !void {
        if (self.accept(tag)) {} else {
            return IncorrectFormattingError.TokenizedInputGivesInvalidParseTree;
        }
    }
    pub fn parseExpression(self: *Self, allocator: Allocator) !*Formula {
        switch (self.tokenArr[self.index].tag) {
            .AX => {
                try self.expect(TokenTag.AX);
                try self.expect(TokenTag.LPAREN);
                var subformula = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var AX = try allocator.create(Formula);
                AX.* = Formula{ .AX = Formula.SingleArg{ .args = [1]*Formula{subformula} } };
                return AX;
            },
            .EX => {
                try self.expect(TokenTag.EX);
                try self.expect(TokenTag.LPAREN);
                var subformula = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var EX = try allocator.create(Formula);
                EX.* = Formula{ .EX = Formula.SingleArg{ .args = [1]*Formula{subformula} } };
                return EX;
            },
            .NOT => {
                try self.expect(TokenTag.NOT);
                try self.expect(TokenTag.LPAREN);
                var subformula = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var NOT = try allocator.create(Formula);
                NOT.* = Formula{ .NOT = Formula.SingleArg{ .args = [1]*Formula{subformula} } };
                return NOT;
            },
            .OR => {
                try self.expect(TokenTag.OR);
                try self.expect(TokenTag.LPAREN);
                var sub1 = try self.parseExpression(allocator);
                try self.expect(TokenTag.COMMA);
                var sub2 = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var OR = try allocator.create(Formula);
                OR.* = Formula{ .OR = Formula.DoubleArg{ .args = [2]*Formula{ sub1, sub2 } } };
                return OR;
            },
            .AND => {
                try self.expect(TokenTag.AND);
                try self.expect(TokenTag.LPAREN);
                var sub1 = try self.parseExpression(allocator);
                try self.expect(TokenTag.COMMA);
                var sub2 = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var AND = try allocator.create(Formula);
                AND.* = Formula{ .AND = Formula.DoubleArg{ .args = [2]*Formula{ sub1, sub2 } } };
                return AND;
            },
            .IMPLIES => {
                try self.expect(TokenTag.IMPLIES);
                try self.expect(TokenTag.LPAREN);
                var sub1 = try self.parseExpression(allocator);
                try self.expect(TokenTag.COMMA);
                var sub2 = try self.parseExpression(allocator);
                try self.expect(TokenTag.RPAREN);
                var IMPLIES = try allocator.create(Formula);
                IMPLIES.* = Formula{ .IMPLIES = Formula.DoubleArg{ .args = [2]*Formula{ sub1, sub2 } } };
                return IMPLIES;
            },
            .ATOM => {
                try self.expect(TokenTag.ATOM);
                try self.expect(TokenTag.LPAREN);
                try self.expect(TokenTag.LITERAL);
                const literal_val = self.tokenArr[self.index - 1].atom_value.?;
                try self.expect(TokenTag.RPAREN);

                var atom = try allocator.create(Formula);
                atom.* = Formula{ .ATOM = literal_val };
                return atom;
            },
            .TRUE => {
                try self.expect(TokenTag.TRUE);
                var TRUE = try allocator.create(Formula);
                TRUE.* = Formula{ .TRUE = {} };
                return TRUE;
            },
            .FALSE => {
                try self.expect(TokenTag.FALSE);
                var FALSE = try allocator.create(Formula);
                FALSE.* = Formula{ .FALSE = {} };
                return FALSE;
            },
            else => return IncorrectFormattingError.TokenizedInputGivesInvalidParseTree,
        }
    }
};

test "parsing simple" {
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    var formula_raw = "AX(ATOM(3))";
    if (tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        defer tokenizedArr.deinit();

        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "parsing advanced" {
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    var formula_raw = "AX(IMPLIES(ATOM(3),EX(TRUE)))";
    if (tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        defer tokenizedArr.deinit();

        std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "parsing less advanced" {
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    // var formula_raw = "IMPLIES(ATOM(1234),ATOM(8008))";
    var formula_raw = "IMPLIES(NOT(ATOM(1234)),NOT(NOT(ATOM(8008))))";
    if (tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        defer tokenizedArr.deinit();

        std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "parsing advanced advanced" {
    var arena_instance = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_instance.deinit();
    const allocator = arena_instance.allocator();

    // var formula_raw = "IMPLIES(ATOM(1234),ATOM(8008))";
    var formula_raw = "OR(AND(EX(NOT(IMPLIES(NOT(ATOM(1234)),NOT(NOT(ATOM(8008)))))),AX(IMPLIES(ATOM(3),ATOM(4)))),ATOM(5))";
    if (tokenizeFormula(formula_raw, allocator)) |tokenizedArr| {
        defer tokenizedArr.deinit();

        std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        var parser = Parser.init(tokenizedArr.items);
        var formula = parser.parseExpression(allocator) catch unreachable;
        std.debug.print("\n", .{});
        formula.printPreOrderTree();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        Tokenizer.IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}
