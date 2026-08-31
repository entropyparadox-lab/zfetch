# zfetch ⚡

[![Zig Version](https://img.shields.io/badge/Zig-0.16.0%2B-orange.svg)](https://ziglang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Zero C Dependencies](https://img.shields.io/badge/Zero--C-Pure%20Zig-brightgreen.svg)]()
[![Type-Safe JSON](https://img.shields.io/badge/Type--Safe-JSON%20REST-purple.svg)]()

**Ergonomic, Type-Safe HTTP Client & REST Wrapper for Pure Zig (v0.16.0+)**

`zfetch` turns Zig 0.16.0's verbose `std.http.Client` boilerplate into clean, 1-line HTTP requests with automatic TLS CA bundle scanning, streaming response buffer management, Bearer token authorization, and typed JSON response deserialization.

---

## Why zfetch vs std.http.Client?

| Task | `std.http.Client` (Stdlib) | `zfetch` ⚡ |
| :--- | :--- | :--- |
| **GET Request** | ~25 lines (Uri parse, request, sendBodiless, receiveHead, reader, decompress, allocate) | `client.get(url, .{})` (1 line) |
| **Typed JSON GET** | ~40 lines + manual `std.json.parseFromSlice` | `client.getJson(UserStruct, url, .{})` (1 line) |
| **TLS CA Bundle** | Manual `ca_bundle.rescan` check | Auto-rescanned on first request |
| **Bearer Token** | Manual header array creation & buffer formatting | `.{ .bearer_token = "..." }` |
| **Memory Safety** | Complex stream lifetimes | Clean `resp.deinit()` |

---

## Installation (`build.zig.zon`)

Add `zfetch` to your `build.zig.zon`:

```bash
zig fetch --save https://github.com/entropyparadox-lab/zfetch/archive/refs/tags/v1.0.0.tar.gz
```

In your `build.zig`:

```zig
const zfetch_dep = b.dependency("zfetch", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zfetch", zfetch_dep.module("zfetch"));
```

---

## Quickstart

### 1. Basic JSON Fetch

```zig
const std = @import("std");
const zfetch = @import("zfetch");

const UserProfile = struct {
    id: u64,
    name: []const u8,
    email: []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;

    var client = zfetch.Client.init(allocator, io);
    defer client.deinit();

    // 1-line typed JSON request
    var user = try client.getJson(UserProfile, "https://api.example.com/me", .{
        .bearer_token = "my-secret-token",
    });
    defer user.deinit();

    std.debug.print("User: {s} ({s})\n", .{ user.value.name, user.value.email });
}
```

---

## License

MIT License (c) 2026 Entropy Paradox Lab / Charles Choi
