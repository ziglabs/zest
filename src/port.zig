const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

pub const PortError = error{
    InvalidPort,
};

pub fn parse(port: []const u8) PortError!u16 {
    const result = std.fmt.parseUnsigned(u16, port, 10) catch return PortError.InvalidPort;
    if (result >= 1 and result <= 65535) return result else return PortError.InvalidPort;
}

test "valid ports" {
    var port = try parse("9000");
    try expect(port == 9000);

    port = try parse("1");
    try expect(port == 1);

    port = try parse("65535");
    try expect(port == 65535);
}

test "invalid ports" {
    const expected_error = PortError.InvalidPort;
    try expectError(expected_error, parse("hello"));
    try expectError(expected_error, parse("0"));
    try expectError(expected_error, parse("65536"));
}