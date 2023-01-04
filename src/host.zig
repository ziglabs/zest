const ip = @import("ip.zig");

pub const HostError = error{
    InvalidHost,
};

pub const Host = union(enum) {
    ip: Ip,
    name: []const u8,
};

pub fn parse(host: []const u8) HostError!Host {

}