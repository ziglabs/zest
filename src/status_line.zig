const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const status = @import("status.zig");
const version = @import("version.zig");

pub const StatusLineError = error{
    InvalidStatusLine,
};

pub const Error = StatusLineError || status.StatusError || version.VersionError;

pub const StatusLine = struct {
    version: version.Version,
    status: status.Status,
};

pub fn parse(status_line: []const u8) Error!StatusLine {
    var iterator = std.mem.split(u8, status_line, " ");
    var slice = iterator.first();

    const parsed_version = try version.parse(slice);

    slice = if (iterator.next()) |s| s else return StatusLineError.InvalidStatusLine;

    const parsed_status = try status.parse(slice);

    if (iterator.next() != null) {
        return StatusLineError.InvalidStatusLine;
    }

    return StatusLine{ .version = parsed_version, .status = parsed_status };
}

test "valid response status line" {
    const status_line = "HTTP/1.1 200";
    const result = try parse(status_line);
    try expect(result.version == version.Version.http11);
    try expect(result.status == status.Status.ok);
}

test "wrong response version" {
    const status_line = "HTTP/1.2 200";
    const expected_error = version.VersionError.UnsupportedVersion;
    try expectError(expected_error, parse(status_line));
}

test "wrong response status" {
    const status_line = "HTTP/1.1 99";
    const expected_error = status.StatusError.InvalidStatusCode;
    try expectError(expected_error, parse(status_line));
}
