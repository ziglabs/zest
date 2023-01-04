const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

const Scheme = @import("scheme.zig").Scheme;

pub const PortError = error {
    InvalidPort,
};

pub fn fromString(port: []const u8) PortError!u16 {
    const result = std.fmt.parseUnsigned(u16, port, 10) catch return PortError.InvalidPort;
    if (result >= 1 and result <= 65535) return result else return PortError.InvalidPort;
}

pub fn fromScheme(scheme: Scheme) u16 {
    return switch(scheme) {
        .http => 80,
        .https => 443,
    };
}

test "valid ports" {
    try expect(try fromString("9000") == 9000);
    try expect(try fromString("1") == 1);
    try expect(try fromString("65535") == 65535);
}

test "invalid ports" {
    const expected_error = PortError.InvalidPort;
    try expectError(expected_error, fromString("hello"));
    try expectError(expected_error, fromString("0"));
    try expectError(expected_error, fromString("65536"));
}

test "port from scheme" {
    try expect(fromScheme(Scheme.http) == 80);
    try expect(fromScheme(Scheme.https) == 443);
}