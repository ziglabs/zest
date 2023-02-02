// const std = @import("std");
// const expect = std.testing.expect;
// const expectEqualStrings = std.testing.expectEqualStrings;
// const request = @import("request.zig");
// const response = @import("response.zig");
// const p = @import("path.zig");

// pub fn Handler(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
//     return fn (comptime request.Request(RequestBodyType), comptime *response.Response(ResponseBodyType)) anyerror!void;
// }

// pub fn Route(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
//     if (@typeInfo(RequestBodyType) != .Struct) @compileError("Route expects a struct type for RequestBodyType");
//     if (@typeInfo(ResponseBodyType) != .Struct) @compileError("Route expects a struct type for ResponseBodyType");
//     return struct {
//         path: []const u8,
//         request_body_type: type,
//         response_body_type: type,
//         handler: Handler(RequestBodyType, ResponseBodyType),
//     };
// }

// pub fn Build(comptime path: []const u8, comptime RequestBodyType: type, comptime ResponseBodyType: type, comptime handler: Handler(RequestBodyType, ResponseBodyType)) !Route(RequestBodyType, ResponseBodyType) {
//     return comptime Route(RequestBodyType, ResponseBodyType){ .path = try p.parse(path), .request_body_type = RequestBodyType, .response_body_type = ResponseBodyType, .handler = handler };
// }

// pub const Yes = struct {
//     hi: u8,
// };

// pub const No = struct {
//     bye: u8,
// };

// pub fn yes(comptime req: request.Request(Yes), comptime res: *response.Response(No)) !void {
//     _ = req;
//     _ = res;
// }

// test "test" {
//     const route = try Build("/hello", Yes, No, yes);
//     try expectEqualStrings("/hello", route.path);
// }

const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const request = @import("request.zig");
const response = @import("response.zig");
const p = @import("path.zig");

pub fn Handler(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
    comptime {
        return fn (request.Request(RequestBodyType), *response.Response(ResponseBodyType)) anyerror!void;
    }
}

pub fn Route(comptime RequestBodyType: type, comptime ResponseBodyType: type) type {
    if (@typeInfo(RequestBodyType) != .Struct) @compileError("Route expects a struct type for RequestBodyType");
    if (@typeInfo(ResponseBodyType) != .Struct) @compileError("Route expects a struct type for ResponseBodyType");
    comptime {
        return struct {
            path: []const u8,
            request_body_type: type,
            response_body_type: type,
            handler: Handler(RequestBodyType, ResponseBodyType),
        };
    }
}

pub fn Build(comptime path: []const u8, comptime RequestBodyType: type, comptime ResponseBodyType: type, comptime handler: Handler(RequestBodyType, ResponseBodyType)) !Route(RequestBodyType, ResponseBodyType) {
    comptime {
        return Route(RequestBodyType, ResponseBodyType){ .path = try p.parse(path), .request_body_type = RequestBodyType, .response_body_type = ResponseBodyType, .handler = handler };
    }
}

pub const Yes = struct {
    hi: u8,
};

pub const No = struct {
    bye: u8,
};

pub fn yes(req: request.Request(Yes), res: *response.Response(No)) anyerror!void {
    _ = req;
    _ = res;
}

test "test" {
    const route = try Build("/hello", Yes, No, yes);
    try expectEqualStrings("/hello", route.path);
}
