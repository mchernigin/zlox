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
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?Literal,
    line: u32,

    const Self = @This();

    pub fn init(tt: TokenType, lexeme: []const u8, literal: ?Literal, line: u32) Self {
        return .{
            .type = tt,
            .lexeme = lexeme,
            .literal = literal,
            .line = line,
        };
    }
};