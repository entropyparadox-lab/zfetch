const std = @import("std");

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const RequestOptions = struct {
    headers: []const Header = &.{},
    bearer_token: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    accept: ?[]const u8 = null,
    body: ?[]const u8 = null,
    keep_alive: bool = true,
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,

    pub fn toStd(self: Method) std.http.Method {
        return switch (self) {
            .GET => .GET,
            .POST => .POST,
            .PUT => .PUT,
            .DELETE => .DELETE,
            .PATCH => .PATCH,
            .HEAD => .HEAD,
            .OPTIONS => .OPTIONS,
        };
    }
};
