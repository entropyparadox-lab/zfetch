#!/usr/bin/env python3
"""Offline HTTP and fetched-package consumer checks; only loopback is used."""
import argparse
import http.server
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile
import threading
from typing import cast


SOURCE = r'''
const std = @import("std");
const zfetch = @import("zfetch");
const Payload = struct { message: []const u8 };
pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var args = init.minimal.args.iterate();
    _ = args.next();
    const url = args.next().?;
    var client = zfetch.Client.init(allocator, init.io);
    defer client.deinit();
    var parsed = try client.getJson(Payload, url, .{ .bearer_token = "local-test", .keep_alive = false });
    defer parsed.deinit();
    try std.testing.expectEqualStrings("loopback", parsed.value.message);
    var posted = try client.postJson(Payload, url, .{ .message = "loopback" }, .{ .keep_alive = false });
    defer posted.deinit();
    try std.testing.expectEqualStrings("loopback", posted.value.message);
    var response = try zfetch.get(allocator, init.io, url, .{ .keep_alive = false });
    defer response.deinit();
    try std.testing.expect(response.isSuccess());
}
'''
BUILD = '''const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep = b.dependency("zfetch", .{ .target = target, .optimize = optimize });
    const mod = b.createModule(.{ .root_source_file = b.path("main.zig"), .target = target, .optimize = optimize });
    mod.addImport("zfetch", dep.module("zfetch"));
    const exe = b.addExecutable(.{ .name = "consumer", .root_module = mod });
    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    b.step("run", "Run loopback consumer").dependOn(&run.step);
}
'''


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def respond(self, body):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        cast(Server, self.server).requests.append(("GET", self.headers.get("Authorization"), self.headers.get("Accept")))
        self.respond(b'{"message":"loopback"}')

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
        cast(Server, self.server).requests.append(("POST", self.headers.get("Content-Type"), json.loads(body)))
        self.respond(body)


class Server(http.server.ThreadingHTTPServer):
    requests: list


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--zig", default="zig")
    parser.add_argument("--work-dir", required=True, type=Path, help="Parent for isolated temporary files/caches")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    args.work_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="zfetch-", dir=args.work_dir) as work:
        work = Path(work)
        cache = work / "cache"
        env = dict(os.environ, ZIG_GLOBAL_CACHE_DIR=str(cache))
        def run(*command, cwd=root):
            print("+", *command, flush=True)
            return subprocess.check_output(command, cwd=cwd, env=env, text=True, timeout=120).strip()
        zon = (root / "build.zig.zon").read_text()
        paths = re.findall(r'"([^"]+)"', zon.split(".paths = .{", 1)[1].split("}", 1)[0])
        archive = work / "zfetch.tar.gz"
        with tarfile.open(archive, "w:gz") as tar:
            for path in paths:
                tar.add(root / path, arcname=path)
        package_hash = run(args.zig, "fetch", str(archive))
        extracted = work / "extracted"
        with tarfile.open(cache / "p" / (package_hash + ".tar.gz")) as tar:
            tar.extractall(extracted, filter="data")
        package = extracted / package_hash
        for path in paths:
            assert (package / path).exists(), path
        assert not (package / ".git").exists()
        # Full standalone build catches missing example files in .paths too.
        run(args.zig, "build", "test", "--summary", "all", cwd=package)
        run(args.zig, "build", "--summary", "all", cwd=package)
        consumer = work / "consumer"
        consumer.mkdir()
        (consumer / "build.zig").write_text(BUILD)
        (consumer / "main.zig").write_text(SOURCE)
        (consumer / "build.zig.zon").write_text('.{ .name = .smoke, .version = "0.0.0", .fingerprint = 0x4946e97a97261c84, .dependencies = .{ .zfetch = .{ .url = "file://' + str(archive) + '", .hash = "' + package_hash + '" } }, .paths = .{ "" } }')
        server = Server(("127.0.0.1", 0), Handler)
        server.requests = []
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            run(args.zig, "build", "run", "--", f"http://127.0.0.1:{server.server_port}/json", cwd=consumer)
            assert server.requests == [
                ("GET", "Bearer local-test", "application/json"),
                ("POST", "application/json", {"message": "loopback"}),
                ("GET", None, None),
            ], server.requests
        finally:
            server.shutdown()
            server.server_close()
            thread.join()
        print("PASS: archive .paths, standalone package build/tests, consumer import, typed GET/POST, bearer/JSON headers, response ownership, one-shot GET")


if __name__ == "__main__":
    main()
