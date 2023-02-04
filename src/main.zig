const std = @import("std");
const zest = @import("zest.zig");

const Yes = struct {
    hi: u8,
};

const No = struct {
    bye: u8,
};

fn yoyo(req: zest.request.Request(Yes), res: *zest.response.Response(No)) anyerror!void {
    _ = req;
    try res.headers.put("Dog", "8");
    res.body = No{ .bye = 10 };
}

pub fn main() !void {
    const config = comptime try zest.server.Config.default();
    const routes = .{try zest.route.Build("/hello", Yes, No, yoyo)};
    try zest.server.start(config, routes);
}
