const std = @import("std");
const log = std.log.scoped(.zest);
const net = std.net;
const rl = @import("request_line.zig");
const h = @import("headers.zig");

pub const Config = struct {
    address: std.net.Address,
    max_request_line_bytes: u64,
    max_headers_bytes: u64,
    max_headers_map_bytes: u64,
    max_body_bytes: u64,
};

pub fn start(comptime config: Config) !void {
    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(config.address);

    var request_line_buffer: [config.max_request_line_bytes]u8 = undefined;
    var request_line_fba = std.heap.FixedBufferAllocator.init(&request_line_buffer);

    var headers_map_buffer: [config.max_headers_map_bytes]u8 = undefined;
    var headers_map_fba = std.heap.FixedBufferAllocator.init(&headers_map_buffer);

    var headers_buffer: [config.max_headers_bytes]u8 = undefined;
    var headers_fba = std.heap.FixedBufferAllocator.init(&headers_buffer);

    while (true) {
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
        _ = parsed_request_line;

        // skips the \n
        try r.skipBytes(1, .{});

        var headers_map = h.Headers.init(headers_map_fba.allocator());
   
        read_headers: while(true) {
            const header = try r.readUntilDelimiterAlloc(headers_fba.allocator(), '\r', config.max_headers_bytes);
            if (std.mem.eql(u8, header, "")) break :read_headers;
            try headers_map.parse(header);
            // skips the \n
            try r.skipBytes(1, .{});             
        }

        std.debug.print("\nAuthorization: {s}\n", .{headers_map.get("Authorization") orelse ""});
        std.debug.print("\nPostman-Token: {s}\n", .{headers_map.get("Postman-Token") orelse ""});

        request_line_fba.reset();
        headers_map_fba.reset();
        headers_fba.reset();
    }
}

// // my_stream: std.net.Stream

// var br = std.io.bufferedReader(conn.stream.reader());
// const r = br.reader(); // get the std.io.Reader from the buffered reader - this is backed by an in-memory buffer to prevent constant syscalls

// // let's read the start line!
// var line_buf: [1024]u8 = undefined; // reasonable max size
// const start_line = try r.readUntilDelimiter(&line_buf, '\n');
// // you'll have to check for the CR yourself
// // then do stuff with start_line
