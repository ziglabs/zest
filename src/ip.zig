const std = @import("std");

pub const IpError = error{
    InvalidIpAddress,
};

pub const Ip = union(enum) { ipv4: std.net.Ip4Address, ipv6: std.net.Ip6Address };

pub fn fromString(ip: []const u8) IpError!Ip {
    const maybe_ipv4 = std.net.Ip4Address.parse(ip, 0) catch IpError.InvalidIpAddress;
    const maybe_ipv6 = std.net.Ip6Address.parse(ip, 0) catch IpError.InvalidIpAddress;

    if (maybe_ipv4 != IpError.InvalidIpAddress) {
        return Ip{ .ipv4 = maybe_ipv4 };
    } else if (maybe_ipv6 != IpError.InvalidIpAddress) {
        return Ip{ .ipv6 = maybe_ipv6 };
    } else {
        return IpError.InvalidIpAddress;
    }
}

test "valid ipv4 addresses" {}

test "valid ipv6 addresses" {}

test "invalid ipv4 addresses" {}

test "invalid ipv6 addresses" {}
