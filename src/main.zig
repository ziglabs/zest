const std = @import("std");
const zest = @import("zest.zig");

const Yes = struct {
    hi: u8,
};

const No = struct {
    bye: u8,
};

fn hello(req: zest.request.Request(Yes), res: *zest.response.Response(No)) anyerror!void {
    _ = req;
    try res.headers.put("Dog", "8");
    res.body = No{ .bye = 10 };
}

fn hi(req: zest.request.Request(zest.request.EmptyBody), res: *zest.response.Response(zest.response.EmptyBody)) anyerror!void {
    _ = req;
    try res.headers.put("Dog", "8");
}

pub fn main() !void {
    const config = comptime try zest.server.Config.default();
    const routes = comptime .{ 
        try zest.route.Build("/hello", Yes, No, hello), 
        try zest.route.Build("/hi", zest.request.EmptyBody, zest.response.EmptyBody, hi) 
    };
    try zest.server.start(config, routes);
}