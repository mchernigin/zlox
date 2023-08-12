const std = @import("std");
const token = @import("token.zig");

pub const Ast = struct {
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init() Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        return .{
            .arena = arena,
            .allocator = arena.allocator(),
        };
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
        self.* = undefined;
    }

    pub fn createBinary(self: *Self, left: *Expr, operator: token.Token, right: *Expr) !Expr {
        const new_binary: *Binary = try self.allocator.create(Binary);
        new_binary.* = Binary{ .left = left, .operator = operator, .right = right };
        return .{ .Binary = new_binary };
    }

    pub fn createUnary(self: *Self, operator: token.Token, right: Expr) !Expr {
        const new_unary: *Unary = try self.allocator.create(Unary);
        new_unary.* = Unary{ .operator = operator, .right = right };
        return .{ .Unary = new_unary };
    }

    pub fn createGrouping(self: *Self, inner: Expr) !Expr {
        const new_grouping: *Unary = try self.allocator.create(Unary);
        new_grouping.* = Grouping{ .inner = inner };
        return .{ .Grouping = new_grouping };
    }
};

pub const Expr = union(enum) {
    Binary: *Binary,
    Unary: *Unary,
    Literal: *token.Literal,
    Grouping: *Grouping,
};

pub const Binary = struct {
    left: *Expr,
    operator: token.Token,
    right: *Expr,
};

pub const Unary = struct {
    operator: token.Token,
    right: *Expr,
};

pub const Grouping = struct {
    inner: *Expr,
};
