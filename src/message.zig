const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const h = @import("headers.zig");
const sl = @import("start_line.zig");

pub fn Message(comptime Body: type) type {
    if (@typeInfo(Body) != .Struct) @compileError("Message expects a struct type");
    return struct { start_line: sl.Type, headers: h.Headers, body: Body };
}

pub fn Build(start_line: sl.Type, headers: h.Headers, comptime Body: type, body: Body) Message(Body) {
    return Message(Body){ .start_line = start_line, .headers = headers, .body = body };
}

test "test" {
    const Greeting = struct {
        hi: u8,
    };

    const start_line = try sl.StartLine.request.parse("POST /hello HTTP/1.1");

    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = h.Headers.init(fba.allocator());
    try headers.parse("Content-Length: 42");

    const bm = Build(start_line, headers, Greeting, Greeting{ .hi = 9 });

    try expect(bm.body.hi == 9);

    // try expect(@typeInfo(@TypeOf(bm.body)) == Greeting);

    try expect(@TypeOf(bm.body) == Greeting);

}
