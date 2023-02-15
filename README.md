# Zest
Zest is a json-rpc ***like*** http server with zero dynamic memory allocation.

## Example
```zig
const std = @import("std");
const zest = @import("zest");
const server = zest.server;
const Request = zest.request.Request;
const Response = zest.response.Response;
const Route = zest.route.Route;
const Router = zest.router.Router;

const Person = struct {
    name: []const u8,
};

const ScouterReading = struct {
    power_level: u64
};

fn scouter(req: Request, res: *Response) anyerror!void {
    const request_body = try req.parseBody(Person);
    const power_level: u64 = if (std.mem.eql(u8, "goku", request_body.name)) 9000 else 1;
    const response_body = ScouterReading{ .power_level = power_level };
    try res.stringifyBody(ScouterReading, response_body);
}

pub fn main() !void {
    const config = comptime try server.Config.init("127.0.0.1", 8080, 1024);
    const routes = comptime .{try Route.init("/scouter", scouter)};
    const router = comptime Router.init(&routes);
    try server.start(config, router);
}
```

## Constraints

* No url params
* No query params
* Only POST requests
* Requires `Content-Type: application/json` in request headers
* Requires `Content-Length: <length_here>` in request headers
* At a minimum an empty object `{}` must be sent in the request / response
## Building
Zest is being developed on Zig version 0.10.1 and will be kept up to date with new releases.

To build Zest do `zig build` (this also builds the `scouter` example). To indivually build the `scouter` example do `zig build example -Dexample=scouter` and the executable will appear in `zig-out/bin`.