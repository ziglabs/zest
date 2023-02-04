const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

const h = @import("headers.zig");
const rl = @import("request_line.zig");

pub const EmptyBody = struct {};

pub fn Request(comptime BodyType: type) type {
    if (@typeInfo(BodyType) != .Struct) @compileError("Request expects BodyType to be a struct type");
    return struct { request_line: rl.RequestLine, headers: h.Headers, body: BodyType };
}

pub fn Build(request_line: rl.RequestLine, headers: h.Headers, comptime BodyType: type, body: BodyType) Request(BodyType) {
    return Request(BodyType){ .request_line = request_line, .headers = headers, .body = body };
}

test "test" {
    const Greeting = struct {
        hi: u8,
    };

    const request_line = try rl.parse("POST /hello HTTP/1.1");

    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = h.Headers.init(fba.allocator());
    try headers.parse("Content-Length: 42");

    const body = Greeting{ .hi = 9 };

    const built_request = Build(request_line, headers, Greeting, body);

    try expect(built_request.body.hi == 9);
    try expect(@TypeOf(built_request.body) == Greeting);
    try expectEqualStrings(built_request.headers.get("Content-Length") orelse unreachable, "42");
    try expect(built_request.request_line.method == .post);
    try expectEqualStrings(built_request.request_line.path, "/hello");
    try expect(built_request.request_line.version == .http11);
}
