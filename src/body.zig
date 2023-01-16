const std = @import("std");
const json = std.json;
const expect = std.testing.expect;


pub fn parse(comptime T: type, body: []const u8) !T {
    var stream = json.TokenStream.init(body);
    return try json.parse(T, &stream, .{});
}

pub fn stringify(buffer: []u8, comptime T: type, content: T) ![]const u8 {
    var fba = std.heap.FixedBufferAllocator.init(buffer);
    return try std.json.stringifyAlloc(fba.allocator(), content, .{});
}

test "testing 1" {
    const Config = struct {
        vals: struct { testing: u8, production: u8 },
        uptime: u64,
    };

    const body =
        \\{
        \\    "vals": {
        \\        "testing": 1,
        \\        "production": 42
        \\    },
        \\    "uptime": 9999
        \\}
    ;
    const result = try parse(Config, body);
    try expect(result.uptime == 9999);
}

test "testing 2" {
    const Config = struct {
        uptime: u64
    };

    const body = "{\"uptime\": 9999}";
    const result = try parse(Config, body);
    try expect(result.uptime == 9999);
}

test "testing 3" {
    const Config = struct {
        greating: [4]u8
    };

    const body = "{\"greating\": \"9999\"}";
    const result = try parse(Config, body);
    try expect(std.mem.eql(u8, &result.greating, "9999"));
}

test "testing 4" {
    const Config = struct {
        uptime: u64
    };
    const config = Config{ .uptime = 4};
    var buffer: [1024]u8 = undefined;
    const result = try stringify(&buffer, Config, config);
    try expect(std.mem.eql(u8, "{\"uptime\":4}", result));
}
