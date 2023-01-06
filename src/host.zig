const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const ip = @import("ip.zig");

pub const HostError = error{
    InvalidHost,
};

pub fn parse(host: []const u8) HostError![]const u8 {
    _ = ip.parse(host) catch {
        if (std.net.isValidHostName(host)) return host else return HostError.InvalidHost;
    };

    return host;
}

test "valid hosts" {
    const host_1 = try parse("hello.com");
    try expectEqualStrings("hello.com", host_1);

    const host_2 = try parse("172.16.254.1");
    try expectEqualStrings("172.16.254.1", host_2);
}

test "invalid hosts" {
    const expected_error = HostError.InvalidHost;
    try expectError(expected_error, parse("he/llo.com"));
}
