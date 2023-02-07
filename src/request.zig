const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

const h = @import("headers.zig");
const rl = @import("request_line.zig");
const b = @import("body.zig");

pub const EmptyBody = struct{};

pub const Request = struct {
    request_line: rl.RequestLine,
    headers: h.Headers, 
    body_raw: []const u8,
    body_allocator: std.mem.Allocator,

    pub fn parseBody(self: Request, comptime BodyType: type) !BodyType {
        return try b.parse(self.body_allocator, BodyType, self.body_raw);
    }
};