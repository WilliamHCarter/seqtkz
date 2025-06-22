const std = @import("std");
const kseq = @import("./kseq.zig");

const Command = enum {
    Comp,
    Fqchk,
    Hety,
    Gc,
    Subseq,
    Mutfa,
    Mergefa,
    Mergepe,
    Dropse,
    Randbase,
    CutN,
    Gap,
    Listhet,
    Famask,
    Trimfq,
    Hrun,
    Sample,
    Seq,
    Kfreq,
    Rename,
    Split,
    Hpc,
    Size,
    Telo,
    Help,
};

pub const CommandError = error{
    InvalidCommand,
    MissingArgument,
    CommandFailed,
    FileNotFound,
    InvalidArgument,
};

pub fn parseCommand(cmd: []const u8) !Command {
    const KV = struct { []const u8, Command };
    const map = std.StaticStringMap(Command).initComptime([_]KV{
        .{ "comp", .Comp },
        .{ "fqchk", .Fqchk },
        .{ "hety", .Hety },
        .{ "gc", .Gc },
        .{ "subseq", .Subseq },
        .{ "mutfa", .Mutfa },
        .{ "mergefa", .Mergefa },
        .{ "mergepe", .Mergepe },
        .{ "dropse", .Dropse },
        .{ "randbase", .Randbase },
        .{ "cutN", .CutN },
        .{ "gap", .Gap },
        .{ "listhet", .Listhet },
        .{ "famask", .Famask },
        .{ "trimfq", .Trimfq },
        .{ "hrun", .Hrun },
        .{ "sample", .Sample },
        .{ "seq", .Seq },
        .{ "kfreq", .Kfreq },
        .{ "rename", .Rename },
        .{ "split", .Split },
        .{ "hpc", .Hpc },
        .{ "size", .Size },
        .{ "telo", .Telo },
        .{ "help", .Help },
        .{ "--help", .Help },
        .{ "-h", .Help },
    });

    return map.get(cmd) orelse CommandError.InvalidCommand;
}

pub fn help() !void {
    const usage_text =
        \\
        \\Usage:   seqtk <command> <arguments>
        \\Version: 1.4-r132-dirty
        \\
        \\Command: seq       common transformation of FASTA/Q
        \\         size      report the number sequences and bases
        \\         comp      get the nucleotide composition of FASTA/Q
        \\         sample    subsample sequences
        \\         subseq    extract subsequences from FASTA/Q
        \\         fqchk     fastq QC (base/quality summary)
        \\         mergepe   interleave two PE FASTA/Q files
        \\         split     split one file into multiple smaller files
        \\         trimfq    trim FASTQ using the Phred algorithm
        \\
        \\         hety      regional heterozygosity
        \\         gc        identify high- or low-GC regions
        \\         mutfa     point mutate FASTA at specified positions
        \\         mergefa   merge two FASTA/Q files
        \\         famask    apply a X-coded FASTA to a source FASTA
        \\         dropse    drop unpaired from interleaved PE FASTA/Q
        \\         rename    rename sequence names
        \\         randbase  choose a random base from hets
        \\         cutN      cut sequence at long N
        \\         gap       get the gap locations
        \\         listhet   extract the position of each het
        \\         hpc       homopolyer-compressed sequence
        \\         telo      identify telomere repeats in asm or long reads
        \\
        \\
    ;

    std.debug.print("{s}", .{usage_text});
}

// Command implementations
pub fn comp(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement nucleotide composition
}

pub fn fqchk(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement fastq QC
}

pub fn hety(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement regional heterozygosity
}

pub fn gc(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement GC region identification
}

pub fn subseq(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement subsequence extraction
}

pub fn mutfa(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement point mutation
}

pub fn mergefa(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement FASTA/Q merging
}

pub fn mergepe(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement PE file interleaving
}

pub fn dropse(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    if (args.len == 0) {
        // Check if stdin is a terminal
        if (std.io.getStdIn().isTty()) {
            std.debug.print("Usage: seqtk dropse <in.fq>\n", .{});
            return CommandError.InvalidArgument;
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
            try copySequence(&last, &current);
            has_last = true;
            continue;
        }

        const is_pair = isPairedSequence(&last, &current);
        if (!is_pair) {
            try copySequence(&last, &current);
            continue;
        }

        // Output both sequences
        try writeSequence(writer, &last);
        try writeSequence(writer, &current);
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

pub fn randbase(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement random base selection
}

pub fn cutN(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement N cutting
}

pub fn gap(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    var min_size: usize = 50;

    var i: usize = 0;
    while (i < args.len and args[i][0] == '-') : (i += 1) {
        if (std.mem.eql(u8, args[i], "-l")) {
            i += 1;
            if (i >= args.len) return CommandError.MissingArgument;
            min_size = std.fmt.parseInt(usize, args[i], 10) catch return CommandError.InvalidArgument;
        } else {
            return CommandError.InvalidArgument;
        }
    }

    if (i < args.len) {
        const file = std.fs.cwd().openFile(args[i], .{}) catch return error.FileNotFound;
        defer file.close();
        return gapImpl(allocator, file.reader(), std.io.getStdOut().writer(), min_size) catch error.CommandFailed;
    } else if (!std.io.getStdIn().isTty()) {
        return gapImpl(allocator, std.io.getStdIn().reader(), std.io.getStdOut().writer(), min_size) catch error.CommandFailed;
    } else {
        std.debug.print("Usage: seqtk gap [-l 50] <in.fa>\n", .{});
        return CommandError.InvalidArgument;
    }
}

fn gapImpl(allocator: std.mem.Allocator, reader: anytype, writer: anytype, min_size: usize) !void {
    var seq_reader = kseq.FastaReader(@TypeOf(reader)).init(reader, allocator);
    var sequence = kseq.Sequence.init(allocator);
    defer sequence.deinit();

    while (try seq_reader.readSequence(&sequence)) {
        var i: usize = 0;
        while (i < sequence.sequence.items.len) {
            // Skip non-gap characters
            while (i < sequence.sequence.items.len and !isGapChar(sequence.sequence.items[i])) : (i += 1) {}

            if (i >= sequence.sequence.items.len) break;

            // Found gap start
            const start = i;
            while (i < sequence.sequence.items.len and isGapChar(sequence.sequence.items[i])) : (i += 1) {}

            // Report if gap is large enough
            if (i - start >= min_size) {
                try writer.print("{s}\t{d}\t{d}\n", .{ sequence.name.items, start, i });
            }
        }
    }
}

fn isGapChar(c: u8) bool {
    return switch (c) {
        'A', 'a', 'C', 'c', 'G', 'g', 'T', 't' => false,
        else => true,
    };
}

pub fn listhet(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement het position extraction
}

pub fn famask(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement FASTA masking
}

pub fn trimfq(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement FASTQ trimming
}

pub fn hrun(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement homopolymer run analysis
}

pub fn sample(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement sequence subsampling
}

pub fn seq(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement common FASTA/Q transformations
}

pub fn kfreq(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement k-mer frequency analysis
}

pub fn rename(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement sequence renaming
}

pub fn split(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement file splitting
}

pub fn hpc(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    if (args.len == 0) {
        // Read from stdin, write to stdout
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();
        return hpcImpl(allocator, stdin, stdout) catch error.CommandFailed;
    } else {
        // TODO: Handle file input/output
        return CommandError.InvalidArgument;
    }
}

fn hpcImpl(allocator: std.mem.Allocator, reader: anytype, writer: anytype) !void {
    var seq_reader = kseq.FastaReader(@TypeOf(reader)).init(reader, allocator);
    var sequence = kseq.Sequence.init(allocator);
    defer sequence.deinit();

    while (try seq_reader.readSequence(&sequence)) {
        if (sequence.sequence.items.len == 0) continue;

        try writer.print(">{s}\n", .{sequence.name.items});

        var last_char: ?u8 = null;
        for (sequence.sequence.items) |char| {
            if (last_char == null or char != last_char.?) {
                try writer.writeByte(char);
                last_char = char;
            }
        }
        try writer.writeByte('\n');
    }
}

pub fn size(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    if (args.len == 0) {
        // Read from stdin, write to stdout
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();
        return sizeImpl(allocator, stdin, stdout) catch error.CommandFailed;
    } else {
        // TODO: Handle file input/output
        return CommandError.InvalidArgument;
    }
}

fn sizeImpl(allocator: std.mem.Allocator, reader: anytype, writer: anytype) !void {
    var seq_reader = kseq.FastaReader(@TypeOf(reader)).init(reader, allocator);
    var sequence = kseq.Sequence.init(allocator);
    defer sequence.deinit();

    var seq_count: u64 = 0;
    var length: u64 = 0;

    while (try seq_reader.readSequence(&sequence)) {
        seq_count += 1;
        length += sequence.sequence.items.len;
    }

    try writer.print("{}\t{}\n", .{ seq_count, length });
}

pub fn telo(args: []const []const u8, allocator: std.mem.Allocator) CommandError!void {
    _ = args;
    _ = allocator;
    // TODO: Implement telomere repeat identification
}

//============================== Helper Function ==============================
fn copySequence(dest: *kseq.Sequence, src: *const kseq.Sequence) !void {
    dest.name.clearRetainingCapacity();
    dest.comment.clearRetainingCapacity();
    dest.sequence.clearRetainingCapacity();
    dest.quality.clearRetainingCapacity();

    try dest.name.appendSlice(src.name.items);
    try dest.comment.appendSlice(src.comment.items);
    try dest.sequence.appendSlice(src.sequence.items);
    try dest.quality.appendSlice(src.quality.items);
    dest.is_fastq = src.is_fastq;
}

fn writeSequence(writer: anytype, sequence: *const kseq.Sequence) !void {
    if (sequence.is_fastq) {
        // Write FASTQ format
        try writer.writeByte('@');
        try writer.writeAll(sequence.name.items);
        if (sequence.comment.items.len > 0) {
            try writer.writeByte(' ');
            try writer.writeAll(sequence.comment.items);
        }
        try writer.writeByte('\n');
        try writer.writeAll(sequence.sequence.items);
        try writer.writeAll("\n+\n");
        try writer.writeAll(sequence.quality.items);
        try writer.writeByte('\n');
    } else {
        // Write FASTA format
        try writer.writeByte('>');
        try writer.writeAll(sequence.name.items);
        if (sequence.comment.items.len > 0) {
            try writer.writeByte(' ');
            try writer.writeAll(sequence.comment.items);
        }
        try writer.writeByte('\n');
        try writer.writeAll(sequence.sequence.items);
        try writer.writeByte('\n');
    }
}
