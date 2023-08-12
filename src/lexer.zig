const std = @import("std");
const lox = @import("main.zig");
const token = @import("token.zig");

const TT = token.TokenType;

pub const Scanner = struct {
    source: []const u8,
    tokens: std.ArrayList(token.Token),
    start: u32 = 0,
    current: u32 = 0,
    line: u32 = 1,

    allocator: std.mem.Allocator,
    keywords: std.StringHashMap(TT),

    const Self = @This();

    pub fn init(source: []const u8, allocator: std.mem.Allocator) !Self {
        var keywords = std.StringHashMap(TT).init(allocator);

        try keywords.put("and", TT.AND);
        try keywords.put("class", TT.CLASS);
        try keywords.put("else", TT.ELSE);
        try keywords.put("false", TT.FALSE);
        try keywords.put("for", TT.FOR);
        try keywords.put("fun", TT.FUN);
        try keywords.put("if", TT.IF);
        try keywords.put("nil", TT.NIL);
        try keywords.put("or", TT.OR);
        try keywords.put("print", TT.PRINT);
        try keywords.put("return", TT.RETURN);
        try keywords.put("super", TT.SUPER);
        try keywords.put("this", TT.THIS);
        try keywords.put("true", TT.TRUE);
        try keywords.put("var", TT.VAR);
        try keywords.put("while", TT.WHILE);

        return .{
            .source = source,
            .tokens = std.ArrayList(token.Token).init(allocator),
            .allocator = allocator,
            .keywords = keywords,
        };
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
        self.keywords.deinit();
        self.* = undefined;
    }

    pub fn scanTokens(self: *Self) !std.ArrayList(token.Token) {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }

        try self.tokens.append(token.Token.init(TT.EOF, "", null, self.line));

        return self.tokens;
    }

    fn scanToken(self: *Self) !void {
        const c = self.advance();
        try switch (c) {
            '(' => self.addToken(TT.LEFT_PAREN),
            ')' => self.addToken(TT.RIGHT_PAREN),
            '{' => self.addToken(TT.LEFT_BRACE),
            '}' => self.addToken(TT.RIGHT_BRACE),
            ',' => self.addToken(TT.COMMA),
            '.' => self.addToken(TT.DOT),
            '-' => self.addToken(TT.MINUS),
            '+' => self.addToken(TT.PLUS),
            ';' => self.addToken(TT.SEMICOLON),
            '*' => self.addToken(TT.STAR),
            '!' => self.addToken(if (self.match('=')) TT.BANG_EQUAL else TT.BANG),
            '=' => self.addToken(if (self.match('=')) TT.EQUAL_EQUAL else TT.EQUAL),
            '<' => self.addToken(if (self.match('=')) TT.LESS_EQUAL else TT.LESS),
            '>' => self.addToken(if (self.match('=')) TT.GREATER_EQUAL else TT.GREATER),
            '/' => if (self.match('/')) {
                while (self.peek() != '\n' and !self.isAtEnd()) _ = self.advance();
            } else if (self.match('*')) {
                var deep: i16 = 1;
                while (deep > 0 and !self.isAtEnd()) {
                    if (self.match('*') and self.match('/')) deep -= 1;
                    if (self.match('/') and self.match('*')) deep += 1;
                    if (self.advance() == '\n') self.line += 1;
                }
            } else {
                try self.addToken(TT.SLASH);
            },
            ' ', '\r', '\t' => {},
            '\n' => self.line += 1,
            '"' => self.string(),
            'o' => if (self.match('r')) self.addToken(TT.OR),
            else => if (isDigit(c)) {
                try self.number();
            } else if (isAlpha(c)) {
                try self.identifier();
            } else {
                try lox.err(lox.IntepreterError.LexerError, self.line, "Unexpected character.");
            },
        };
    }

    fn isAtEnd(self: *Self) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Self) u8 {
        const c = self.source[self.current];
        self.current += 1;

        return c;
    }

    fn addToken(self: *Self, token_type: TT) !void {
        try self.addTokenWithLiteral(token_type, null);
    }

    fn addTokenWithLiteral(self: *Self, token_type: TT, literal: ?token.Literal) !void {
        const text = self.source[self.start..self.current];
        try self.tokens.append(token.Token.init(token_type, text, literal, self.line));
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd() or self.source[self.current] != expected) {
            return false;
        }

        self.current += 1;
        return true;
    }

    fn peek(self: *Self) u8 {
        return if (self.isAtEnd()) 0 else self.source[self.current];
    }

    fn string(self: *Self) !void {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            try lox.err(lox.IntepreterError.LexerError, self.line, "Unterminated string.");
            return lox.IntepreterError.LexerError;
        }

        _ = self.advance();

        const string_value = self.source[self.start + 1 .. self.current - 1];
        try self.addTokenWithLiteral(TT.STRING, token.Literal{ .String = string_value });
    }

    fn number(self: *Self) !void {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }

        const value = try std.fmt.parseInt(i64, self.source[self.start..self.current], 10);
        try self.addTokenWithLiteral(TT.NUMBER, token.Literal{ .Number = value });
    }

    fn peekNext(self: *Self) u8 {
        return if (self.current + 1 >= self.source.len) 0 else self.source[self.current + 1];
    }

    fn identifier(self: *Self) !void {
        while (isAlphaNumeric(self.peek())) _ = self.advance();

        const text = self.source[self.start..self.current];
        const token_type = self.keywords.get(text) orelse TT.IDENTIFIER;

        try self.addToken(token_type);
    }
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

fn isAlphaNumeric(c: u8) bool {
    return isDigit(c) or isAlpha(c);
}
