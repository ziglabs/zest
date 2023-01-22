const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const method = @import("method.zig");
const path = @import("path.zig");
const status = @import("status.zig");
const version = @import("version.zig");

pub const StartLineError = error{
    InvalidStartLine,
};

pub const Error = StartLineError || method.MethodError || path.PathError || status.StatusError || version.VersionError;

pub const Type = union(enum) {
    request: Request,
    response: Response,
};

pub const Request = struct {
    method: method.Method,
    path: []const u8,
    version: version.Version,
};

pub const Response = struct {
    version: version.Version,
    status: status.Status,
};

pub const StartLine = enum {
    request,
    response,

    pub fn parse(self: StartLine, start_line: []const u8) Error!Type {
        switch (self) {
            .request => {
                const request = try parseRequestStartLine(start_line);
                return Type{ .request = request };
            },
            .response => {
                const response = try parseResponseStartLine(start_line);
                return Type{ .response = response };
            },
        }
    }
};

fn parseRequestStartLine(start_line: []const u8) Error!Request {
    var iterator = std.mem.split(u8, start_line, " ");
    var slice = iterator.first();

    const parsed_method = try method.parse(slice);

    slice = if (iterator.next()) |s| s else return StartLineError.InvalidStartLine;

    const parsed_path = try path.parse(slice);

    slice = if (iterator.next()) |s| s else return StartLineError.InvalidStartLine;

    const parsed_version = try version.parse(slice);

    if (iterator.next() != null) {
        return StartLineError.InvalidStartLine;
    }

    return Request{ .method = parsed_method, .path = parsed_path, .version = parsed_version };
}

fn parseResponseStartLine(start_line: []const u8) Error!Response {
    var iterator = std.mem.split(u8, start_line, " ");
    var slice = iterator.first();

    const parsed_version = try version.parse(slice);

    slice = if (iterator.next()) |s| s else return StartLineError.InvalidStartLine;

    const parsed_status = try status.parse(slice);

    if (iterator.next() != null) {
        return StartLineError.InvalidStartLine;
    }

    return Response{ .version = parsed_version, .status = parsed_status };
}

test "valid request start path" {
    const start_line = "POST /hello HTTP/1.1";
    const result = try StartLine.request.parse(start_line);
    try expect(result.request.method == method.Method.post);
    try expectEqualStrings("/hello", result.request.path);
    try expect(result.request.version == version.Version.http11);
}

test "wrong request method" {
    const start_line = "POS /hello HTTP/1.1";
    const expected_error = method.MethodError.UnsupportedMethod;
    try expectError(expected_error, StartLine.request.parse(start_line));
}

test "wrong request version" {
    const start_line = "POST /hello HTTP/1.2";
    const expected_error = version.VersionError.UnsupportedVersion;
    try expectError(expected_error, StartLine.request.parse(start_line));
}

test "valid response start path" {
    const start_line = "HTTP/1.1 200";
    const result = try StartLine.response.parse(start_line);
    try expect(result.response.version == version.Version.http11);
    try expect(result.response.status == status.Status.ok);
}

test "wrong response version" {
    const start_line = "HTTP/1.2 200";
    const expected_error = version.VersionError.UnsupportedVersion;
    try expectError(expected_error, StartLine.response.parse(start_line));
}

test "wrong response status" {
    const start_line = "HTTP/1.1 99";
    const expected_error = status.StatusError.InvalidStatusCode;
    try expectError(expected_error, StartLine.response.parse(start_line));
}
