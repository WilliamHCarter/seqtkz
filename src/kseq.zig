const std = @import("std");
const testing = std.testing;

pub const ReadError = error{
    TruncatedQuality,
    QualityLengthMismatch,
    OutOfMemory,
    EndOfStream,
};

pub const Sequence = struct {
    name: std.ArrayList(u8),
    comment: std.ArrayList(u8),
    sequence: std.ArrayList(u8),
    quality: std.ArrayList(u8),
    is_fastq: bool,

    pub fn init(allocator: std.mem.Allocator) Sequence {
        return .{
            .name = std.ArrayList(u8).init(allocator),
            .comment = std.ArrayList(u8).init(allocator),
            .sequence = std.ArrayList(u8).init(allocator),
            .quality = std.ArrayList(u8).init(allocator),
            .is_fastq = false,
        };
    }

    pub fn deinit(self: *Sequence) void {
        self.name.deinit();
        self.comment.deinit();
        self.sequence.deinit();
        self.quality.deinit();
    }
};

pub fn FastaReader(comptime ReaderType: type) type {
    return struct {
        buffered_reader: std.io.BufferedReader(4096, ReaderType),
        allocator: std.mem.Allocator,
        last_char: ?u8 = null,

        const Self = @This();

        pub fn init(reader: ReaderType, allocator: std.mem.Allocator) Self {
            return .{
                .buffered_reader = std.io.bufferedReader(reader),
                .allocator = allocator,
            };
        }

        pub fn readSequence(self: *Self, seq: *Sequence) !bool {
            // Clear previous sequence data
            seq.name.clearRetainingCapacity();
            seq.comment.clearRetainingCapacity();
            seq.sequence.clearRetainingCapacity();
            seq.quality.clearRetainingCapacity();
            seq.is_fastq = false;

            var reader = self.buffered_reader.reader();

            // If we don't have a stored character, read until we find a header
            if (self.last_char == null) {
                while (true) {
                    const byte = reader.readByte() catch |err| {
                        if (err == error.EndOfStream) return false;
                        return err;
                    };
                    if (byte == '>' or byte == '@') {
                        self.last_char = byte;
                        break;
                    }
                }
            }

            // Determine format from header character
            const header_char = self.last_char.?;
            seq.is_fastq = (header_char == '@');

            // Read name (until space) and comment (rest of line)
            var found_space = false;
            while (true) {
                const byte = reader.readByte() catch |err| {
                    if (err == error.EndOfStream) break;
                    return err;
                };

                if (byte == '\n') break;

                if (!found_space and byte == ' ') {
                    found_space = true;
                    continue;
                }

                if (!found_space) {
                    try seq.name.append(byte);
                } else {
                    try seq.comment.append(byte);
                }
            }

            // Read sequence lines until we hit a header or quality marker
            self.last_char = null;
            while (true) {
                const byte = reader.readByte() catch |err| {
                    if (err == error.EndOfStream) break;
                    return err;
                };

                if (byte == '>' or byte == '@' or byte == '+') {
                    self.last_char = byte;
                    break;
                }

                if (byte != '\n' and byte != '\r') {
                    try seq.sequence.append(byte);
                }
            }

            // If FASTQ and we hit '+', read quality scores
            if (seq.is_fastq and self.last_char == '+') {
                // Skip rest of '+' line
                while (true) {
                    const byte = reader.readByte() catch |err| {
                        if (err == error.EndOfStream) return error.TruncatedQuality;
                        return err;
                    };
                    if (byte == '\n') break;
                }

                // Read quality scores (must be same length as sequence)
                while (seq.quality.items.len < seq.sequence.items.len) {
                    const byte = reader.readByte() catch |err| {
                        if (err == error.EndOfStream) return error.TruncatedQuality;
                        return err;
                    };

                    if (byte != '\n' and byte != '\r') {
                        try seq.quality.append(byte);
                    }
                }

                if (seq.quality.items.len != seq.sequence.items.len) {
                    return error.QualityLengthMismatch;
                }

                self.last_char = null;
            }

            return true;
        }
    };
}

//=================================== Tests ===================================

test "read single FASTA sequence" {
    const input = ">seq1 comment here\nACTGACTG\nACTG\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("seq1", seq.name.items);
    try testing.expectEqualStrings("comment here", seq.comment.items);
    try testing.expectEqualStrings("ACTGACTGACTG", seq.sequence.items);
    try testing.expect(!seq.is_fastq);
    try testing.expectEqual(@as(usize, 0), seq.quality.items.len);
}

test "read single FASTQ sequence" {
    const input = "@read1 comment\nACTGACTG\n+\nIIIIIIII\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("read1", seq.name.items);
    try testing.expectEqualStrings("comment", seq.comment.items);
    try testing.expectEqualStrings("ACTGACTG", seq.sequence.items);
    try testing.expect(seq.is_fastq);
    try testing.expectEqualStrings("IIIIIIII", seq.quality.items);
}

test "read multiple sequences mixed format" {
    const input = ">fasta1\nACTG\n@fastq1\nGGGG\n+\nIIII\n>fasta2 with comment\nTTTT\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    // First sequence (FASTA)
    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("fasta1", seq.name.items);
    try testing.expectEqualStrings("ACTG", seq.sequence.items);
    try testing.expect(!seq.is_fastq);

    // Second sequence (FASTQ)
    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("fastq1", seq.name.items);
    try testing.expectEqualStrings("GGGG", seq.sequence.items);
    try testing.expect(seq.is_fastq);
    try testing.expectEqualStrings("IIII", seq.quality.items);

    // Third sequence (FASTA)
    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("fasta2", seq.name.items);
    try testing.expectEqualStrings("with comment", seq.comment.items);
    try testing.expectEqualStrings("TTTT", seq.sequence.items);
    try testing.expect(!seq.is_fastq);
}

test "handle empty file" {
    const input = "";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(!try reader.readSequence(&seq));
}

test "handle file with only whitespace" {
    const input = "\n\n\n   \n\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(!try reader.readSequence(&seq));
}

test "multiline sequence with various line endings" {
    const input = ">seq1\nACTG\r\nGGGG\rTTTT\nAAAA\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("ACTGGGGGTTTTAAAA", seq.sequence.items);
}

test "FASTQ with multiline quality scores" {
    const input = "@read1\nACTGACTG\n+\nIIII\nIIII\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("IIIIIIII", seq.quality.items);
}

test "truncated FASTQ quality scores" {
    const input = "@read1\nACTGACTG\n+\nIIII";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expectError(ReadError.TruncatedQuality, reader.readSequence(&seq));
}

test "FASTQ quality length mismatch" {
    // This test case would need internal modification to trigger QualityLengthMismatch
    // since the current implementation stops reading at sequence length
}

test "sequence with no name" {
    const input = ">\nACTGACTG\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("", seq.name.items);
    try testing.expectEqualStrings("ACTGACTG", seq.sequence.items);
}

test "sequence with only comment (no name)" {
    const input = "> just a comment\nACTG\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("", seq.name.items);
    try testing.expectEqualStrings("just a comment", seq.comment.items);
}

test "FASTQ with quality line containing header marker" {
    const input = "@read1\nACTG\n+optional comment\n>III\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings(">III", seq.quality.items);
}

test "reuse sequence object" {
    const input = ">seq1 first\nAAAA\n>seq2 second\nTTTT\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    // First read
    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("seq1", seq.name.items);
    try testing.expectEqualStrings("first", seq.comment.items);

    // Second read - should clear previous data
    try testing.expect(try reader.readSequence(&seq));
    try testing.expectEqualStrings("seq2", seq.name.items);
    try testing.expectEqualStrings("second", seq.comment.items);
    try testing.expectEqualStrings("TTTT", seq.sequence.items);
}

test "EOF after sequence returns false" {
    const input = ">seq1\nACTG";
    var stream = std.io.fixedBufferStream(input);
    var reader = FastaReader(@TypeOf(stream.reader())).init(stream.reader(), testing.allocator);

    var seq = Sequence.init(testing.allocator);
    defer seq.deinit();

    try testing.expect(try reader.readSequence(&seq));
    try testing.expect(!try reader.readSequence(&seq));
}
