const std = @import("std");
const testing = std.testing;
const kseq = @import("kseq.zig");
const commands = @import("commands.zig");

const TestConfig = struct {
    timeout_ms: u32 = 10000,
    verbose: bool = false,
    benchmark: bool = false,
    temp_dir: []const u8 = "test_tmp",
};

const TestResult = struct {
    passed: bool,
    seqtk_output: []u8,
    seqtkz_output: []u8,
    seqtk_time_ns: ?u64 = null,
    seqtkz_time_ns: ?u64 = null,
    allocator: std.mem.Allocator,

    fn deinit(self: *TestResult) void {
        self.allocator.free(self.seqtk_output);
        self.allocator.free(self.seqtkz_output);
    }

    fn printDiff(self: *TestResult) void {
        if (!self.passed) {
            std.debug.print("\n=== Output Mismatch ===\n", .{});
            std.debug.print("Expected (seqtk):\n{s}\n", .{self.seqtk_output});
            std.debug.print("Actual (seqtkz):\n{s}\n", .{self.seqtkz_output});
        }
    }
};

pub const TestHarness = struct {
    allocator: std.mem.Allocator,
    config: TestConfig,
    temp_dir: std.fs.Dir,

    pub fn init(allocator: std.mem.Allocator, config: TestConfig) !TestHarness {
        std.fs.cwd().makeDir(config.temp_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const temp_dir = try std.fs.cwd().openDir(config.temp_dir, .{});

        return TestHarness{
            .allocator = allocator,
            .config = config,
            .temp_dir = temp_dir,
        };
    }

    pub fn deinit(self: *TestHarness) void {
        self.temp_dir.close();
        std.fs.cwd().deleteTree(self.config.temp_dir) catch {};
    }

    pub fn compareCommand(self: *TestHarness, command: []const u8, args: []const []const u8, stdin_data: ?[]const u8) !TestResult {
        if (self.config.verbose) {
            std.debug.print("Testing command: {s}", .{command});
            for (args) |arg| {
                std.debug.print(" {s}", .{arg});
            }
            std.debug.print("\n", .{});
        }

        const seqtk_result = try self.runExternal("seqtk", command, args, stdin_data);
        defer self.allocator.free(seqtk_result.stdout);
        defer self.allocator.free(seqtk_result.stderr);

        const seqtkz_result = try self.runSeqtkz(command, args, stdin_data);
        defer self.allocator.free(seqtkz_result.stdout);
        defer self.allocator.free(seqtkz_result.stderr);

        const outputs_match = std.mem.eql(u8, seqtk_result.stdout, seqtkz_result.stdout);

        return TestResult{
            .passed = outputs_match,
            .seqtk_output = try self.allocator.dupe(u8, seqtk_result.stdout),
            .seqtkz_output = try self.allocator.dupe(u8, seqtkz_result.stdout),
            .seqtk_time_ns = seqtk_result.time_ns,
            .seqtkz_time_ns = seqtkz_result.time_ns,
            .allocator = self.allocator,
        };
    }

    const RunResult = struct {
        stdout: []u8,
        stderr: []u8,
        time_ns: ?u64,
    };

    fn runExternal(self: *TestHarness, exe_name: []const u8, command: []const u8, args: []const []const u8, stdin_data: ?[]const u8) !RunResult {
        var argv = std.ArrayList([]const u8).init(self.allocator);
        defer argv.deinit();

        try argv.append(exe_name);
        try argv.append(command);
        for (args) |arg| {
            try argv.append(arg);
        }

        const start_time = if (self.config.benchmark) std.time.nanoTimestamp() else 0;

        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = argv.items,
            .max_output_bytes = 10 * 1024 * 1024, // 10MB max
        });

        const end_time = if (self.config.benchmark) std.time.nanoTimestamp() else 0;
        const elapsed = if (self.config.benchmark) @as(u64, @intCast(end_time - start_time)) else null;

        // If stdin_data provided, use different approach
        if (stdin_data) |data| {
            const stdin_file = try self.temp_dir.createFile("stdin.tmp", .{});
            defer stdin_file.close();
            try stdin_file.writeAll(data);

            var child = std.process.Child.init(argv.items, self.allocator);
            child.stdin_behavior = .Pipe;
            child.stdout_behavior = .Pipe;
            child.stderr_behavior = .Pipe;

            try child.spawn();

            if (child.stdin) |stdin| {
                try stdin.writeAll(data);
                stdin.close();
            }

            const stdout = try child.stdout.?.reader().readAllAlloc(self.allocator, 10 * 1024 * 1024);
            const stderr = try child.stderr.?.reader().readAllAlloc(self.allocator, 1024 * 1024);

            _ = try child.wait();

            return RunResult{
                .stdout = stdout,
                .stderr = stderr,
                .time_ns = elapsed,
            };
        }

        return RunResult{
            .stdout = result.stdout,
            .stderr = result.stderr,
            .time_ns = elapsed,
        };
    }

    fn runSeqtkz(self: *TestHarness, command: []const u8, args: []const []const u8, stdin_data: ?[]const u8) !RunResult {
        return self.runExternal("./zig-out/bin/seqtkz", command, args, stdin_data);
    }

    pub fn generateFasta(self: *TestHarness, num_sequences: usize, seq_length: usize) ![]u8 {
        var buffer = std.ArrayList(u8).init(self.allocator);
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        const random = prng.random();

        const bases = "ACGT";

        var i: usize = 0;
        while (i < num_sequences) : (i += 1) {
            try buffer.writer().print(">seq_{d} test sequence\n", .{i});

            var j: usize = 0;
            while (j < seq_length) : (j += 1) {
                if (j > 0 and j % 80 == 0) {
                    try buffer.append('\n');
                }
                const base = bases[random.intRangeAtMost(usize, 0, 3)];
                try buffer.append(base);
            }
            try buffer.append('\n');
        }

        return buffer.toOwnedSlice();
    }

    pub fn generateFastq(self: *TestHarness, num_sequences: usize, seq_length: usize) ![]u8 {
        var buffer = std.ArrayList(u8).init(self.allocator);
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        const random = prng.random();

        const bases = "ACGT";

        var i: usize = 0;
        while (i < num_sequences) : (i += 1) {
            try buffer.writer().print("@read_{d} test read\n", .{i});

            var j: usize = 0;
            while (j < seq_length) : (j += 1) {
                const base = bases[random.intRangeAtMost(usize, 0, 3)];
                try buffer.append(base);
            }
            try buffer.append('\n');
            try buffer.append('+');
            try buffer.append('\n');

            // Generate quality scores
            j = 0;
            while (j < seq_length) : (j += 1) {
                const qual = @as(u8, @intCast(random.intRangeAtMost(u8, 33, 73))); // Phred+33
                try buffer.append(qual);
            }
            try buffer.append('\n');
        }

        return buffer.toOwnedSlice();
    }
};

test "hpc command with simple FASTA" {
    const allocator = testing.allocator;
    var harness = try TestHarness.init(allocator, .{});
    defer harness.deinit();

    const test_data =
        \\>seq1
        \\AAAACCCCGGGGTTTT
        \\>seq2
        \\AAAAAAAACCCCCCCCGGGGGGGGTTTTTTTT
        \\
    ;

    var result = try harness.compareCommand("hpc", &.{}, test_data);
    defer result.deinit();

    try testing.expect(result.passed);
}

test "size command with mixed sequences" {
    const allocator = testing.allocator;
    var harness = try TestHarness.init(allocator, .{});
    defer harness.deinit();

    const test_data =
        \\>seq1
        \\ACTG
        \\>seq2
        \\ACTGACTG
        \\>seq3
        \\ACTGACTGACTG
        \\
    ;

    var result = try harness.compareCommand("size", &.{}, test_data);
    defer result.deinit();

    if (!result.passed) {
        result.printDiff();
    }
    try testing.expect(result.passed);
}

test "size command with FASTQ" {
    const allocator = testing.allocator;
    var harness = try TestHarness.init(allocator, .{});
    defer harness.deinit();

    const test_data =
        \\@read1
        \\ACTG
        \\+
        \\IIII
        \\@read2
        \\ACTGACTG
        \\+
        \\IIIIIIII
        \\
    ;

    var result = try harness.compareCommand("size", &.{}, test_data);
    defer result.deinit();

    if (!result.passed) {
        result.printDiff();
    }
    try testing.expect(result.passed);
}

test "benchmark hpc with large file" {
    const allocator = testing.allocator;
    var harness = try TestHarness.init(allocator, .{ .benchmark = true, .verbose = true });
    defer harness.deinit();

    const test_data = try harness.generateFasta(1000, 1000);
    defer allocator.free(test_data);

    var result = try harness.compareCommand("hpc", &.{}, test_data);
    defer result.deinit();

    try testing.expect(result.passed);

    if (result.seqtk_time_ns != null and result.seqtkz_time_ns != null) {
        const seqtk_ms = @as(f64, @floatFromInt(result.seqtk_time_ns.?)) / 1_000_000.0;
        const seqtkz_ms = @as(f64, @floatFromInt(result.seqtkz_time_ns.?)) / 1_000_000.0;
        const speedup = seqtk_ms / seqtkz_ms;

        std.debug.print("\nPerformance comparison:\n", .{});
        std.debug.print("  seqtk:  {d:.2} ms\n", .{seqtk_ms});
        std.debug.print("  seqtkz: {d:.2} ms\n", .{seqtkz_ms});
        std.debug.print("  Speedup: {d:.2}x\n", .{speedup});
    }
}

test "hpc property: output never longer than input" {
    const allocator = testing.allocator;
    var harness = try TestHarness.init(allocator, .{});
    defer harness.deinit();

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const test_data = try harness.generateFasta(10, 100);
        defer allocator.free(test_data);

        var result = try harness.compareCommand("hpc", &.{}, test_data);
        defer result.deinit();

        // Property: HPC output should always be shorter or equal length
        try testing.expect(result.seqtkz_output.len <= test_data.len);
    }
}
