const message = @import("message.zig");

const Handler = fn (message.Message, message.Message) anyerror!void;

pub fn Route(comptime RequestBody: type, comptime ResponseBody: type) type {
    if (@typeInfo(RequestBody) != .Struct) @compileError("Route expects a struct type for RequestBody");
    if (@typeInfo(ResponseBody) != .Struct) @compileError("Route expects a struct type for ResponseBody");
    return struct {
        path: []const u8,
        request_body: RequestBody,
        response_body: ResponseBody,
        handler: Handler,
    };
}

pub fn Build(path: []const u8, comptime RequestBody: type, request_body: RequestBody, comptime ResponseBody: type, response_body: ResponseBody, handler: Handler) Route(RequestBody, ResponseBody) {
    return Route(RequestBody, ResponseBody){ .path = path, .request_body = request_body, .response_body = response_body, .handler = handler };
}
