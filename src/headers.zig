const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const HeadersError = error{
    InvalidHeader,
    InvalidHeaderName,
    InvalidHeaderValue,
    OutOfSpace,
};

pub const Headers = struct {
    headers: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) Headers {
        return Headers{ .headers = std.StringHashMap([]const u8).init(allocator) };
    }

    pub fn get(self: Headers, name: []const u8) ?[]const u8 {
        return self.headers.get(name);
    }

    pub fn put(self: *Headers, name: []const u8, value: []const u8) !void {
        if (!validName(name)) return HeadersError.InvalidHeaderName;
        if (!validValue(value)) return HeadersError.InvalidHeaderValue;

        self.headers.put(name, value) catch return HeadersError.OutOfSpace;
    }

    pub fn parse(self: *Headers, header: []const u8) HeadersError!void {
        if (header.len == 0) return HeadersError.InvalidHeader;
        if (std.mem.count(u8, header, ": ") != 1) return HeadersError.InvalidHeader;

        var iterator = std.mem.split(u8, header, ": ");
        const name = iterator.first();
        const value = if (iterator.next()) |v| v else return HeadersError.InvalidHeader;
        
        try self.put(name, value);
    }
};

fn validName(name: []const u8) bool {
    for (name) |char| {
        if (!valid_header_name_characters[char]) return false;
    }
    return true;
}

fn validValue(value: []const u8) bool {
    for (value) |char| {
        if (!valid_header_value_characters[char]) return false;
    }
    return true;
}

const valid_header_name_characters = [_]bool{
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, true,  false, true,  true,  true,  true,  true,  false, false, true,  true,  false, true,  true,  false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, false, false, false,
    false, true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, false, true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, true,  false, true,  false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
};

const valid_header_value_characters = [_]bool{
    false, false, false, false, false, false, false, false, false, true,  false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
    true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
};

test "valid header 1" {
    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = Headers.init(fba.allocator());

    try headers.parse("Content-Length: 42");
    const value = headers.get("Content-Length") orelse unreachable;
    try expectEqualStrings("42", value);
}

test "valid header 2" {
    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = Headers.init(fba.allocator());

    try headers.parse("Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImV4cCI6MTY2NTE2NzM1NSwiaWF0IjoxNjY1MTYwMTU1LCJpc3MiOiJKb2tlbiIsImp0aSI6IjJzZHRjbG44YTNuYnJuZGVoYzAwMDA2NCIsIm5iZiI6MTY2NTE2MDE1NSwicGFzc3dvcmQiOiJ0aGVyZSIsInVzZXJuYW1lIjoiaGVsbG8ifQ.kpFf5uo_ll6Ti8xYe3XhwL_EjX-wWVOz8A6ywWt3IJo");
    const value = headers.get("Authorization") orelse unreachable;
    try expectEqualStrings("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImV4cCI6MTY2NTE2NzM1NSwiaWF0IjoxNjY1MTYwMTU1LCJpc3MiOiJKb2tlbiIsImp0aSI6IjJzZHRjbG44YTNuYnJuZGVoYzAwMDA2NCIsIm5iZiI6MTY2NTE2MDE1NSwicGFzc3dvcmQiOiJ0aGVyZSIsInVzZXJuYW1lIjoiaGVsbG8ifQ.kpFf5uo_ll6Ti8xYe3XhwL_EjX-wWVOz8A6ywWt3IJo", value);
}

test "invalid header" {
    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = Headers.init(fba.allocator());

    var expected_error = HeadersError.InvalidHeaderName;
    try expectError(expected_error, headers.parse("Con(tent-Length: 42"));

    expected_error = HeadersError.InvalidHeaderValue;
    try expectError(expected_error, headers.parse("Content-Length: 4\r2"));

    expected_error = HeadersError.InvalidHeader;
    try expectError(expected_error, headers.parse("Content-Length:42"));

    expected_error = HeadersError.InvalidHeader;
    try expectError(expected_error, headers.parse(""));
}

test "out of space error" {
    var buffer: [300]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var headers = Headers.init(fba.allocator());

    try headers.put("a", "1");
    try headers.put("b", "2");
    try headers.put("c", "3");
    try headers.put("d", "4");
    try headers.put("e", "5");
    try headers.put("f", "6");

    const expected_error = HeadersError.OutOfSpace;
    try expectError(expected_error, headers.parse("g: 7"));
}
