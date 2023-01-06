const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const IpError = error{
    InvalidIpAddress,
};

pub fn parse(ip: []const u8) IpError!std.net.Address {
    return std.net.Address.parseIp4(ip, 0) catch try parseIp6(ip);
}

fn parseIp6(ip: []const u8) IpError!std.net.Address {
    if (ip.len < 3) return IpError.InvalidIpAddress;
    if (ip[0] == '[' and ip[ip.len-1] == ']') {
        return std.net.Address.parseIp6(ip[1..ip.len-1], 0) catch IpError.InvalidIpAddress;
    } else return IpError.InvalidIpAddress;
    
}

// test "valid ipv4 addresses" {
//     try expect(@TypeOf(try parse("172.16.254.1")) == std.net.Address);
//     try expect(@TypeOf(try parse("192.0.1.246")) == std.net.Address);
// }

// test "valid ipv6 addresses" {
//     try expect(@TypeOf(try parse("2002:db8::8a3f:362:7897")) == std.net.Address);
//     try expect(@TypeOf(try parse("2001:db8::7")) == std.net.Address);
// }

// test "invalid ipv4 addresses" {
//     const expected_error = IpError.InvalidIpAddress;
//     try expectError(expected_error, parse("172.16.256.1"));
//     try expectError(expected_error, parse("192.168. 01.1"));
// }

// test "invalid ipv6 addresses" {
//     const expected_error = IpError.InvalidIpAddress;
//     try expectError(expected_error, parse("56FE::2159:5BBC::6594"));
// }

test "ipv6" {
    const result = try parse("[2002:db8::8a3f:362:7897]");
    var buf = [_]u8{0} ** 100;
    var ip = std.fmt.bufPrint(buf[0..], "{}", .{result}) catch unreachable;
    try expectEqualStrings("[2002:db8::8a3f:362:7897]:0", ip);
  
}
