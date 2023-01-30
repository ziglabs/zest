const std = @import("std");
const log = std.log.scoped(.zest);
const net = std.net;
const sl = @import("start_line.zig");
const h = @import("headers.zig");

pub fn start(address: net.Address) !void {
    var server = net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(address);
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
        var start_line_buff: [1024]u8 = undefined;
        const start_line = try r.readUntilDelimiter(&start_line_buff, '\r');
        const start_line_result = try sl.StartLine.request.parse(start_line);
        std.debug.print("\npath: {s}\n", .{start_line_result.request.path});

        // skips the \n
        try r.skipBytes(1, .{});

        var headers_buff: [1024]u8 = undefined;
        const header = try r.readUntilDelimiter(&headers_buff, '\r');

        var buffer: [300]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        var headers = h.Headers.init(fba.allocator());

        try headers.parse(header);
        std.debug.print("header: {s}", .{headers.get("Authorization") orelse ""});
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
