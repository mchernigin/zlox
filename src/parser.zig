const std = @import("std");
const token = @import("token.zig");
const ast = @import("ast.zig");
const lox = @import("main.zig");

const TT = token.TokenType;

pub const Parser = struct {
    tokens: std.ArrayList(token.Token),
    ast: ast.Ast,
    current: u32 = 0,

    const Self = @This();

    pub fn init(tokens: std.ArrayList(token.Token)) Self {
        return .{ .tokens = tokens, .ast = ast.Ast.init() };
    }

    pub fn deinit(self: *Self) void {
        self.ast.deinit();
        self.* = undefined;
    }

    pub fn parse(self: *Self) ast.Expr {
        return self.expression();
    }

    fn expression(self: *Self) ast.Expr {
        return self.equality() catch unreachable;
    }

    fn equality(self: *Self) !ast.Expr {
        var expr = try self.comparison();

        while (self.match(&[_]TT{ TT.BANG_EQUAL, TT.EQUAL_EQUAL })) {
            const operator = self.previous();
            const right = try self.comparison();
            expr = try self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn comparison(self: *Self) !ast.Expr {
        var expr = try self.term();

        while (self.match(&[_]TT{ TT.GREATER, TT.GREATER_EQUAL, TT.LESS, TT.LESS_EQUAL })) {
            const operator = self.previous();
            const right = try self.factor();
            expr = try self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn term(self: *Self) !ast.Expr {
        var expr = try self.factor();

        while (self.match(&[_]TT{ TT.MINUS, TT.PLUS })) {
            const operator = self.previous();
            const right = try self.factor();
            expr = try self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn factor(self: *Self) !ast.Expr {
        var expr = try self.unary();

        while (self.match(&[_]TT{ TT.STAR, TT.SLASH })) {
            const operator = self.previous();
            const right = try self.unary();
            expr = try self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn unary(self: *Self) !ast.Expr {
        if (self.match(&[_]TT{ TT.BANG, TT.MINUS })) {
            const operator = self.previous();
            const right = try self.unary();
            return try self.ast.createUnary(operator, right);
        }

        return try self.primary();
    }

    fn primary(self: *Self) !ast.Expr {
        if (self.match(&[_]TT{TT.FALSE})) return ast.Expr{ .Literal = token.Literal{ .Bool = false } };
        if (self.match(&[_]TT{TT.TRUE})) return ast.Expr{ .Literal = token.Literal{ .Bool = true } };
        if (self.match(&[_]TT{TT.NIL})) return ast.Expr{ .Literal = token.Literal.Nil };
        if (self.match(&[_]TT{TT.NUMBER}))
            return ast.Expr{ .Literal = token.Literal{ .Number = self.previous().literal.?.Number } };
        if (self.match(&[_]TT{TT.STRING}))
            return ast.Expr{ .Literal = token.Literal{ .String = self.previous().literal.?.String } };

        if (self.match(&[_]TT{TT.LEFT_PAREN})) {
            const expr = self.expression();
            _ = try self.consume(TT.RIGHT_PAREN, "Expected ')' after expression.");
            return try self.ast.createGrouping(expr);
        }

        try lox.err_from_token(self.peek(), "Expected expression.");
        return lox.IntepreterError.ParserError;
    }

    fn match(self: *Self, token_types: []const TT) bool {
        for (token_types) |token_type| {
            if (self.check(token_type)) {
                _ = self.advance();
                return true;
            }
        }

        return false;
    }

    fn consume(self: *Self, token_type: TT, error_msg: [:0]const u8) !token.Token {
        if (self.check(token_type)) return self.advance();

        try lox.err_from_token(self.peek(), error_msg);
        return lox.IntepreterError.ParserError;
    }

    fn synchronize(self: *Self) void {
        self.advance();

        while (!self.isAtEnd()) {
            if (self.previous().token_type == TT.SEMICOLON) return;

            switch (self.peek().token_type) {
                TT.CLASS | TT.FUN | TT.VAR | TT.FOR | TT.IF | TT.WHILE | TT.PRINT | TT.RETURN => return,
                else => self.advance(),
            }
        }
    }

    fn check(self: *Self, token_type: TT) bool {
        if (self.isAtEnd()) return false;
        return self.peek().token_type == token_type;
    }

    fn advance(self: *Self) token.Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.previous();
    }

    fn isAtEnd(self: *Self) bool {
        return self.peek().token_type == TT.EOF;
    }

    fn peek(self: *Self) token.Token {
        return self.tokens.items[self.current];
    }

    fn previous(self: *Self) token.Token {
        return self.tokens.items[self.current - 1];
    }
};
