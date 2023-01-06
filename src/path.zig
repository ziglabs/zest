const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub const PathError = error{
    InvalidPath,
};

pub fn parse(path: []const u8) PathError![]const u8 {
    if (path.len == 0) return PathError.InvalidPath;
    if (path[0] != '/') return PathError.InvalidPath;
    if (path.len > 1 and path[path.len - 1] == '/') return PathError.InvalidPath;

    for (path) |char| {
        if (!isUnreserved(char) and char != '/') return PathError.InvalidPath;
    }
    return path;
}

fn isUnreserved(char: u8) bool {
    return std.ascii.isAlNum(char) or switch (char) {
        '-', '.', '_', '~' => true,
        else => false,
    };
}

test "valid paths" {
    try expectEqualStrings(try parse("/"), "/");
    try expectEqualStrings(try parse("/hello"), "/hello");
    try expectEqualStrings(try parse("/heLLo-1/there.9_kj~"), "/heLLo-1/there.9_kj~");
}

test "invalid paths" {
    const expected_error = PathError.InvalidPath;
    try expectError(expected_error, parse("//"));
    try expectError(expected_error, parse("/hi/"));
    try expectError(expected_error, parse(""));
    try expectError(expected_error, parse("/he /d"));
}
