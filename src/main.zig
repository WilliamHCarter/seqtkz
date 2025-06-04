const std = @import("std");

// Error types
const UsageError = error{NoCommandProvided};
const CommandError = error{ InvalidCommand, CommandFailed };

const CommandFn = fn ([][]const u8) CommandError!void;

const commands = std.StaticStringMap(CommandFn).initComptime(.{
    .{ "comp", stk_comp },
    .{ "fqchk", stk_fqchk },
    .{ "hety", stk_hety },
    .{ "gc", stk_gc },
    .{ "subseq", stk_subseq },
    .{ "mutfa", stk_mutfa },
    .{ "mergefa", stk_mergefa },
    .{ "mergepe", stk_mergepe },
    .{ "dropse", stk_dropse },
    .{ "randbase", stk_randbase },
    .{ "cutN", stk_cutN },
    .{ "gap", stk_gap },
    .{ "listhet", stk_listhet },
    .{ "famask", stk_famask },
    .{ "trimfq", stk_trimfq },
    .{ "hrun", stk_hrun },
    .{ "sample", stk_sample },
    .{ "seq", stk_seq },
    .{ "kfreq", stk_kfreq },
    .{ "rename", stk_rename },
    .{ "split", stk_split },
    .{ "hpc", stk_hpc },
    .{ "size", stk_size },
    .{ "telo", stk_telo },
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        usage() catch |err| switch (err) {
            UsageError.NoCommandProvided => std.process.exit(1),
        };
        return;
    }

    const command = args[1];
    const remaining_args = args[1..];

    if (commands.get(command)) |command_fn| {
        command_fn(remaining_args) catch |err| switch (err) {
            CommandError.InvalidCommand, CommandError.CommandFailed => {
                std.debug.print("Command '{s}' failed\n", .{command});
                std.process.exit(1);
            },
        };
    } else {
        std.debug.print("[main] unrecognized command '{s}'. Abort!\n", .{command});
        std.process.exit(1);
    }
}

fn usage() UsageError!void {
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
    return UsageError.NoCommandProvided;
}

// Command implementations
fn stk_comp(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_fqchk(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_hety(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_gc(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_subseq(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_mutfa(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_mergefa(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_mergepe(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_dropse(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_randbase(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_cutN(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_gap(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_listhet(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_famask(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_trimfq(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_hrun(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_sample(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_seq(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_kfreq(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_rename(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_split(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_hpc(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_size(args: [][]const u8) CommandError!void {
    _ = args;
}
fn stk_telo(args: [][]const u8) CommandError!void {
    _ = args;
}

//============================================================++=====================
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
