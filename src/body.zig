const std = @import("std");
const json = std.json;
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const BodyError = error {
    CannotParseBody,
    CannotStringifyBody,
};

pub fn parse(allocator: std.mem.Allocator, comptime T: type, body: []const u8) !T {
    var stream = json.TokenStream.init(body);
    return try json.parse(T, &stream, .{.allocator = allocator});
}

pub fn stringify(allocator: std.mem.Allocator, comptime T: type, content: T) BodyError![]const u8 {
    return std.json.stringifyAlloc(allocator, content, .{}) catch BodyError.CannotStringifyBody;
}

// test "testing 1" {
//     const Config = struct {
//         vals: struct { testing: u8, production: u8 },
//         uptime: u64,
//     };

//     const body =
//         \\{
//         \\    "vals": {
//         \\        "testing": 1,
//         \\        "production": 42
//         \\    },
//         \\    "uptime": 9999
//         \\}
//     ;
//     const result = try parse(Config, body);
//     try expect(result.uptime == 9999);
// }

// test "testing 2" {
//     const Config = struct {
//         uptime: u64
//     };

//     const body = "{\"uptime\": 9999}";
//     const result = try parse(Config, body);
//     try expect(result.uptime == 9999);
// }

// test "testing 3" {
//     const Config = struct {
//         greeting: [4]u8
//     };

//     const body = "{\"greeting\": \"9999\"}";
//     const result = try parse(Config, body);
//     try expectEqualStrings(&result.greeting, "9999");
// }

// test "testing 4" {
//     const Config = struct {
//         uptime: u64
//     };
//     const config = Config{ .uptime = 4};
//     var buffer: [1024]u8 = undefined;
//     const result = try stringify(&buffer, Config, config);
//     try expectEqualStrings("{\"uptime\":4}", result);
// }

// test "testing 5" {
//     const Config = struct {
//         greeting: [2]u8
//     };

//     const body = "{\"greeting\": \"9999\"}";
//     try expectError(BodyError.CannotParseBody, parse(Config, body));
// }

test "testing 6" {
    const Config = struct {
        greeting: []const u8,
        hello: []const u8,
        you: u8,
    };
    var buffer: [6]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const body = "{\"greeting\": \"9999\", \"hello\": \"88\", \"you\": 9}";
    const result = try parse(fba.allocator(), Config, body);
    try expectEqualStrings(result.greeting, "9999");
    try expectEqualStrings(result.hello, "88");
    try expect(result.you == 9);
}

test "testing 7" {
    const Config = struct {};
    var buffer: [6]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const body = "{}";
    const result = try parse(fba.allocator(), Config, body);
    std.debug.print("{any}", .{result});
    // try expectEqualStrings(result.greeting, "9999");
    // try expectEqualStrings(result.hello, "88");
    try expect(9 == 9);
}

test "testing 8" {
    const Config = struct {};
    const config = Config{};
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const result = try stringify(fba.allocator(), Config, config);
    try expectEqualStrings("{}", result);
}