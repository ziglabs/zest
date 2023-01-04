const Scheme = @import("scheme.zig");
const std = @import("std");
const expect = std.testing.expect;

const Url = struct {
    scheme: Url,

    const separator = "://";
};

// if you find a space - return error

// accept localhost

test "test" {
    try expect(std.mem.eql(u8, std.mem.trimLeft(u8, "hello", "zz"), "llo"));
}