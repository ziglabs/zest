const std = @import("std");
const zest = @import("zest");
const server = zest.server;
const Request = zest.request.Request;
const Response = zest.response.Response;
const Route = zest.route.Route;
const Router = zest.router.Router;

const Person = struct {
    name: []const u8,
    favorite_food: []const u8,
};

const SillyPhrase = struct {
    name: []const u8,
};

fn sillyPhraseGenerator(req: Request, res: *Response) void {
    const request_body = req.parseBody(Person) catch unreachable;
    const response_body = SillyPhrase{ .name = "Zippy " ++ request_body.favorite_food ++ " " ++ request_body.name ++ " McZappy" };
    res.stringifyBody(SillyPhrase, response_body) catch unreachable;
}

pub fn main() !void {
    const config = comptime try server.Config.init("127.0.0.1", 8080, 1024);
    const routes = comptime .{ try Route.init("/sillyPhraseGenerator", sillyPhraseGenerator) };
    const router = comptime Router.init(&routes);
    try server.start(config, router);
}
