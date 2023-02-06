const std = @import("std");
const expect = std.testing.expect;
const log = std.log.scoped(.zest);
const net = std.net;
const rl = @import("request_line.zig");
const req = @import("request.zig");
const res = @import("response.zig");
const sl = @import("status_line.zig");
const h = @import("headers.zig");
const b = @import("body.zig");
const s = @import("status.zig");
const v = @import("version.zig");

// address defaults to 127.0.0.1:8080
// all byte counts defaults to 1kb
pub const Config = struct {
    address: std.net.Address,
    max_read_request_line_bytes: u64 = 1024,
    max_read_request_headers_bytes: u64 = 1024,
    max_request_headers_map_bytes: u64 = 1024,
    max_response_headers_map_bytes: u64 = 1024,
    max_read_request_body_bytes: u64 = 1024,
    max_request_body_parse_bytes: u64 = 1024,
    max_response_body_bytes: u64 = 1024,
    max_response_body_stringify_bytes: u64 = 1024,

    pub fn init(address_name: []const u8, address_port: u16, max_read_request_line_bytes: u64, max_read_request_headers_bytes: u64, max_request_headers_map_bytes: u64, max_response_headers_map_bytes: u64, max_read_request_body_bytes: u64, max_request_body_parse_bytes: u64, max_response_body_bytes: u64, max_response_body_stringify_bytes: u64) !Config {
        return Config{ .address = try std.net.Address.parseIp(address_name, address_port), .max_read_request_line_bytes = max_read_request_line_bytes, .max_read_request_headers_bytes = max_read_request_headers_bytes, .max_request_headers_map_bytes = max_request_headers_map_bytes, .max_response_headers_map_bytes = max_response_headers_map_bytes, .max_read_request_body_bytes = max_read_request_body_bytes, .max_request_body_parse_bytes = max_request_body_parse_bytes, .max_response_body_bytes = max_response_body_bytes, .max_response_body_stringify_bytes = max_response_body_stringify_bytes };
    }

    pub fn default() !Config {
        return Config{ .address = try std.net.Address.parseIp("127.0.0.1", 8080) };
    }
};

pub fn start(comptime config: Config, comptime routes: anytype) !void {
    if (@typeInfo(@TypeOf(routes)) != .Struct) @compileError("start expects routes to be an anonymous list literal");
    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(config.address);

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
    // TODO: handle errors and respond appropriately
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
                log.err("Could not accept connection: '{s}'", .{@errorName(err)});
                continue;
            },
            else => return err,
        };

        var br = std.io.bufferedReader(connection.stream.reader());
        const r = br.reader();

        var bw = std.io.bufferedWriter(connection.stream.writer());
        const w = bw.writer();

        const read_request_line = try r.readUntilDelimiterAlloc(read_request_line_fba.allocator(), '\r', config.max_read_request_line_bytes);
        const request_line = try rl.parse(read_request_line);

        // const route = get_route: inline for (std.meta.fields(@TypeOf(routes))) |field| {
        //     const route = @field(routes, field.name);
        //     if (std.mem.eql(u8, route.path, request_line.path)) {
        //         break :get_route route;
        //     }
        // } else {
        //     try w.writeAll("HTTP/1.1 404\r\n\r\n");
        //     try bw.flush();
        //     connection.stream.close();
        //     continue;
        // };

        // const route = get_route: inline for (routes) |route| {
        //     if (std.mem.eql(u8, route.path, request_line.path)) {
        //         break :get_route route;
        //     }
        // } else {
        //     try w.writeAll("HTTP/1.1 404\r\n\r\n");
        //     try bw.flush();
        //     connection.stream.close();
        //     continue;
        // };

        // const route = get_route: inline for (@typeInfo(@TypeOf(routes)).Struct.fields) |field| {
        //     const route = @field(routes, field.name);
        //     if (std.mem.eql(u8, route.path, request_line.path)) {
        //         break :get_route route;
        //     }
        // } else {
        //     try w.writeAll("HTTP/1.1 404\r\n\r\n");
        //     try bw.flush();
        //     connection.stream.close();
        //     continue;
        // };

        // skips the \n
        try r.skipBytes(1, .{});

        var request_headers_map = h.Headers.init(request_headers_map_fba.allocator());
        read_request_headers: while (true) {
            const read_request_header = try r.readUntilDelimiterAlloc(read_request_headers_fba.allocator(), '\r', config.max_read_request_headers_bytes);
            if (std.mem.eql(u8, read_request_header, "")) break :read_request_headers;
            try request_headers_map.parse(read_request_header);
            // skips the \n
            try r.skipBytes(1, .{});
        }

        // skips the \n
        try r.skipBytes(1, .{});

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

        var request_body_buffer = try read_request_body_fba.allocator().alloc(u8, content_length_number);
        const read_request_body_count = try r.readAll(request_body_buffer);
        if (read_request_body_count > content_length_number) {
            try w.writeAll("HTTP/1.1 400\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        }

        const request_body = try b.parse(request_body_parse_fba.allocator(), route.request_body_type, request_body_buffer);
        const request = req.Build(request_line, request_headers_map, route.request_body_type, request_body);
        var response_headers_map = h.Headers.init(response_headers_map_fba.allocator());
        var response = res.Build(sl.StatusLine{ .version = v.Version.http11, .status = s.Status.ok }, response_headers_map, route.response_body_type, response_body_fba.allocator());
        try route.handler(request, &response);

        std.debug.print("\nDog: {s}", .{response.headers.get("Dog") orelse unreachable});
        const response_body = if (response.body) |body| body else {
            try w.writeAll("HTTP/1.1 500\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };
        _ = response_body;
        // std.debug.print("\nbye: {d}", .{response_body.bye});
        try w.writeAll("HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nhi");
        try bw.flush();
        connection.stream.close();
    }
}
