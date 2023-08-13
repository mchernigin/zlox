const token = @import("token.zig");

const std = @import("std");

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

    pub fn createBinary(self: *Self, left: Expr, operator: token.Token, right: Expr) !Expr {
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
        const new_grouping: *Grouping = try self.allocator.create(Grouping);
        new_grouping.* = Grouping{ .inner = inner };
        return .{ .Grouping = new_grouping };
    }
};

pub const Expr = union(enum) {
    Binary: *Binary,
    Unary: *Unary,
    Literal: token.Literal,
    Grouping: *Grouping,

    const Self = @This();

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        switch (self) {
            inline .Binary => |b| try writer.print("({any} {any} {any})", .{ b.operator, b.left, b.right }),
            inline .Unary => |u| try writer.print("({any} {any})", .{ u.operator, u.right }),
            inline .Literal => |l| try writer.print("{any}", .{l}),
            inline .Grouping => |g| try writer.print("({any})", .{g.inner}),
        }
    }
};

pub const Binary = struct {
    left: Expr,
    operator: token.Token,
    right: Expr,
};

pub const Unary = struct {
    operator: token.Token,
    right: Expr,
};

pub const Grouping = struct {
    inner: Expr,
};
