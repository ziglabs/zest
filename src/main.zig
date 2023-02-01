const std = @import("std");
const zest = @import("zest.zig");
const m = @import("message.zig");
const h = @import("headers.zig");
const r = @import("route.zig");
const sl = @import("start_line.zig");

const RequestBodyType = struct {
    hello: []const u8,
};

const ResponseBodyType = struct {
    goodbye: []const u8
};

// fn helloHandler(req: m.Message(RequestBodyType)) anyerror!m.Message(ResponseBodyType) {
//     _ = req;
//     const start_line = try sl.StartLine.request.parse("POST /hello HTTP/1.1");
//     var buffer: [300]u8 = undefined;
//     var fba = std.heap.FixedBufferAllocator.init(&buffer);
//     var headers = h.Headers.init(fba.allocator());
//     try headers.parse("Content-Length: 42");

//     return m.Build(start_line, headers, ResponseBodyType, ResponseBodyType{ .goodbye = "see ya" });
// }

fn hello() anyerror!m.Message(ResponseBodyType) {
    const start_line = try sl.StartLine.request.parse("POST /hello HTTP/1.1");
    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = h.Headers.init(fba.allocator());
    try headers.parse("Content-Length: 42");

    return m.Build(start_line, headers, ResponseBodyType, ResponseBodyType{ .goodbye = "see ya" });
}

pub fn main() !void {
    var hh = try hello();
    try hh.headers.put("Content", "sdf");
    std.debug.print("method {s}", .{hh.headers.get("Content-Length") orelse ""});
    // const route = try r.Build("/hi", RequestBodyType, ResponseBodyType, helloHandler);
    // std.debug.print("path: {s}", .{route.path});
}
