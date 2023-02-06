const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

const h = @import("headers.zig");
const rl = @import("request_line.zig");

pub const Request = struct {
    request_line: rl.RequestLine,
    headers: h.Headers, 
    body_raw: []const u8,
    body_allocator: std.mem.Allocator,
};