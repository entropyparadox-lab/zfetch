const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Response = struct {
    allocator: Allocator,
    status: std.http.Status,
    body: []const u8,

    pub fn deinit(self: *Response) void {
        self.allocator.free(self.body);
    }

    pub fn isSuccess(self: Response) bool {
        const code = @intFromEnum(self.status);
        return code >= 200 and code < 300;
    }

    pub fn isClientError(self: Response) bool {
        const code = @intFromEnum(self.status);
        return code >= 400 and code < 500;
    }

    pub fn isServerError(self: Response) bool {
        const code = @intFromEnum(self.status);
        return code >= 500 and code < 600;
    }

    /// Deserializes JSON response body into concrete Zig type T using std.json
    pub fn json(self: Response, comptime T: type) !std.json.Parsed(T) {
        return std.json.parseFromSlice(
            T,
            self.allocator,
            self.body,
            .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
        );
    }

    /// Deserializes JSON response body into concrete Zig type T with custom options
    pub fn jsonWithOptions(self: Response, comptime T: type, options: std.json.ParseOptions) !std.json.Parsed(T) {
        return std.json.parseFromSlice(T, self.allocator, self.body, options);
    }
};

test "response status predicates and json deserialization" {
    const allocator = std.testing.allocator;

    const User = struct {
        id: u64,
        username: []const u8,
        is_active: bool,
    };

    const raw_json = "{\"id\": 42, \"username\": \"cycorld\", \"is_active\": true}";
    const body = try allocator.dupe(u8, raw_json);

    var resp = Response{
        .allocator = allocator,
        .status = .ok,
        .body = body,
    };
    defer resp.deinit();

    try std.testing.expect(resp.isSuccess());
    try std.testing.expect(!resp.isClientError());
    try std.testing.expect(!resp.isServerError());

    var parsed = try resp.json(User);
    defer parsed.deinit();

    try std.testing.expectEqual(@as(u64, 42), parsed.value.id);
    try std.testing.expectEqualStrings("cycorld", parsed.value.username);
    try std.testing.expect(parsed.value.is_active);
}

test "response status code classification and error json handling" {
    const allocator = std.testing.allocator;

    const Dummy = struct { val: u32 };

    // 1. Client Error (404)
    var resp_404 = Response{
        .allocator = allocator,
        .status = .not_found,
        .body = try allocator.dupe(u8, "{\"error\": \"not found\"}"),
    };
    defer resp_404.deinit();
    try std.testing.expect(!resp_404.isSuccess());
    try std.testing.expect(resp_404.isClientError());
    try std.testing.expect(!resp_404.isServerError());

    // 2. Server Error (500)
    var resp_500 = Response{
        .allocator = allocator,
        .status = .internal_server_error,
        .body = try allocator.dupe(u8, "Internal Server Error"),
    };
    defer resp_500.deinit();
    try std.testing.expect(!resp_500.isSuccess());
    try std.testing.expect(!resp_500.isClientError());
    try std.testing.expect(resp_500.isServerError());

    // 3. Malformed JSON returns error
    try std.testing.expectError(error.SyntaxError, resp_500.json(Dummy));
}
