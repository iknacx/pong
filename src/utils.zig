const std = @import("std");

pub fn readFile(allocator: std.mem.Allocator, path: []const u8) ![:0]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    const size = try file.getEndPos();
    return try file.readToEndAllocOptions(allocator, size, null, @alignOf(u8), 0);
}
