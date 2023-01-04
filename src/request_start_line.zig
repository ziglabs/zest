const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const method = @import("method.zig");
const path = @import("path.zig");
const version = @import("version.zig");

pub const RequestStartLineError = error{
    MissingMethod,
    MissingPath,
    MissingVersion,
    InvalidStartLine,
};

pub const Error = RequestStartLineError || method.MethodError || path.PathError || version.VersionError;

pub const RequestStartLine = struct {
    method: method.Method,
    path: []const u8,
    version: version.Version,
};

pub fn parse(start_line: []const u8) Error!RequestStartLine {
    var iterator = std.mem.split(u8, start_line, " ");
    var slice = iterator.first();

    const parsed_method = try method.Method.fromString(slice);

    slice = if (iterator.next()) |s| s else return RequestStartLineError.MissingPath;

    const parsed_path = try path.fromString(slice);

    slice = if (iterator.next()) |s| s else return RequestStartLineError.MissingVersion;

    const parsed_version = try version.fromString(slice);

    if (iterator.next() != null) {
        return RequestStartLineError.InvalidStartLine;
    }

    return RequestStartLine{ .method = parsed_method, .path = parsed_path, .version = parsed_version };
}

test "valid request start path" {
    const start_line = "POST /hello HTTP/1.1";
    const result = try parse(start_line);
    try expect(result.method == method.Method.post);
    try expectEqualStrings("/hello", result.path);
    try expect(result.version == version.Version.http11);
}
