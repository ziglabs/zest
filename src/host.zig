const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;
const ip = @import("ip.zig");

pub const HostError = error{
    InvalidHost,
};

pub const Host = union(enum) {
    ip: std.net.Address,
    name: []const u8,
};

pub fn parse(host: []const u8) HostError!Host {
    const maybe_ip = ip.fromString(host) catch {
        if (std.net.isValidHostName(host)) {
            return Host{ .name = host };
        } else {
            return HostError.InvalidHost;
        }
    };

    return Host{ .ip = maybe_ip };
}

test "valid hosts" {
    const host_1 = try parse("hello.com");
    try expectEqualStrings("hello.com", host_1.name);

    const host_2 = try parse("172.16.254.1");
    switch(host_2) {
        .ip => try expect(true),
        .name => try expect(false),
    }
}
