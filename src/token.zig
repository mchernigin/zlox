const std = @import("std");

pub const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

pub const Literal = union(enum) {
    String: []const u8,
    Number: i64,
    Bool: bool,
    Nil,

    const Self = @This();

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        switch (self) {
            inline .String => |value, tag| try writer.print("{s}({s})", .{ @tagName(tag), value }),
            inline .Number => |value, tag| try writer.print("{s}({d})", .{ @tagName(tag), value }),
            inline .Bool => |value, tag| try writer.print("{s}({})", .{ @tagName(tag), value }),
            inline .Nil => |tag| try writer.print("{s}", .{@tagName(tag)}),
        }
    }
};

pub const Token = struct {
    token_type: TokenType,
    lexeme: []const u8,
    literal: ?Literal,
    line: u32,

    const Self = @This();

    pub fn init(token_type: TokenType, lexeme: []const u8, literal: ?Literal, line: u32) Self {
        return .{
            .token_type = token_type,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        var token_type_iter = std.mem.splitBackwardsSequence(u8, @tagName(self.token_type), ".");
        var token_type_name = token_type_iter.first();
        try writer.print("{d} | {s} \"{s}\"", .{ self.line, token_type_name, self.lexeme });
        if (self.literal != null) try writer.print(": {any}", .{self.literal});
    }
};
