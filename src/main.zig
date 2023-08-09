const std = @import("std");
const token = @import("token.zig");
const scanner = @import("lexer.zig");

pub fn main() !u8 {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len > 2) {
        const stderr = std.io.getStdErr().writer();
        try stderr.writeAll("Error: too many arguments\n");
        try stderr.print("Usage: {s} [script]\n", .{args[0]});
        return 2;
    } else if (args.len == 2) {
        try runFile(args[1], gpa);
    } else {
        try runPrompt(gpa);
    }

    return 0;
}

pub const IntepreterError = error{LexerError};

fn runFile(filename: [:0]const u8, allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const file_size_limit = 1024 * 1024;
    var file_content = try file.readToEndAlloc(allocator, file_size_limit);

    try run(file_content, allocator);
}

fn runPrompt(allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var buf: [1024]u8 = undefined;

    while (true) {
        try stdout.print("lox> ", .{});
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |user_input| {
            try run(user_input, allocator);
        } else {
            break;
        }
    }
}

fn run(source_code: []const u8, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();

    var scnnr: scanner.Scanner = try scanner.Scanner.init(source_code, allocator);
    defer scnnr.deinit();

    const tokens = try scnnr.scanTokens();

    for (tokens.items) |tok| {
        try stdout.print("{any}\n", .{tok});
    }
}

pub fn err(line: u32, message: [:0]const u8) !void {
    try report(line, "", message);
}

fn report(line: u32, location: [:0]const u8, message: [:0]const u8) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("[line {d}] Error{s}: {s}\n", .{ line, location, message });
    return IntepreterError.LexerError;
}
