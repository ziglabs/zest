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

pub const Error = scheme.SchemeError || host.HostError || port.PortError || path.PathError;

pub const Url = struct {
    scheme: scheme.Scheme,
    host: host.Host,
    port: u16,
    path: []const u8,

    pub fn format(self: Url, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.writeAll(self.scheme.toString());
        try writer.writeAll("://");
        switch (self.host) {
            .ip => try writer.print("{any}", .{self.host.ip}),
            .name => {
                try writer.writeAll(self.host.name);
                try writer.print(":{d}", .{self.port});
            },
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

    const port_colon_index = if (std.mem.indexOf(u8, slice, ":")) |index| index else -1;
    const slash_index = if (std.mem.indexOf(u8, slice, "/")) |index| index else return UrlError.InvalidUrl;

    const parsed_host = if (port_colon_index == -1) {
        try host.parse(slice[0..slash_index]);
    } else if (slash_index - port_colon_index > 0) {
        try host.parse(slice[0..port_colon_index]);
    } else {
         return UrlError.InvalidUrl;
    };

    const parsed_port = if (port_colon_index == -1) {
        port.fromScheme(parsed_scheme);
    } else if (slash_index - port_colon_index > 0) {
        try port.parse(slice[port_colon_index + 1..slash_index]);
    } else {
        return UrlError.InvalidUrl;
    };
    const parsed_path = try path.parse(slice);
    return Url{.scheme = parsed_scheme, .host = parsed_host,}
}

test "format" {
    const url = Url{ .scheme = scheme.Scheme.http, .host = try host.parse("hello.com"), .port = 8080, .path = try path.parse("/hello/there") };
    try expectFmt("http://hello.com:8080/hello/there", "{}", .{url});
}
