const std = @import("std");

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


pub const FastaReader = struct {
    buffered_reader: std.io.BufferedReader(4096, anytype),
    allocator: std.mem.Allocator,
    last_char: ?u8 = null,

    pub fn init(reader: anytype, allocator: std.mem.Allocator) FastaReader {
        return .{
            .buffered_reader = std.io.bufferedReader(reader),
            .allocator = allocator,
        };
    }

    pub fn readSequence(self: *FastaReader, seq: *Sequence) !bool {
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
