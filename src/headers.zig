const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;
const header = @import("header.zig");
const Header = header.Header;

pub const HeadersError = error {
    OutOfSpace,
};

pub const Headers = struct {
    headers: [2]Header = undefined,
    index: u8 = 0,

    pub fn append(self: *Headers, content: Header) HeadersError!void {
        if (self.index == self.headers.len) return HeadersError.OutOfSpace;

        self.headers[self.index] = content;
        self.index += 1;
    }

    pub fn get(self: Headers, name: []const u8) ?Header {
        if (self.index == 0) return null;
        for (self.headers) |item| {
            if (std.mem.eql(u8, item.name, name)) return item;
        }
        return null;
    }
};

test "append headers" {
    const header_1 = try header.parse("Content-Length: 9000");
    const header_2 = try header.parse("Content-Type: application/json");
    var headers = Headers{};
    try headers.append(header_1);
    try headers.append(header_2);
}

test "get header" {
    const header_1 = try header.parse("Content-Length: 9000");
    var headers = Headers{};
    try headers.append(header_1);

    const get_header_1 = headers.get("Content-Length") orelse unreachable;
    try expectEqualStrings("Content-Length", get_header_1.name);
    try expectEqualStrings("9000", get_header_1.value);
}

test "get out of space error" {
    var headers = Headers{};
    try headers.append(try header.parse("Content-Type: application/json"));
    try headers.append(try header.parse("Content-Type: application/json"));

    const expected_error = HeadersError.OutOfSpace;
    try expectError(expected_error, headers.append(try header.parse("Content-Type: application/json")));
}

test "get back null" {
    var headers = Headers{};
    var result = headers.get("hello");
    try expect(result == null);

    try headers.append(try header.parse("Content-Type: application/json"));
    result = headers.get("hello");
    try expect(result == null);
}