const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

const h = @import("headers.zig");
const sl = @import("status_line.zig");

pub const EmptyBody = struct {};

pub fn Response(comptime BodyType: type) type {
    if (@typeInfo(BodyType) != .Struct) @compileError("Response expects BodyType to be a struct type");
    return struct { status_line: sl.StatusLine, headers: h.Headers, body: ?BodyType, body_allocator: std.mem.Allocator };
}

pub fn Build(status_line: sl.StatusLine, headers: h.Headers, comptime BodyType: type, body_allocator: std.mem.Allocator) Response(BodyType) {
    return Response(BodyType){ .status_line = status_line, .headers = headers, .body = null, .body_allocator = body_allocator };
}

test "test" {
    const Greeting = struct {
        hi: u8,
    };

    const status_line = try sl.parse("HTTP/1.1 200");

    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = h.Headers.init(fba.allocator());
    try headers.parse("Content-Length: 42");

    const body = Greeting{ .hi = 9 };

    var built_response = Build(status_line, headers, Greeting);
    built_response.body = body;
    const body_hi = if (built_response.body) |b| b else unreachable;
    try expect(body_hi.hi == 9);
    try expect(@TypeOf(body_hi) == Greeting);
    try expectEqualStrings(built_response.headers.get("Content-Length") orelse unreachable, "42");
    try expect(built_response.status_line.status == .ok);
    try expect(built_response.status_line.version == .http11);
}