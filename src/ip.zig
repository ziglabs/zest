const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const IpError = error{
    InvalidIpAddress,
};

pub fn fromString(ip: []const u8) IpError!std.net.Address {
    return std.net.Address.parseIp4(ip, 0) catch std.net.Address.parseIp6(ip, 0) catch IpError.InvalidIpAddress;
}

test "valid ipv4 addresses" {
    try expect(@TypeOf(try fromString("172.16.254.1")) == std.net.Address);
    try expect(@TypeOf(try fromString("192.0.1.246")) == std.net.Address);
}

test "valid ipv6 addresses" {
    try expect(@TypeOf(try fromString("2002:db8::8a3f:362:7897")) == std.net.Address);
    try expect(@TypeOf(try fromString("2001:db8::7")) == std.net.Address);
}

test "invalid ipv4 addresses" {
    const expected_error = IpError.InvalidIpAddress;
    try expectError(expected_error, fromString("172.16.256.1"));
    try expectError(expected_error, fromString("192.168. 01.1"));
}

test "invalid ipv6 addresses" {
    const expected_error = IpError.InvalidIpAddress;
    try expectError(expected_error, fromString("56FE::2159:5BBC::6594"));
}
