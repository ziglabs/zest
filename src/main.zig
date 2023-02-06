const std = @import("std");
const zest = @import("zest.zig");
const Request = zest.request.Request;
const Response = zest.response.Response;
const Route = zest.route.Route;
const Router = zest.router.Router;

const Yes = struct {
    hi: u8,
};

const No = struct {
    bye: u8,
};

fn hello(req: Request, res: *Response) anyerror!void {
    const request_body = try zest.body.parse(req.body_allocator, Yes, req.body_raw);
    std.debug.print("\nin hello handler: {d}\n", .{request_body.hi});
    try res.headers.put("Dog", "8");
}

fn hi(req: Request, res: *Response) anyerror!void {
    _ = req;
    try res.headers.put("Dog", "8");
    res.body_raw = "{ \"bye\": 10 }";
}

pub fn main() !void {
    const config = comptime try zest.server.Config.default();

    const router = Router{
        .routes = &.{
            try Route.init("/hello", hello),
            try Route.init("/hi", hi)
        }
    };

    try zest.server.start(config, router);
}
