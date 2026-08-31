const std = @import("std");
const Allocator = std.mem.Allocator;

pub const types = @import("types.zig");
pub const response = @import("response.zig");
pub const client = @import("client.zig");

pub const Client = client.Client;
pub const Response = response.Response;
pub const Header = types.Header;
pub const RequestOptions = types.RequestOptions;
pub const Method = types.Method;

/// One-shot GET request
pub fn get(allocator: Allocator, io: std.Io, url: []const u8, options: RequestOptions) !Response {
    var c = Client.init(allocator, io);
    defer c.deinit();
    return c.get(url, options);
}

/// One-shot POST request
pub fn post(allocator: Allocator, io: std.Io, url: []const u8, body: ?[]const u8, options: RequestOptions) !Response {
    var c = Client.init(allocator, io);
    defer c.deinit();
    return c.post(url, body, options);
}

/// One-shot typed GET JSON request
pub fn getJson(comptime T: type, allocator: Allocator, io: std.Io, url: []const u8, options: RequestOptions) !std.json.Parsed(T) {
    var c = Client.init(allocator, io);
    defer c.deinit();
    return c.getJson(T, url, options);
}

/// One-shot typed POST JSON request
pub fn postJson(comptime RespT: type, allocator: Allocator, io: std.Io, url: []const u8, payload: anytype, options: RequestOptions) !std.json.Parsed(RespT) {
    var c = Client.init(allocator, io);
    defer c.deinit();
    return c.postJson(RespT, url, payload, options);
}

test {
    _ = types;
    _ = response;
    _ = client;
}
