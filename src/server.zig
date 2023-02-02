const std = @import("std");
const expect = std.testing.expect;
const log = std.log.scoped(.zest);
const net = std.net;
const rl = @import("request_line.zig");
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

        const read_request_line = try r.readUntilDelimiterAlloc(request_line_fba.allocator(), '\r', config.max_request_line_bytes);
        const parsed_request_line = try rl.parse(read_request_line);
        const route = get_route: inline for (routes) |route| {
            if (std.mem.eql(u8, route.path, parsed_request_line.path)) {
                break :get_route route;
            }
        } else {
            log.err("Path not found - returning 404", .{});
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

        const read_body = try r.readUntilDelimiterOrEofAlloc(body_fba.allocator(), '\r', config.max_body_bytes);
        const parsed_body = try b.parse(body_parse_fba.allocator(), route.request_body_type, read_body orelse "");
        std.debug.print("{d}", .{parsed_body.hi});

        // const a = headers_map.get("Authorization") orelse "";
        // const p = headers_map.get("Postman-Token") orelse "";
        // std.debug.print("\nAuthorization: {s}\n", .{a});
        // std.debug.print("\nPostman-Token: {s}\n", .{p});


    }
}

test "test" {
    try expect(true);
}

// // my_stream: std.net.Stream

// var br = std.io.bufferedReader(conn.stream.reader());
// const r = br.reader(); // get the std.io.Reader from the buffered reader - this is backed by an in-memory buffer to prevent constant syscalls

// // let's read the start line!
// var line_buf: [1024]u8 = undefined; // reasonable max size
// const start_line = try r.readUntilDelimiter(&line_buf, '\n');
// // you'll have to check for the CR yourself
// // then do stuff with start_line
