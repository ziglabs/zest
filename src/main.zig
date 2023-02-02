const std = @import("std");
const zest = @import("zest.zig");
const request = @import("request.zig");
const response = @import("response.zig");

// pub fn main() !void {
//     const config = comptime zest.server.Config{ 
//         .address = try std.net.Address.parseIp("127.0.0.1", 8080), 
//         .max_request_line_bytes = 1024, 
//         .max_headers_bytes = 1024, 
//         .max_headers_map_bytes = 1024, 
//         .max_body_bytes = 1024 };

//     try zest.server.start(config);
// }

const Yes = struct {
    hi: u8,
};

const No = struct {
    bye: u8,
};

pub fn yoyo(req: request.Request(Yes), res: *response.Response(No)) anyerror!void {
    _ = req;
    _ = res;
}

pub fn main() !void {
    const route = try zest.route.Build("/hello", Yes, No, yoyo);
    std.debug.print("path: {s}", .{route.path});
}
