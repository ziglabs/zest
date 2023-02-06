const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

const h = @import("headers.zig");
const sl = @import("status_line.zig");

pub const Response = struct {
    status_line: sl.StatusLine,
    headers: h.Headers,
    body_raw: []const u8,
    body_allocator: std.mem.Allocator,
    body_stringify_allocator: std.mem.Allocator,
};