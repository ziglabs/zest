const std = @import("std");
const expect = std.testing.expect;
const log = std.log.scoped(.zest);
const net = std.net;
const rl = @import("request_line.zig");
const req = @import("request.zig");
const res = @import("response.zig");
const sl = @import("status_line.zig");
const h = @import("headers.zig");
const s = @import("status.zig");
const v = @import("version.zig");
const Router = @import("router.zig").Router;

pub const Config = struct {
    address: std.net.Address,
    max_read_request_line_bytes: u64,
    max_read_request_headers_bytes: u64,
    max_request_headers_map_bytes: u64,
    max_response_headers_map_bytes: u64,
    max_read_request_body_bytes: u64,
    max_request_body_parse_bytes: u64,
    max_response_body_bytes: u64,
    max_response_body_stringify_bytes: u64,

    pub fn init(address_name: []const u8, address_port: u16, buffer_bytes: u64) !Config {
        return Config{ .address = try std.net.Address.parseIp(address_name, address_port), .max_read_request_line_bytes = buffer_bytes, .max_read_request_headers_bytes = buffer_bytes, .max_request_headers_map_bytes = buffer_bytes, .max_response_headers_map_bytes = buffer_bytes, .max_read_request_body_bytes = buffer_bytes, .max_request_body_parse_bytes = buffer_bytes, .max_response_body_bytes = buffer_bytes, .max_response_body_stringify_bytes = buffer_bytes };
    }
};

pub fn start(comptime config: Config, comptime router: Router) !void {
    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(config.address);

    log.info("listening at {}", .{config.address});

    var read_request_line_buffer: [config.max_read_request_line_bytes]u8 = undefined;
    var read_request_line_fba = std.heap.FixedBufferAllocator.init(&read_request_line_buffer);

    var read_request_headers_buffer: [config.max_read_request_headers_bytes]u8 = undefined;
    var read_request_headers_fba = std.heap.FixedBufferAllocator.init(&read_request_headers_buffer);

    var request_headers_map_buffer: [config.max_request_headers_map_bytes]u8 = undefined;
    var request_headers_map_fba = std.heap.FixedBufferAllocator.init(&request_headers_map_buffer);

    var response_headers_map_buffer: [config.max_response_headers_map_bytes]u8 = undefined;
    var response_headers_map_fba = std.heap.FixedBufferAllocator.init(&response_headers_map_buffer);

    var read_request_body_buffer: [config.max_read_request_body_bytes]u8 = undefined;
    var read_request_body_fba = std.heap.FixedBufferAllocator.init(&read_request_body_buffer);

    var request_body_parse_buffer: [config.max_request_body_parse_bytes]u8 = undefined;
    var request_body_parse_fba = std.heap.FixedBufferAllocator.init(&request_body_parse_buffer);

    var response_body_buffer: [config.max_response_body_bytes]u8 = undefined;
    var response_body_fba = std.heap.FixedBufferAllocator.init(&response_body_buffer);

    var response_body_stringify_buffer: [config.max_response_body_stringify_bytes]u8 = undefined;
    var response_body_stringify_fba = std.heap.FixedBufferAllocator.init(&response_body_stringify_buffer);

    while (true) : ({
        read_request_line_fba.reset();
        read_request_headers_fba.reset();
        request_headers_map_fba.reset();
        response_headers_map_fba.reset();
        read_request_body_fba.reset();
        request_body_parse_fba.reset();
        response_body_fba.reset();
        response_body_stringify_fba.reset();
    }) {
        var connection = server.accept() catch |err| switch (err) {
            error.ConnectionResetByPeer, error.ConnectionAborted => {
                log.err("could not accept connection: '{s}'", .{@errorName(err)});
                continue;
            },
            else => return err,
        };

        var br = std.io.bufferedReader(connection.stream.reader());
        const r = br.reader();

        var bw = std.io.bufferedWriter(connection.stream.writer());
        const w = bw.writer();

        const read_request_line = r.readUntilDelimiterAlloc(read_request_line_fba.allocator(), '\r', config.max_read_request_line_bytes) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        const request_line = rl.parse(read_request_line) catch |err| switch (err) {
            error.InvalidRequestLine, error.InvalidPath => {
                try w.writeAll("HTTP/1.1 400\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
            error.UnsupportedMethod => {
                try w.writeAll("HTTP/1.1 405\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
            error.UnsupportedVersion => {
                try w.writeAll("HTTP/1.1 505\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
        };
        const route = router.find(request_line.path) orelse {
            try w.writeAll("HTTP/1.1 404\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        // skips the \n
        r.skipBytes(1, .{}) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        var request_headers_map = h.Headers.init(request_headers_map_fba.allocator());
        read_request_headers: while (true) {
            const read_request_header = r.readUntilDelimiterAlloc(read_request_headers_fba.allocator(), '\r', config.max_read_request_headers_bytes) catch {
                try w.writeAll("HTTP/1.1 400\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            };
            if (std.mem.eql(u8, read_request_header, "")) break :read_request_headers;
            request_headers_map.parse(read_request_header) catch {
                try w.writeAll("HTTP/1.1 400\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            };
            // skips the \n
            r.skipBytes(1, .{}) catch {
                try w.writeAll("HTTP/1.1 400\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            };
        }
        // skips the \n
        r.skipBytes(1, .{}) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        const content_length_string = request_headers_map.get("Content-Length") orelse {
            try w.writeAll("HTTP/1.1 411\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        const content_length_number = std.fmt.parseUnsigned(u64, content_length_string, 10) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        if (content_length_number > config.max_read_request_body_bytes) {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }
        const content_type = request_headers_map.get("Content-Type") orelse {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        if (!std.mem.eql(u8, content_type, "application/json")) {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }
        var request_body_raw = read_request_body_fba.allocator().alloc(u8, content_length_number) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        const read_request_body_count = r.readAll(request_body_raw) catch {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        if (!std.json.validate(request_body_raw)) {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }
        if (read_request_body_count > content_length_number) {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }
        const request = req.Request{ .request_line = request_line, .headers = request_headers_map, .body_raw = request_body_raw, .body_allocator = request_body_parse_fba.allocator() };
        var response_headers_map = h.Headers.init(response_headers_map_fba.allocator());
        var response = res.Response{
            .status_line = sl.StatusLine{ .version = v.Version.http11, .status = s.Status.ok },
            .headers = response_headers_map,
            .body_raw = "{}",
            .body_allocator = response_body_fba.allocator(),
            .body_stringify_allocator = response_body_stringify_fba.allocator(),
        };
        route.handler(request, &response) catch |err| switch (err) {
            error.CannotParseBody => {
                try w.writeAll("HTTP/1.1 400\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
            error.CannotStringifyBody, error.InvalidHeader, error.InvalidHeaderName, error.InvalidHeaderValue, error.OutOfSpace, error.InvalidStatusLine, error.InvalidStatusCode, error.UnsupportedVersion => {
                try w.writeAll("HTTP/1.1 500\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
            else => {
                try w.writeAll("HTTP/1.1 500\r\n\r\n");
                try bw.flush();
                connection.stream.close();
                continue;
            },
        };
        if (!std.json.validate(response.body_raw)) {
            try w.writeAll("HTTP/1.1 500\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }
        // status line
        try w.print("{s} {s}\r\n", .{ response.status_line.version.toString(), response.status_line.status.toString() });
        // headers
        try w.writeAll("Connection: close\r\n");
        try w.writeAll("Content-Type: application/json\r\n");
        try w.print("Content-Length: {d}\r\n", .{response.body_raw.len});
        var headers_iterator = response.headers.iterator();
        while (headers_iterator.next()) |header| {
            try w.print("{s}: {s}\r\n", .{header.key_ptr.*, header.value_ptr.*});
        }
        // body
        try w.print("\r\n{s}", .{response.body_raw});
        try bw.flush();
        connection.stream.close();
    }
}
