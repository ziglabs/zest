const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const MethodError = error{
    UnsupportedMethod,
};

// https://www.rfc-editor.org/rfc/rfc9110.html#name-methods
pub const Method = enum {
    post,

    // https://www.rfc-editor.org/rfc/rfc9110.html#name-methods
    pub const methods = [_][]const u8{ "POST" };

    pub fn toString(self: Method) []const u8 {
        return methods[@enumToInt(self)];
    }

    pub fn fromString(method: []const u8) MethodError!Method {
        for (methods) |m, i| {
            if (std.mem.eql(u8, m, method)) {
                return @intToEnum(Method, i);
            }
        }
        return MethodError.UnsupportedMethod;
    }
};

test "lengths are equal" {
    const methods_enum_length = @typeInfo(Method).Enum.fields.len;
    try expect(methods_enum_length == Method.methods.len);
}

test "invalid values return an error" {
    const expected_error = MethodError.UnsupportedMethod;
    try expectError(expected_error, Method.fromString(""));
    try expectError(expected_error, Method.fromString(" "));
    try expectError(expected_error, Method.fromString("HELLO"));
}

test "method POST" {
    const method = Method.post;
    try expect(std.mem.eql(u8, method.toString(), "POST"));
    try expect(try Method.fromString("POST") == Method.post);
}

