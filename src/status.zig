const std = @import("std");
const expect = std.testing.expect;

const StatusError = error{
    InvalidStatusCode,
};
// https://www.rfc-editor.org/rfc/rfc9110#section-15
pub const Status = enum(u16) {
    @"continue",
    switching_protocols,
    ok,
    created,
    accepted,
    non_authoritative_information,
    no_content,
    reset_content,
    partial_content,
    multiple_choices,
    moved_permanently,
    found,
    see_other,
    not_modified,
    temporary_redirect,
    permanent_redirect,
    bad_request,
    unauthorized,
    forbidden,
    not_found,
    method_not_allowed,
    not_acceptable,
    proxy_authentication_required,
    request_timeout,
    conflict,
    gone,
    length_required,
    precondition_failed,
    content_too_large,
    uri_too_long,
    unsupported_media_type,
    range_not_satisfiable,
    expectation_failed,
    misdirected_request,
    unprocessable_content,
    upgrade_required,
    internal_server_error,
    not_implemented,
    bad_gateway,
    service_unavailable,
    gateway_timeout,
    http_version_not_supported,

    pub const codes_u16 = [_]u16{ 100, 101, 200, 201, 202, 203, 204, 205, 206, 300, 301, 302, 303, 304, 307, 308, 400, 401, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 421, 422, 426, 500, 501, 502, 503, 504, 505 };
    pub const codes_string = [_][]const u8{ "100", "101", "200", "201", "202", "203", "204", "205", "206", "300", "301", "302", "303", "304", "307", "308", "400", "401", "403", "404", "405", "406", "407", "408", "409", "410", "411", "412", "413", "414", "415", "416", "417", "421", "422", "426", "500", "501", "502", "503", "504", "505" };

    pub fn toString(self: Status) []const u8 {
        return codes_string[@enumToInt(self)];
    }

    pub fn toU16(self: Status) u16 {
        return codes_u16[@enumToInt(self)];
    }

    pub fn fromString(status_code: []const u8) StatusError!Status {
        for (codes_string) |sc, i| {
            if (std.mem.eql(u8, sc, status_code)) {
                return @intToEnum(Status, i);
            }
        }
        return StatusError.InvalidStatusCode;
    }

    pub fn fromU16(status_code: u16) StatusError!Status {
        for (codes_u16) |sc, i| {
            if (sc == status_code) {
                return @intToEnum(Status, i);
            }
        }
        return StatusError.InvalidStatusCode;
    }
};

test "Status" {
    const status = Status.@"continue";
    try expect(std.mem.eql(u8, status.toString(), "100"));
    try expect(status.toU16() == 100);
    try expect(try Status.fromString("100") == Status.@"continue");
    try expect(try Status.fromU16(100) == Status.@"continue");
    const status_enum_length = @typeInfo(Status).Enum.fields.len;
    try expect(status_enum_length == Status.codes_u16.len);
    try expect(status_enum_length == Status.codes_string.len);
    for (Status.codes_u16) |value, i| {
        try expect(value == try std.fmt.parseUnsigned(u16, Status.codes_string[i], 10));
    }
}
