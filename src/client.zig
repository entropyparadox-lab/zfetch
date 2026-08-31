const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("types.zig");
const response_mod = @import("response.zig");

pub const Client = struct {
    allocator: Allocator,
    io: std.Io,
    http_client: std.http.Client,
    ca_scanned: bool = false,

    pub fn init(allocator: Allocator, io: std.Io) Client {
        return .{
            .allocator = allocator,
            .io = io,
            .http_client = .{ .allocator = allocator, .io = io },
        };
    }

    pub fn deinit(self: *Client) void {
        self.http_client.deinit();
    }

    pub fn ensureCaBundle(self: *Client) !void {
        if (!self.ca_scanned) {
            try self.http_client.ca_bundle.rescan(self.allocator);
            self.ca_scanned = true;
        }
    }

    /// Performs an arbitrary HTTP request
    pub fn fetch(self: *Client, method: types.Method, url: []const u8, options: types.RequestOptions) !response_mod.Response {
        try self.ensureCaBundle();

        var extra_headers: std.ArrayList(std.http.Header) = .empty;
        defer extra_headers.deinit(self.allocator);

        // 1. Add user extra headers
        for (options.headers) |h| {
            try extra_headers.append(self.allocator, .{ .name = h.name, .value = h.value });
        }

        // 2. Bearer auth header
        var auth_buf: [512]u8 = undefined;
        if (options.bearer_token) |token| {
            const auth_val = try std.fmt.bufPrint(&auth_buf, "Bearer {s}", .{token});
            try extra_headers.append(self.allocator, .{ .name = "Authorization", .value = auth_val });
        }

        // 3. Accept header
        if (options.accept) |acc| {
            try extra_headers.append(self.allocator, .{ .name = "Accept", .value = acc });
        }

        var allocating = std.Io.Writer.Allocating.init(self.allocator);
        defer allocating.deinit();

        var req_headers = std.http.Client.Request.Headers{};
        if (options.content_type) |ct| {
            req_headers.content_type = .{ .override = ct };
        }

        const fetch_res = try self.http_client.fetch(.{
            .location = .{ .url = url },
            .method = method.toStd(),
            .payload = options.body,
            .headers = req_headers,
            .extra_headers = extra_headers.items,
            .response_writer = &allocating.writer,
            .keep_alive = options.keep_alive,
        });

        var array_list = allocating.toArrayList();
        const body_slice = try array_list.toOwnedSlice(self.allocator);

        return response_mod.Response{
            .allocator = self.allocator,
            .status = fetch_res.status,
            .body = body_slice,
        };
    }

    pub fn get(self: *Client, url: []const u8, options: types.RequestOptions) !response_mod.Response {
        return self.fetch(.GET, url, options);
    }

    pub fn post(self: *Client, url: []const u8, body: ?[]const u8, options: types.RequestOptions) !response_mod.Response {
        var opt = options;
        opt.body = body;
        return self.fetch(.POST, url, opt);
    }

    pub fn put(self: *Client, url: []const u8, body: ?[]const u8, options: types.RequestOptions) !response_mod.Response {
        var opt = options;
        opt.body = body;
        return self.fetch(.PUT, url, opt);
    }

    pub fn patch(self: *Client, url: []const u8, body: ?[]const u8, options: types.RequestOptions) !response_mod.Response {
        var opt = options;
        opt.body = body;
        return self.fetch(.PATCH, url, opt);
    }

    pub fn delete(self: *Client, url: []const u8, options: types.RequestOptions) !response_mod.Response {
        return self.fetch(.DELETE, url, options);
    }

    /// High-level typed GET helper that fetches JSON and deserializes to T
    pub fn getJson(self: *Client, comptime T: type, url: []const u8, options: types.RequestOptions) !std.json.Parsed(T) {
        var opt = options;
        if (opt.accept == null) opt.accept = "application/json";

        var resp = try self.get(url, opt);
        defer resp.deinit();

        return resp.json(T);
    }

    /// High-level typed POST helper that serializes payload struct to JSON and deserializes response JSON to T
    pub fn postJson(self: *Client, comptime RespT: type, url: []const u8, payload: anytype, options: types.RequestOptions) !std.json.Parsed(RespT) {
        var opt = options;
        if (opt.content_type == null) opt.content_type = "application/json";
        if (opt.accept == null) opt.accept = "application/json";

        const json_payload = try std.fmt.allocPrint(self.allocator, "{f}", .{std.json.fmt(payload, .{})});
        defer self.allocator.free(json_payload);
        opt.body = json_payload;

        var resp = try self.post(url, json_payload, opt);
        defer resp.deinit();

        return resp.json(RespT);
    }
};
