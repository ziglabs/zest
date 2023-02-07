const std = @import("std");
const zest = @import("zest");
const server = zest.server;
const Request = zest.request.Request;
const Response = zest.response.Response;
const Route = zest.route.Route;
const Router = zest.router.Router;

const Person = struct {
    name: []const u8,
    age: u16,
};

const Friend = struct {
    name: []const u8,
    age: u16,
};

fn findFriend(req: Request, res: *Response) anyerror!void {
    const request_body = try req.parseBody(Person);
    const response_body = Friend{ .name = "Zippy McZappy", .age = request_body.age * 2 };
    try res.stringifyBody(Friend, response_body);
}

pub fn main() !void {
    const config = comptime try server.Config.init("127.0.0.1", 8080, 1024);
    const routes = comptime .{ try Route.init("/findFriend", findFriend) };
    const router = comptime Router.init(&routes);
    try server.start(config, router);
}
