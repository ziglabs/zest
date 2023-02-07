const std = @import("std");
const json = std.json;
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub const BodyError = error {
    CannotParseBody,
    CannotStringifyBody,
};

pub fn parse(allocator: std.mem.Allocator, comptime T: type, body: []const u8) BodyError!T {
    var stream = json.TokenStream.init(body);
    return json.parse(T, &stream, .{.allocator = allocator}) catch BodyError.CannotParseBody;
}

pub fn stringify(allocator: std.mem.Allocator, comptime T: type, content: T) BodyError![]const u8 {
    return std.json.stringifyAlloc(allocator, content, .{}) catch BodyError.CannotStringifyBody;
}

test "testing 1" {
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

test "testing 2" {
    const Config = struct {};
    const config = Config{};
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const result = try stringify(fba.allocator(), Config, config);
    try expectEqualStrings("{}", result);
}