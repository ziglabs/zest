const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const request = @import("request.zig");
const response = @import("response.zig");
const p = @import("path.zig");

pub fn Handler(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
    return fn (request.Request(RequestBodyType), *response.Response(ResponseBodyType)) anyerror!void;
}

pub fn Route(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
    if (@typeInfo(RequestBodyType) != .Struct) @compileError("Route expects a struct type for RequestBodyType");
    if (@typeInfo(ResponseBodyType) != .Struct) @compileError("Route expects a struct type for ResponseBodyType");
    return struct {
        path: []const u8,
        request_body_type: type,
        response_body_type: type,
        handler: Handler(RequestBodyType, ResponseBodyType),
    };
}

pub fn Build(comptime path: []const u8, comptime RequestBodyType: type, comptime ResponseBodyType: type, handler: Handler(RequestBodyType, ResponseBodyType)) !Route(RequestBodyType, ResponseBodyType) {
    return Route(RequestBodyType, ResponseBodyType){ .path = try p.parse(path), .request_body_type = RequestBodyType, .response_body_type = ResponseBodyType, .handler = handler };
}