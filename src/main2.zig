const std = @import("std");
const net = std.net;

// pub fn main() anyerror!void {
//     const self_addr = try net.Address.resolveIp("127.0.0.1", 8080);
//     var listener = net.StreamServer.init(.{});
//     try (&listener).listen(self_addr);

//     std.log.info("Listening on {}; press Ctrl-C to exit...", .{self_addr});

//     while ((&listener).accept()) |conn| {
//         std.log.info("Accepted Connection from: {}", .{conn.address});
//         try conn.stream.writer().print("HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nhi", .{});
//         conn.stream.close();
//     } else |err| {
//         return err;
//     }
// }

pub fn main() anyerror!void {
    const self_addr = try net.Address.resolveIp("127.0.0.1", 8080);
    var server = net.StreamServer.init(.{});
    try server.listen(self_addr);

    std.log.info("Listening on {}; press Ctrl-C to exit...", .{self_addr});

    while (true) {
        var connection = try server.accept();
        std.log.info("Accepted Connection from: {}", .{connection.address});
        // try connection.stream.writer().print("HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nhi", .{});
        try connection.stream.writer().print("HTTP/1.1 404\r\nConnection: close\r\nContent-Length: 0", .{});

        connection.stream.close();
    } else |err| {
        return err;
    }
}
