const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;
const p = @import("path.zig");

pub const Route = struct {
    path: []const u8,
    handler: fn (Request, *Response) anyerror!void,

    pub fn init(path: []const u8, handler: fn (Request, *Response) anyerror!void) !Route {
        return Route{
            .path = try p.parse(path),
            .handler = handler,
        };
    }
};
