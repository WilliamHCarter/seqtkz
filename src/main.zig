const std = @import("std");
const kseq = @import("./kseq.zig");
const commands = @import("commands.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const err = gpa.deinit();
        if (err == .leak) std.debug.print("Memory leaks detected: {}\n", .{err});
    }

    seqtk(allocator) catch |err| {
        const stderr = std.io.getStdErr().writer();
        switch (err) {
            error.InvalidCommand => stderr.print("Invalid command. Use 'seqtk help' to see available commands.\n", .{}) catch {},
            error.MissingArgument => stderr.print("Missing argument for the command. Use 'seqtk help' for usage information.\n", .{}) catch {},
            error.CommandFailed => stderr.print("Command execution failed. Please check your input and try again.\n", .{}) catch {},
            error.OutOfMemory => stderr.print("Out of memory. Try closing other applications or increasing available memory.\n", .{}) catch {},
            error.AccessDenied => stderr.print("Access denied. Try running the program with higher privileges.\n", .{}) catch {},
            error.InvalidArgument => stderr.print("Invalid argument provided. Use 'seqtk help' for usage information.\n", .{}) catch {},
            error.FileNotFound => stderr.print("Input file not found. Please check the file path.\n", .{}) catch {},
            else => stderr.print("An unexpected error occurred. Please report this issue.\n", .{}) catch {},
        }
        stderr.print("Error: {s}\n", .{@errorName(err)}) catch {};
        std.process.exit(1);
    };
}

fn seqtk(allocator: std.mem.Allocator) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) return try commands.help();

    const cmd = commands.parseCommand(args[1]) catch |err| switch (err) {
        else => {
            std.debug.print("[main] unrecognized command '{s}'. Abort!\n", .{args[1]});
            return error.InvalidCommand;
        },
    };

    const remaining_args = if (args.len > 2) args[2..] else &[_][]const u8{};

    switch (cmd) {
        .Comp => try commands.comp(remaining_args, allocator),
        .Fqchk => try commands.fqchk(remaining_args, allocator),
        .Hety => try commands.hety(remaining_args, allocator),
        .Gc => try commands.gc(remaining_args, allocator),
        .Subseq => try commands.subseq(remaining_args, allocator),
        .Mutfa => try commands.mutfa(remaining_args, allocator),
        .Mergefa => try commands.mergefa(remaining_args, allocator),
        .Mergepe => try commands.mergepe(remaining_args, allocator),
        .Dropse => try commands.dropse(remaining_args, allocator),
        .Randbase => try commands.randbase(remaining_args, allocator),
        .CutN => try commands.cutN(remaining_args, allocator),
        .Gap => try commands.gap(remaining_args, allocator),
        .Listhet => try commands.listhet(remaining_args, allocator),
        .Famask => try commands.famask(remaining_args, allocator),
        .Trimfq => try commands.trimfq(remaining_args, allocator),
        .Hrun => try commands.hrun(remaining_args, allocator),
        .Sample => try commands.sample(remaining_args, allocator),
        .Seq => try commands.seq(remaining_args, allocator),
        .Kfreq => try commands.kfreq(remaining_args, allocator),
        .Rename => try commands.rename(remaining_args, allocator),
        .Split => try commands.split(remaining_args, allocator),
        .Hpc => try commands.hpc(remaining_args, allocator),
        .Size => try commands.size(remaining_args, allocator),
        .Telo => try commands.telo(remaining_args, allocator),
        .Help => try commands.help(),
    }
}

//============================================================
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
