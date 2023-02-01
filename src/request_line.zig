const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const method = @import("method.zig");
const path = @import("path.zig");
const version = @import("version.zig");

pub const RequestLineError = error{
    InvalidRequestLine,
};

pub const Error = RequestLineError || method.MethodError || path.PathError || version.VersionError;

pub const RequestLine = struct {
    method: method.Method,
    path: []const u8,
    version: version.Version,
};

pub fn parse(request_line: []const u8) Error!RequestLine {
    var iterator = std.mem.split(u8, request_line, " ");
    var slice = iterator.first();

    const parsed_method = try method.parse(slice);

    slice = if (iterator.next()) |s| s else return RequestLineError.InvalidRequestLine;

    const parsed_path = try path.parse(slice);

    slice = if (iterator.next()) |s| s else return RequestLineError.InvalidRequestLine;

    const parsed_version = try version.parse(slice);

    if (iterator.next() != null) {
        return RequestLineError.InvalidRequestLine;
    }

    return RequestLine{ .method = parsed_method, .path = parsed_path, .version = parsed_version };
}



test "valid request start path" {
    const request_line = "POST /hello HTTP/1.1";
    const result = try parse(request_line);
    try expect(result.method == method.Method.post);
    try expectEqualStrings("/hello", result.path);
    try expect(result.version == version.Version.http11);
}

test "wrong request method" {
    const request_line = "POS /hello HTTP/1.1";
    const expected_error = method.MethodError.UnsupportedMethod;
    try expectError(expected_error, parse(request_line));
}

test "wrong request version" {
    const request_line = "POST /hello HTTP/1.2";
    const expected_error = version.VersionError.UnsupportedVersion;
    try expectError(expected_error, parse(request_line));
}