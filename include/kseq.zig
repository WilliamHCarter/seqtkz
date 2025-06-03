const std = @import("std");

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
