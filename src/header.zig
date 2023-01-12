const std = @import("std");
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const HeaderError = error{
    InvalidHeader,
    InvalidHeaderName,
    InvalidHeaderValue,
};

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub fn parse(header: []const u8) HeaderError!Header {
    if (header.len == 0) return HeaderError.InvalidHeader;
    if (std.mem.count(u8, header, ": ") != 1) return HeaderError.InvalidHeader;

    var iterator = std.mem.split(u8, header, ": ");
    const name = iterator.first();
    const value = if (iterator.next()) |v| v else return HeaderError.InvalidHeader;

    if (!validName(name)) return HeaderError.InvalidHeaderName;
    if (!validValue(value)) return HeaderError.InvalidHeaderValue;

    return Header{ .name = name, .value = value };
}

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

test "valid header" {
    const result = try parse("Content-Length: 42");
    try expectEqualStrings("Content-Length", result.name);
    try expectEqualStrings("42", result.value);
}

test "invalid header" {
    var expected_error = HeaderError.InvalidHeaderName;
    try expectError(expected_error, parse("Con(tent-Length: 42"));

    expected_error = HeaderError.InvalidHeaderValue;
    try expectError(expected_error, parse("Content-Length: 4\r2"));

    expected_error = HeaderError.InvalidHeader;
    try expectError(expected_error, parse("Content-Length:42"));

    expected_error = HeaderError.InvalidHeader;
    try expectError(expected_error, parse(""));
}
