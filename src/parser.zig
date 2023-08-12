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

    pub fn parse(self: *Self) !ast.Expr {
        return self.expression();
    }

    fn expression(self: *Self) !ast.Expr {
        return try self.equality();
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
        var expr = self.term();

        while (self.match(&[_]TT{ TT.GREATER, TT.GREATER_EQUAL, TT.LESS, TT.LESS_EQUAL })) {
            expr.Binary.operator = self.previous();
            expr.Binary.right = self.term();
        }

        return expr;
    }

    fn term(self: *Self) ast.Expr {
        var expr = self.factor();

        while (self.match(&[_]TT{ TT.MINUS, TT.PLUS })) {
            const operator = self.previous();
            const right = self.factor();
            expr = self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn factor(self: *Self) *ast.Expr {
        var expr = self.unary();

        while (self.match([]TT{ TT.STAR, TT.SLASH })) {
            const operator = self.previous();
            const right = self.unary();
            expr = self.ast.createBinary(expr, operator, right);
        }

        return expr;
    }

    fn unary(self: *Self) ast.Expr {
        if (match([]TT{ TT.BANG, TT.MINUS })) {
            const operator = self.previous();
            const right = self.unary();
            return self.ast.createUnary(operator, right);
        }

        return self.primary();
    }

    fn primary(self: *Self) ast.Expr {
        if (self.match([]TT{TT.FALSE})) return ast.Expr.Literal{ .Bool = false };
        if (self.match([]TT{TT.TRUE})) return ast.Expr.Literal{ .Bool = true };
        if (self.match([]TT{TT.NIL})) return ast.Expr.Literal{.Nil};
        if (self.match([]TT{ TT.NUMBER, TT.STRING })) return ast.Expr.Literal{ .Number = self.previous().literal.? };

        if (self.match([]TT{TT.LEFT_PAREN})) {
            const expr = self.expression();
            self.consume(TT.RIGHT_PAREN, "Expected ')' after expression.");
            return ast.Expr.initGrouping(expr);
        }

        return lox.err_from_token(self.peek(), "Expected expression.");
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

    fn consume(self: *Self, tok: token.Token, error_msg: []u8) token.Token {
        if (self.check(tok)) return self.advance();

        return lox.err_from_token(lox.IntepreterError.ParserError, self.peek(), error_msg);
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
        return self.tokens[self.current];
    }

    fn previous(self: *Self) token.Token {
        return self.tokens.items[self.current - 1];
    }
};
