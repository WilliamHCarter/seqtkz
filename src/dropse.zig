const std = @import("std");
const kseq = @import("./kseq.zig");
const cmd = @import("./commands.zig");

pub fn dropse(args: []const []const u8, allocator: std.mem.Allocator) cmd.CommandError!void {
    if (args.len == 0) {
        // Check if stdin is a terminal
        if (std.io.getStdIn().isTty()) {
            std.debug.print("Usage: seqtk dropse <in.fq>\n", .{});
            return cmd.CommandError.InvalidArgument;
        }
        // Read from stdin, write to stdout
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();
        return dropseImpl(allocator, stdin, stdout) catch error.CommandFailed;
    } else {
        // TODO: Handle file input
        const file = std.fs.cwd().openFile(args[0], .{}) catch return error.FileNotFound;
        defer file.close();
        const stdout = std.io.getStdOut().writer();
        return dropseImpl(allocator, file.reader(), stdout) catch error.CommandFailed;
    }
}

fn dropseImpl(allocator: std.mem.Allocator, reader: anytype, writer: anytype) !void {
    var seq_reader = kseq.FastaReader(@TypeOf(reader)).init(reader, allocator);
    var last = kseq.Sequence.init(allocator);
    defer last.deinit();
    var current = kseq.Sequence.init(allocator);
    defer current.deinit();
    var has_last = false;

    while (try seq_reader.readSequence(&current)) {
        if (!has_last) {
            try cmd.copySequence(&last, &current);
            has_last = true;
            continue;
        }

        const is_pair = isPairedSequence(&last, &current);
        if (!is_pair) {
            try cmd.copySequence(&last, &current);
            continue;
        }

        // Output both sequences
        try cmd.writeSequence(writer, &last);
        try cmd.writeSequence(writer, &current);
        has_last = false;
    }
}

//dropse helper
fn isPairedSequence(seq1: *const kseq.Sequence, seq2: *const kseq.Sequence) bool {
    const name1 = seq1.name.items;
    const name2 = seq2.name.items;

    if (name1.len != name2.len) return false;

    // Check if names end with /1 and /2 (or similar pattern)
    var compare_len = name1.len;
    if (name1.len > 2 and
        name1[name1.len - 2] == '/' and
        name2[name2.len - 2] == '/' and
        std.ascii.isDigit(name1[name1.len - 1]) and
        std.ascii.isDigit(name2[name2.len - 1]))
    {
        compare_len = name1.len - 2;
    }

    return std.mem.eql(u8, name1[0..compare_len], name2[0..compare_len]);
}
