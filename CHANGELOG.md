# Changelog

## [1.1.1] - 2026-11-09

- Pin the minimum compiler and Linux/macOS CI to Zig 0.17.1.
- Confirm the existing library builds and tests with Zig 0.17.0 and 0.17.1 before the metadata update; no library API migration is required.
- Include `examples`, tests and development documentation in package `.paths`, fixing standalone builds from fetched archives.
- Add an isolated loopback HTTP smoke test using a separate archive consumer, covering typed GET/POST, Bearer and JSON headers, response ownership and one-shot GET.
- Refresh installation/version examples and add a Korean Zig 0.17.1 development guide.

This entry records the source upgrade, not publication of a release tag.
