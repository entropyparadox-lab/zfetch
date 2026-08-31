const std = @import("std");
const zfetch = @import("zfetch");

const GitHubRepo = struct {
    name: []const u8,
    full_name: []const u8,
    stargazers_count: ?u64 = null,
    forks_count: ?u64 = null,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    var client = zfetch.Client.init(allocator, io);
    defer client.deinit();

    std.debug.print("⚡ zfetch: High-Performance HTTP Client for Zig 0.16.0+\n", .{});
    std.debug.print("----------------------------------------------------\n", .{});

    // 1. One-liner typed JSON GET
    const url = "https://httpbin.org/get";
    std.debug.print("Fetching: {s} ...\n", .{url});

    var resp = client.get(url, .{
        .headers = &.{
            .{ .name = "User-Agent", .value = "zfetch/1.0.0 (Zig 0.16.0)" },
        },
    }) catch |err| {
        std.debug.print("Network request skipped or failed (offline environment): {s}\n", .{@errorName(err)});
        return;
    };
    defer resp.deinit();

    std.debug.print("HTTP Status: {d} (Success: {s})\n", .{ @intFromEnum(resp.status), if (resp.isSuccess()) "YES" else "NO" });
    std.debug.print("Body Length: {d} bytes\n", .{resp.body.len});
}
