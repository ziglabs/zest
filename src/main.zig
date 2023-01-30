const std = @import("std");
const zest = @import("zest.zig");

pub fn main() !void {
    try zest.server.start(
        try std.net.Address.parseIp("127.0.0.1", 8080),
    );
}
