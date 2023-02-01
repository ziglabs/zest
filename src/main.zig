const std = @import("std");
const zest = @import("zest.zig");

pub fn main() !void {
    const config = comptime zest.server.Config{ 
        .address = try std.net.Address.parseIp("127.0.0.1", 8080), 
        .max_request_line_bytes = 1024, 
        .max_headers_bytes = 1024, 
        .max_headers_map_bytes = 1024, 
        .max_body_bytes = 1024 };

    try zest.server.start(config);
}
