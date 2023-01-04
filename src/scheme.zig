const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const SchemeError = error{
    UnsupportedScheme,
};

// https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
pub const Scheme = enum {
    http,
    https,

    // https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
    pub const schemes = [_][]const u8{ "http", "https" };

    pub fn toString(self: Scheme) []const u8 {
        return schemes[@enumToInt(self)];
    }

    pub fn fromString(scheme: []const u8) SchemeError!Scheme {
        for (schemes) |v, i| {
            if (std.mem.eql(u8, v, scheme)) {
                return @intToEnum(Scheme, i);
            }
        }
        return SchemeError.UnsupportedScheme;
    }

    pub fn parse(input: []const u8) SchemeError!Scheme {
        if (std.mem.startsWith(u8, input, Scheme.https.toString())) {
            return Scheme.https;
        } else if (std.mem.startsWith(u8, input, Scheme.http.toString())) {
            return Scheme.http;
        }
        return SchemeError.UnsupportedScheme;
    }

    pub fn length(self: Scheme) u8 {
        return @intCast(u8, self.toString().len);
    }

    pub fn removeScheme(input: []const u8, scheme: Scheme) SchemeError![]const u8 {
        if (std.mem.startsWith(u8, input, scheme.toString())) {
            return input[scheme.length()..];
        } else {
            return SchemeError.UnsupportedScheme;
        }
    }
};

test "lengths are equal" {
    const schemes_enum_length = @typeInfo(Scheme).Enum.fields.len;
    try expect(schemes_enum_length == Scheme.schemes.len);
}

test "invalid values return an error" {
    const expected_error = SchemeError.UnsupportedScheme;
    try expectError(expected_error, Scheme.fromString(""));
    try expectError(expected_error, Scheme.fromString(" "));
    try expectError(expected_error, Scheme.fromString("HELLO"));
}

test "scheme http" {
    const scheme = Scheme.http;
    try expect(std.mem.eql(u8, scheme.toString(), "http"));
    try expect(try Scheme.fromString("http") == Scheme.http);
}

test "scheme https" {
    const scheme = Scheme.https;
    try expect(std.mem.eql(u8, scheme.toString(), "https"));
    try expect(try Scheme.fromString("https") == Scheme.https);
}

test "scheme parse http" {
    const scheme = try Scheme.parse("http://");
    try expect(scheme == Scheme.http);
}

test "scheme parse https" {
    const scheme = try Scheme.parse("https://");
    try expect(scheme == Scheme.https);
}

test "scheme parse hello" {
    const expected_error = SchemeError.UnsupportedScheme;
    try expectError(expected_error, Scheme.parse("hello://"));
}

test "scheme parse blank" {
    const expected_error = SchemeError.UnsupportedScheme;
    try expectError(expected_error, Scheme.parse(""));
}

test "scheme len http" {
    const scheme = Scheme.http;
    try expect(scheme.length() == 4);
}

test "scheme len https" {
    const scheme = Scheme.https;
    try expect(scheme.length() == 5);
}

test "scheme removeScheme" {
    const url = "https://hello.com";
    const scheme = Scheme.https;
    const result = try Scheme.removeScheme(url, scheme);
    try expect(std.mem.eql(u8, result, "://hello.com"));
}

test "scheme removeScheme empty input" {
    const expected_error = SchemeError.UnsupportedScheme;
    try expectError(expected_error, Scheme.removeScheme("", Scheme.https));
}

test "scheme removeScheme no match" {
    const expected_error = SchemeError.UnsupportedScheme;
    try expectError(expected_error, Scheme.removeScheme("hello", Scheme.https));
}
