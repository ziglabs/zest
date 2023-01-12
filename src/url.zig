const std = @import("std");
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectFmt = std.testing.expectFmt;
const expectError = std.testing.expectError;

const scheme = @import("scheme.zig");
const host = @import("host.zig");
const port = @import("port.zig");
const path = @import("path.zig");

pub const UrlError = error{InvalidUrl};

pub const Error = UrlError || scheme.SchemeError || host.HostError || port.PortError || path.PathError;

pub const Url = struct {
    scheme: scheme.Scheme,
    host: []const u8,
    port: ?u16,
    path: []const u8,

    pub fn format(self: Url, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.writeAll(self.scheme.toString());
        try writer.writeAll("://");
        try writer.writeAll(self.host);
        if (self.port) |port_exists| {
            try writer.print(":{d}", .{port_exists});
        }
        try writer.writeAll(self.path);
    }
};

pub fn parse(url: []const u8) Error!Url {
    if (url.len == 0) return UrlError.InvalidUrl;
    if (std.mem.count(u8, url, "://") != 1) return UrlError.InvalidUrl;

    var iterator = std.mem.split(u8, url, "://");
    var slice = iterator.first();

    const parsed_scheme = try scheme.parse(slice);

    slice = if (iterator.next()) |s| s else return UrlError.InvalidUrl;

    const port_colon_index = std.mem.indexOf(u8, slice, ":");
    const slash_index = if (std.mem.indexOf(u8, slice, "/")) |index| index else return UrlError.InvalidUrl;

    const parsed_port = if (port_colon_index) |index| blk: {
        if (slash_index - index > 1) {
            break :blk try port.parse(slice[(index + 1)..slash_index]);
        } else {
            return UrlError.InvalidUrl;
        }
    } else null;

    const parsed_host = if (port_colon_index) |index| blk: {
        if (index < slash_index) {
            break :blk try host.parse(slice[0..index]);
        } else return UrlError.InvalidUrl;
    } else try host.parse(slice[0..slash_index]);

    const parsed_path = try path.parse(slice[slash_index..]);
    return Url{ .scheme = parsed_scheme, .host = parsed_host, .port = parsed_port, .path = parsed_path };
}

test "format" {
    var url = Url{ .scheme = scheme.Scheme.http, .host = try host.parse("hello.com"), .port = 8080, .path = try path.parse("/hello/there") };
    try expectFmt("http://hello.com:8080/hello/there", "{}", .{url});

    url = Url{ .scheme = scheme.Scheme.http, .host = try host.parse("hello.com"), .port = null, .path = try path.parse("/hello/there") };
    try expectFmt("http://hello.com/hello/there", "{}", .{url});

    url = Url{ .scheme = scheme.Scheme.http, .host = try host.parse("172.16.254.1"), .port = 8080, .path = try path.parse("/hello/there") };
    try expectFmt("http://172.16.254.1:8080/hello/there", "{}", .{url});

    url = Url{ .scheme = scheme.Scheme.http, .host = try host.parse("[2002:db8::8a3f:362:7897]"), .port = 8080, .path = try path.parse("/") };
    try expectFmt("http://[2002:db8::8a3f:362:7897]:8080/", "{}", .{url});
}

test "parse 1" {
    const url_to_parse = "http://172.16.254.1:8080/hello/there";
    const url = try parse(url_to_parse);
    try expectEqualStrings(url.scheme.toString(), "http");
    try expectEqualStrings(url.host, "172.16.254.1");
    try expect(url.port.? == 8080);
    try expectEqualStrings(url.path, "/hello/there");
}

test "parse 2" {
    const url_to_parse = "http://172.16.254.1/hello/there";
    const url = try parse(url_to_parse);
    try expectEqualStrings(url.scheme.toString(), "http");
    try expectEqualStrings(url.host, "172.16.254.1");
    try expect(url.port == null);
    try expectEqualStrings(url.path, "/hello/there");
}
