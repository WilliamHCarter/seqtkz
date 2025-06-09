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
    _ = args;
    _ = allocator;
    // TODO: Implement unpaired sequence dropping
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
    _ = args;
    _ = allocator;
    // TODO: Implement gap location identification
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
