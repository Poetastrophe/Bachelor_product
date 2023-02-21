const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;
const mem = std.mem;
pub const TokenTag = enum {
    AX,
    EX,
    OR,
    AND,
    NOT,
    IMPLIES,
    ATOM,
    TRUE,
    FALSE,
    LPAREN,
    RPAREN,
    LITERAL,
    COMMA,
};

pub const Token = struct {
    tag: TokenTag,
    atom_value: ?usize,
};

pub const IncorrectFormattingError = error{
    UserTypedFormula,
};

pub fn tokenizeFormula(formula: []const u8, allocator: Allocator) !ArrayList(Token) {
    var result = ArrayList(Token).init(allocator);
    errdefer result.deinit();
    var i: usize = 0;
    while (i < formula.len) {
        var prev_run = i;
        if (eql(formula, "AX", &i)) {
            // std.debug.print("\n AX entered\n", .{});
            try result.append(Token{ .tag = .AX, .atom_value = null });
        } else if (eql(formula, "EX", &i)) {
            try result.append(Token{ .tag = .EX, .atom_value = null });
        } else if (eql(formula, "OR", &i)) {
            try result.append(Token{ .tag = .OR, .atom_value = null });
        } else if (eql(formula, "AND", &i)) {
            try result.append(Token{ .tag = .AND, .atom_value = null });
        } else if (eql(formula, "NOT", &i)) {
            try result.append(Token{ .tag = .NOT, .atom_value = null });
        } else if (eql(formula, "IMPLIES", &i)) {
            try result.append(Token{ .tag = .IMPLIES, .atom_value = null });
        } else if (eql(formula, "ATOM", &i)) {
            try result.append(Token{ .tag = .ATOM, .atom_value = null });
        } else if (eql(formula, "TRUE", &i)) {
            try result.append(Token{ .tag = .TRUE, .atom_value = null });
        } else if (eql(formula, "FALSE", &i)) {
            try result.append(Token{ .tag = .FALSE, .atom_value = null });
        } else if (eql(formula, "(", &i)) {
            try result.append(Token{ .tag = .LPAREN, .atom_value = null });
        } else if (eql(formula, ")", &i)) {
            try result.append(Token{ .tag = .RPAREN, .atom_value = null });
        } else if (eql(formula, ",", &i)) {
            try result.append(Token{ .tag = .COMMA, .atom_value = null });
        } else if (eql(formula, " ", &i)) {} else {
            //parse literal number
            var j: usize = 0;
            while ('0' <= formula[i + j] and formula[i + j] <= '9') : (j += 1) {}
            if (j != 0) {
                var num = std.fmt.parseInt(u64, formula[i .. i + j], 10) catch unreachable;
                try result.append(Token{ .tag = .LITERAL, .atom_value = num });
                // std.debug.print("\nj:{}\n", .{j});
                i += j;
            }
        }
        if (prev_run == i) {
            return IncorrectFormattingError.UserTypedFormula;
        }
        // std.debug.print("\ni:{}\n", .{i});
    }
    return result;
}

pub fn findError(formula: []const u8) usize {
    var i: usize = 0;
    while (i < formula.len) {
        var prev_run = i;
        if (eql(formula, "AX", &i)) {
            //
        } else if (eql(formula, "EX", &i)) {
            //
        } else if (eql(formula, "AND", &i)) {
            //
        } else if (eql(formula, "NOT", &i)) {
            //
        } else if (eql(formula, "IMPLIES", &i)) {
            //
        } else if (eql(formula, "ATOM", &i)) {
            //
        } else if (eql(formula, "TRUE", &i)) {
            //
        } else if (eql(formula, "FALSE", &i)) {
            //
        } else if (eql(formula, "(", &i)) {
            //
        } else if (eql(formula, ")", &i)) {
            //
        } else if (eql(formula, ",", &i)) {
            //
        } else if (eql(formula, " ", &i)) {} else {
            //parse literal number
            var j: usize = 0;
            while ('0' <= formula[i + j] and formula[i + j] <= '9') : (j += 1) {}
            if (j != 0) {
                i += j;
            }
        }
        if (prev_run == i) {
            return i;
        }
    }
    return i;
}

fn eql(formula: []const u8, other: []const u8, i: *u64) bool {
    var width: u64 = other.len;
    if ((i.* + width) <= formula.len and mem.eql(u8, formula[i.* .. i.* + width], other)) {
        i.* += width;
        return true;
    }
    return false;
}

test "tokenize basic" {
    var formula = "AX(ATOM(3))";
    if (tokenizeFormula(formula, std.testing.allocator)) |tokenizedArr| {
        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        tokenizedArr.deinit();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber {}\n", .{findError(formula)}),
        IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "tokenize basic with error" {
    var formula = "AND(ATOM(3),TOM(3))";
    if (tokenizeFormula(formula, std.testing.allocator)) |_| {
        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        // tokenizedArr.deinit();
    } else |err| switch (err) {
        // IncorrectFormattingError.UserTypedFormula => try expect(findError(formula) == 12),
        IncorrectFormattingError.UserTypedFormula => std.debug.print("\ncolumnNumber ======={}\n", .{findError(formula)}),
        else => unreachable,
    }
}

test "tokenize more advanced" {
    var formula = "AX(OR(ATOM(3),ATOM(4)))";
    if (tokenizeFormula(formula, std.testing.allocator)) |tokenizedArr| {
        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        tokenizedArr.deinit();
    } else |err| switch (err) {
        IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}

test "tokenize more advanced with error" {
    var formula = "AX(O(ATOM(3),ATOM(4)))";
    //                ^ column 3
    if (tokenizeFormula(formula, std.testing.allocator)) |tokenizedArr| {
        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        tokenizedArr.deinit();
    } else |err| switch (err) {
        IncorrectFormattingError.UserTypedFormula => try expect(findError(formula) == 3),
        else => unreachable,
    }
}

test "tokenize more more advanced" {
    var formula = "AX(OR(ATOM(1234),ATOM(8008)))";
    if (tokenizeFormula(formula, std.testing.allocator)) |tokenizedArr| {
        try expect(tokenizedArr.items[6].atom_value.? == 1234);
        try expect(tokenizedArr.items[11].atom_value.? == 8008);
        // std.debug.print("\ntokenarr{any}\n", .{tokenizedArr.items});
        tokenizedArr.deinit();
    } else |err| switch (err) {
        IncorrectFormattingError.UserTypedFormula => unreachable,
        else => unreachable,
    }
}
