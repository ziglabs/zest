const std = @import("std");
const expect = std.testing.expect;
const log = std.log.scoped(.zest);
const net = std.net;
const rl = @import("request_line.zig");
const req = @import("request.zig");
const h = @import("headers.zig");
const b = @import("body.zig");

pub const Config = struct {
    address: std.net.Address,
    max_request_line_bytes: u64,
    max_headers_bytes: u64,
    max_headers_map_bytes: u64,
    max_body_bytes: u64,
};

pub fn start(comptime config: Config, routes: anytype) !void {
    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(config.address);

    var request_line_buffer: [config.max_request_line_bytes]u8 = undefined;
    var request_line_fba = std.heap.FixedBufferAllocator.init(&request_line_buffer);

    var headers_buffer: [config.max_headers_bytes]u8 = undefined;
    var headers_fba = std.heap.FixedBufferAllocator.init(&headers_buffer);

    var headers_map_buffer: [config.max_headers_map_bytes]u8 = undefined;
    var headers_map_fba = std.heap.FixedBufferAllocator.init(&headers_map_buffer);

    var body_buffer: [config.max_body_bytes]u8 = undefined;
    var body_fba = std.heap.FixedBufferAllocator.init(&body_buffer);

    var body_parse_buffer: [config.max_body_bytes]u8 = undefined;
    var body_parse_fba = std.heap.FixedBufferAllocator.init(&body_parse_buffer);

    while (true) : ({
        request_line_fba.reset();
        headers_map_fba.reset();
        headers_fba.reset();
        body_fba.reset();
        body_parse_fba.reset();
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

        const read_request_line = try r.readUntilDelimiterAlloc(request_line_fba.allocator(), '\r', config.max_request_line_bytes);
        const parsed_request_line = try rl.parse(read_request_line);

        const route = get_route: inline for (routes) |route| {
            if (std.mem.eql(u8, route.path, parsed_request_line.path)) {
                break :get_route route;
            }
        } else {
            log.err("Path not found - returning 404", .{});
            try w.writeAll("HTTP/1.1 404\r\n\r\n");
            try bw.flush();
            connection.stream.close();
            continue;
        };

        // skips the \n
        try r.skipBytes(1, .{});

        var headers_map = h.Headers.init(headers_map_fba.allocator());

        read_headers: while (true) {
            const read_header = try r.readUntilDelimiterAlloc(headers_fba.allocator(), '\r', config.max_headers_bytes);
            if (std.mem.eql(u8, read_header, "")) break :read_headers;
            try headers_map.parse(read_header);
            // skips the \n
            try r.skipBytes(1, .{});
        }

        // skips the \n
        try r.skipBytes(1, .{});

        const read_body = try r.readAllAlloc(body_fba.allocator(),config.max_body_bytes);
        std.debug.print("{s}", .{read_body});
        const parsed_body = try b.parse(body_parse_fba.allocator(), route.request_body_type, read_body);

        const request = req.Build(parsed_request_line, headers_map, route.request_body_type, parsed_body);

        const a = request.headers.get("Content-Type") orelse "";
        std.debug.print("\nContent-Type: {s}\n", .{a});

        std.debug.print("\nhi: {d}\n", .{request.body.hi});

        try w.writeAll("HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nhi");
        try bw.flush();
        connection.stream.close();
    }
}

// curl -X POST http://127.0.0.1:8080/hello -H "Content-Type: application/json" -d '{"hi": 8}'
