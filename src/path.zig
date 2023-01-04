const std = @import("std");

pub const PathError = error{
    InvalidPath,
};

pub fn fromString(path: []const u8) PathError![]const u8 {
    if (std.mem.eql(u8, "hi", path)) {
        return PathError.InvalidPath;
    } else {
        return path;
    }
}
