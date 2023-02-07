const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const StatusError = error{
    InvalidStatusCode,
};

// https://www.rfc-editor.org/rfc/rfc9110#section-15
pub const Status = enum {
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

    pub fn toString(self: Status) []const u8 {
        return status_codes_string[@enumToInt(self)];
    }

    pub fn toU16(self: Status) u16 {
        return status_codes_u16[@enumToInt(self)];
    }
};

// https://www.rfc-editor.org/rfc/rfc9110#section-15
pub const status_codes_u16 = [_]u16{ 100, 101, 200, 201, 202, 203, 204, 205, 206, 300, 301, 302, 303, 304, 307, 308, 400, 401, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 421, 422, 426, 500, 501, 502, 503, 504, 505 };
pub const status_codes_string = [_][]const u8{ "100", "101", "200", "201", "202", "203", "204", "205", "206", "300", "301", "302", "303", "304", "307", "308", "400", "401", "403", "404", "405", "406", "407", "408", "409", "410", "411", "412", "413", "414", "415", "416", "417", "421", "422", "426", "500", "501", "502", "503", "504", "505" };

pub fn parse(status_code: []const u8) StatusError!Status {
    for (status_codes_string) |sc, i| {
        if (std.mem.eql(u8, sc, status_code)) {
            return @intToEnum(Status, i);
        }
    }
    return StatusError.InvalidStatusCode;
}

pub fn code(status_code: u16) StatusError!Status {
    for (status_codes_u16) |sc, i| {
        if (sc == status_code) {
            return @intToEnum(Status, i);
        }
    }
    return StatusError.InvalidStatusCode;
}

test "lengths are equal" {
    const status_enum_length = @typeInfo(Status).Enum.fields.len;
    try expect(status_enum_length == status_codes_u16.len);
    try expect(status_enum_length == status_codes_string.len);
}

test "array values are equal" {
    for (status_codes_u16) |value, i| {
        try expect(value == try std.fmt.parseUnsigned(u16, status_codes_string[i], 10));
    }
}

test "invalid values return an error" {
    const expected_error = StatusError.InvalidStatusCode;
    try expectError(expected_error, parse(""));
    try expectError(expected_error, parse(" "));
    try expectError(expected_error, parse("99"));
    try expectError(expected_error, code(99));
}

test "status code 100" {
    const status = Status.@"continue";
    try expect(std.mem.eql(u8, status.toString(), "100"));
    try expect(status.toU16() == 100);
    try expect((try parse("100")) == Status.@"continue");
    try expect((try code(100)) == Status.@"continue");
}

test "status code 101" {
    const status = Status.switching_protocols;
    try expect(std.mem.eql(u8, status.toString(), "101"));
    try expect(status.toU16() == 101);
    try expect((try parse("101")) == Status.switching_protocols);
    try expect((try code(101)) == Status.switching_protocols);
}

test "status code 200" {
    const status = Status.ok;
    try expect(std.mem.eql(u8, status.toString(), "200"));
    try expect(status.toU16() == 200);
    try expect((try parse("200")) == Status.ok);
    try expect((try code(200)) == Status.ok);
}

test "status code 201" {
    const status = Status.created;
    try expect(std.mem.eql(u8, status.toString(), "201"));
    try expect(status.toU16() == 201);
    try expect((try parse("201")) == Status.created);
    try expect((try code(201)) == Status.created);
}

test "status code 202" {
    const status = Status.accepted;
    try expect(std.mem.eql(u8, status.toString(), "202"));
    try expect(status.toU16() == 202);
    try expect((try parse("202")) == Status.accepted);
    try expect((try code(202)) == Status.accepted);
}

test "status code 203" {
    const status = Status.non_authoritative_information;
    try expect(std.mem.eql(u8, status.toString(), "203"));
    try expect(status.toU16() == 203);
    try expect((try parse("203")) == Status.non_authoritative_information);
    try expect((try code(203)) == Status.non_authoritative_information);
}

test "status code 204" {
    const status = Status.no_content;
    try expect(std.mem.eql(u8, status.toString(), "204"));
    try expect(status.toU16() == 204);
    try expect((try parse("204")) == Status.no_content);
    try expect((try code(204)) == Status.no_content);
}

test "status code 205" {
    const status = Status.reset_content;
    try expect(std.mem.eql(u8, status.toString(), "205"));
    try expect(status.toU16() == 205);
    try expect((try parse("205")) == Status.reset_content);
    try expect((try code(205)) == Status.reset_content);
}

test "status code 206" {
    const status = Status.partial_content;
    try expect(std.mem.eql(u8, status.toString(), "206"));
    try expect(status.toU16() == 206);
    try expect((try parse("206")) == Status.partial_content);
    try expect((try code(206)) == Status.partial_content);
}

test "status code 300" {
    const status = Status.multiple_choices;
    try expect(std.mem.eql(u8, status.toString(), "300"));
    try expect(status.toU16() == 300);
    try expect((try parse("300")) == Status.multiple_choices);
    try expect((try code(300)) == Status.multiple_choices);
}

test "status code 301" {
    const status = Status.moved_permanently;
    try expect(std.mem.eql(u8, status.toString(), "301"));
    try expect(status.toU16() == 301);
    try expect((try parse("301")) == Status.moved_permanently);
    try expect((try code(301)) == Status.moved_permanently);
}

test "status code 302" {
    const status = Status.found;
    try expect(std.mem.eql(u8, status.toString(), "302"));
    try expect(status.toU16() == 302);
    try expect((try parse("302")) == Status.found);
    try expect((try code(302)) == Status.found);
}

test "status code 303" {
    const status = Status.see_other;
    try expect(std.mem.eql(u8, status.toString(), "303"));
    try expect(status.toU16() == 303);
    try expect((try parse("303")) == Status.see_other);
    try expect((try code(303)) == Status.see_other);
}

test "status code 304" {
    const status = Status.not_modified;
    try expect(std.mem.eql(u8, status.toString(), "304"));
    try expect(status.toU16() == 304);
    try expect((try parse("304")) == Status.not_modified);
    try expect((try code(304)) == Status.not_modified);
}

test "status code 307" {
    const status = Status.temporary_redirect;
    try expect(std.mem.eql(u8, status.toString(), "307"));
    try expect(status.toU16() == 307);
    try expect((try parse("307")) == Status.temporary_redirect);
    try expect((try code(307)) == Status.temporary_redirect);
}

test "status code 308" {
    const status = Status.permanent_redirect;
    try expect(std.mem.eql(u8, status.toString(), "308"));
    try expect(status.toU16() == 308);
    try expect((try parse("308")) == Status.permanent_redirect);
    try expect((try code(308)) == Status.permanent_redirect);
}

test "status code 400" {
    const status = Status.bad_request;
    try expect(std.mem.eql(u8, status.toString(), "400"));
    try expect(status.toU16() == 400);
    try expect((try parse("400")) == Status.bad_request);
    try expect((try code(400)) == Status.bad_request);
}

test "status code 401" {
    const status = Status.unauthorized;
    try expect(std.mem.eql(u8, status.toString(), "401"));
    try expect(status.toU16() == 401);
    try expect((try parse("401")) == Status.unauthorized);
    try expect((try code(401)) == Status.unauthorized);
}

test "status code 403" {
    const status = Status.forbidden;
    try expect(std.mem.eql(u8, status.toString(), "403"));
    try expect(status.toU16() == 403);
    try expect((try parse("403")) == Status.forbidden);
    try expect((try code(403)) == Status.forbidden);
}

test "status code 404" {
    const status = Status.not_found;
    try expect(std.mem.eql(u8, status.toString(), "404"));
    try expect(status.toU16() == 404);
    try expect((try parse("404")) == Status.not_found);
    try expect((try code(404)) == Status.not_found);
}

test "status code 405" {
    const status = Status.method_not_allowed;
    try expect(std.mem.eql(u8, status.toString(), "405"));
    try expect(status.toU16() == 405);
    try expect((try parse("405")) == Status.method_not_allowed);
    try expect((try code(405)) == Status.method_not_allowed);
}

test "status code 406" {
    const status = Status.not_acceptable;
    try expect(std.mem.eql(u8, status.toString(), "406"));
    try expect(status.toU16() == 406);
    try expect((try parse("406")) == Status.not_acceptable);
    try expect((try code(406)) == Status.not_acceptable);
}

test "status code 407" {
    const status = Status.proxy_authentication_required;
    try expect(std.mem.eql(u8, status.toString(), "407"));
    try expect(status.toU16() == 407);
    try expect((try parse("407")) == Status.proxy_authentication_required);
    try expect((try code(407)) == Status.proxy_authentication_required);
}

test "status code 408" {
    const status = Status.request_timeout;
    try expect(std.mem.eql(u8, status.toString(), "408"));
    try expect(status.toU16() == 408);
    try expect((try parse("408")) == Status.request_timeout);
    try expect((try code(408)) == Status.request_timeout);
}

test "status code 409" {
    const status = Status.conflict;
    try expect(std.mem.eql(u8, status.toString(), "409"));
    try expect(status.toU16() == 409);
    try expect((try parse("409")) == Status.conflict);
    try expect((try code(409)) == Status.conflict);
}

test "status code 410" {
    const status = Status.gone;
    try expect(std.mem.eql(u8, status.toString(), "410"));
    try expect(status.toU16() == 410);
    try expect((try parse("410")) == Status.gone);
    try expect((try code(410)) == Status.gone);
}

test "status code 411" {
    const status = Status.length_required;
    try expect(std.mem.eql(u8, status.toString(), "411"));
    try expect(status.toU16() == 411);
    try expect((try parse("411")) == Status.length_required);
    try expect((try code(411)) == Status.length_required);
}

test "status code 412" {
    const status = Status.precondition_failed;
    try expect(std.mem.eql(u8, status.toString(), "412"));
    try expect(status.toU16() == 412);
    try expect((try parse("412")) == Status.precondition_failed);
    try expect((try code(412)) == Status.precondition_failed);
}

test "status code 413" {
    const status = Status.content_too_large;
    try expect(std.mem.eql(u8, status.toString(), "413"));
    try expect(status.toU16() == 413);
    try expect((try parse("413")) == Status.content_too_large);
    try expect((try code(413)) == Status.content_too_large);
}

test "status code 414" {
    const status = Status.uri_too_long;
    try expect(std.mem.eql(u8, status.toString(), "414"));
    try expect(status.toU16() == 414);
    try expect((try parse("414")) == Status.uri_too_long);
    try expect((try code(414)) == Status.uri_too_long);
}

test "status code 415" {
    const status = Status.unsupported_media_type;
    try expect(std.mem.eql(u8, status.toString(), "415"));
    try expect(status.toU16() == 415);
    try expect((try parse("415")) == Status.unsupported_media_type);
    try expect((try code(415)) == Status.unsupported_media_type);
}

test "status code 416" {
    const status = Status.range_not_satisfiable;
    try expect(std.mem.eql(u8, status.toString(), "416"));
    try expect(status.toU16() == 416);
    try expect((try parse("416")) == Status.range_not_satisfiable);
    try expect((try code(416)) == Status.range_not_satisfiable);
}

test "status code 417" {
    const status = Status.expectation_failed;
    try expect(std.mem.eql(u8, status.toString(), "417"));
    try expect(status.toU16() == 417);
    try expect((try parse("417")) == Status.expectation_failed);
    try expect((try code(417)) == Status.expectation_failed);
}

test "status code 421" {
    const status = Status.misdirected_request;
    try expect(std.mem.eql(u8, status.toString(), "421"));
    try expect(status.toU16() == 421);
    try expect((try parse("421")) == Status.misdirected_request);
    try expect((try code(421)) == Status.misdirected_request);
}

test "status code 422" {
    const status = Status.unprocessable_content;
    try expect(std.mem.eql(u8, status.toString(), "422"));
    try expect(status.toU16() == 422);
    try expect((try parse("422")) == Status.unprocessable_content);
    try expect((try code(422)) == Status.unprocessable_content);
}

test "status code 426" {
    const status = Status.upgrade_required;
    try expect(std.mem.eql(u8, status.toString(), "426"));
    try expect(status.toU16() == 426);
    try expect((try parse("426")) == Status.upgrade_required);
    try expect((try code(426)) == Status.upgrade_required);
}

test "status code 500" {
    const status = Status.internal_server_error;
    try expect(std.mem.eql(u8, status.toString(), "500"));
    try expect(status.toU16() == 500);
    try expect((try parse("500")) == Status.internal_server_error);
    try expect((try code(500)) == Status.internal_server_error);
}

test "status code 501" {
    const status = Status.not_implemented;
    try expect(std.mem.eql(u8, status.toString(), "501"));
    try expect(status.toU16() == 501);
    try expect((try parse("501")) == Status.not_implemented);
    try expect((try code(501)) == Status.not_implemented);
}

test "status code 502" {
    const status = Status.bad_gateway;
    try expect(std.mem.eql(u8, status.toString(), "502"));
    try expect(status.toU16() == 502);
    try expect((try parse("502")) == Status.bad_gateway);
    try expect((try code(502)) == Status.bad_gateway);
}

test "status code 503" {
    const status = Status.service_unavailable;
    try expect(std.mem.eql(u8, status.toString(), "503"));
    try expect(status.toU16() == 503);
    try expect((try parse("503")) == Status.service_unavailable);
    try expect((try code(503)) == Status.service_unavailable);
}

test "status code 504" {
    const status = Status.gateway_timeout;
    try expect(std.mem.eql(u8, status.toString(), "504"));
    try expect(status.toU16() == 504);
    try expect((try parse("504")) == Status.gateway_timeout);
    try expect((try code(504)) == Status.gateway_timeout);
}

test "status code 505" {
    const status = Status.http_version_not_supported;
    try expect(std.mem.eql(u8, status.toString(), "505"));
    try expect(status.toU16() == 505);
    try expect((try parse("505")) == Status.http_version_not_supported);
    try expect((try code(505)) == Status.http_version_not_supported);
}
