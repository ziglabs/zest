const method = @import("method.zig");
const message = @import("message.zig");

pub const Route = struct {
    method: method.Method,
    path: []const u8,
    handler: Handler,

    const Handler = fn (message.Message, message.Message) anyerror!void;
};