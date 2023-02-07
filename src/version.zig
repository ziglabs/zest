const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const VersionError = error{
    UnsupportedVersion,
};

// https://www.rfc-editor.org/rfc/rfc9110.html#name-protocol-version
pub const Version = enum {
    http11,

    pub fn toString(self: Version) []const u8 {
        return versions[@enumToInt(self)];
    }
};

// https://www.rfc-editor.org/rfc/rfc9110.html#name-protocol-version
pub const versions = [_][]const u8{"HTTP/1.1"};

pub fn parse(version: []const u8) VersionError!Version {
    for (versions) |v, i| {
        if (std.mem.eql(u8, v, version)) {
            return @intToEnum(Version, i);
        }
    }
    return VersionError.UnsupportedVersion;
}

test "lengths are equal" {
    const versions_enum_length = @typeInfo(Version).Enum.fields.len;
    try expect(versions_enum_length == versions.len);
}

test "invalid values return an error" {
    const expected_error = VersionError.UnsupportedVersion;
    try expectError(expected_error, parse(""));
    try expectError(expected_error, parse(" "));
    try expectError(expected_error, parse("HELLO"));
}

test "version HTTP/1.1" {
    const version = Version.http11;
    try expect(std.mem.eql(u8, version.toString(), "HTTP/1.1"));
    try expect((try parse("HTTP/1.1")) == Version.http11);
}
