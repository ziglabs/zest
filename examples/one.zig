const std = @import("std");
const zest = @import("zest");
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
    const request_body = try req.parseBody(Yes);
    std.debug.print("\nin hello handler: {d}\n", .{request_body.hi});
    try res.headers.put("Dog", "8");
    const response_body = No{ .bye = request_body.hi + 10 };
    try res.stringifyBody(No, response_body);
}

fn hi(req: Request, res: *Response) anyerror!void {
    const request_body = try req.parseBody(Yes);
    try res.headers.put("Dog", "8");
    const response_body = No{ .bye = request_body.hi + 10 };
    try res.stringifyBody(No, response_body);
}

pub fn main() !void {
    const config = comptime try zest.server.Config.default();
    const routes = .{ 
        try Route.init("/hello", hello), 
        try Route.init("/hi", hi) 
    };
    const router = Router.init(&routes);
    try zest.server.start(config, router);
}
