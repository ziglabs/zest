const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

const MethodError = error{
    InvalidMethod,
};

// https://www.rfc-editor.org/rfc/rfc9110.html#name-methods
pub const Method = enum {
    get,
    head,
    post,
    put,
    delete,
    connect,
    options,
    trace,


    // https://www.rfc-editor.org/rfc/rfc9110.html#name-methods
    pub const methods = [_][]const u8{ "GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE" };

    pub fn toString(self: Method) []const u8 {
        return methods[@enumToInt(self)];
    }

    pub fn fromString(method: []const u8) MethodError!Method {
        for (methods) |m, i| {
            if (std.mem.eql(u8, m, method)) {
                return @intToEnum(Method, i);
            }
        }
        return MethodError.InvalidMethod;
    }


};

test "lengths are equal" {
    const methods_enum_length = @typeInfo(Method).Enum.fields.len;
    try expect(methods_enum_length == Method.methods.len);
}

test "invalid values return an error" {
    const expected_error = MethodError.InvalidMethod;
    try expectError(expected_error, Method.fromString(""));
    try expectError(expected_error, Method.fromString(" "));
    try expectError(expected_error, Method.fromString("HELLO"));
}

test "method GET" {
    const method = Method.get;
    try expect(std.mem.eql(u8, method.toString(), "GET"));
    try expect(try Method.fromString("GET") == Method.get);
}

test "method HEAD" {
    const method = Method.head;
    try expect(std.mem.eql(u8, method.toString(), "HEAD"));
    try expect(try Method.fromString("HEAD") == Method.head);
}

test "method POST" {
    const method = Method.post;
    try expect(std.mem.eql(u8, method.toString(), "POST"));
    try expect(try Method.fromString("POST") == Method.post);
}

test "method PUT" {
    const method = Method.put;
    try expect(std.mem.eql(u8, method.toString(), "PUT"));
    try expect(try Method.fromString("PUT") == Method.put);
}

test "method DELETE" {
    const method = Method.delete;
    try expect(std.mem.eql(u8, method.toString(), "DELETE"));
    try expect(try Method.fromString("DELETE") == Method.delete);
}

test "method CONNECT" {
    const method = Method.connect;
    try expect(std.mem.eql(u8, method.toString(), "CONNECT"));
    try expect(try Method.fromString("CONNECT") == Method.connect);
}

test "method OPTIONS" {
    const method = Method.options;
    try expect(std.mem.eql(u8, method.toString(), "OPTIONS"));
    try expect(try Method.fromString("OPTIONS") == Method.options);
}


test "method TRACE" {
    const method = Method.trace;
    try expect(std.mem.eql(u8, method.toString(), "TRACE"));
    try expect(try Method.fromString("TRACE") == Method.trace);
}
