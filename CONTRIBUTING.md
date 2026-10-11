# Contributing to zfetch ⚡

Thank you for contributing to `zfetch`! To maintain code quality and stability in the Zig ecosystem, we follow strict quality gates.

---

## 1. Compiler Versioning & Branch Strategy

* **`main` (Protected)**: Production releases (`vX.Y.Z`) are cut exclusively from `main`.
* **`feat/zig-0.17-renewal`**: Tracks the pinned, unreleased Zig snapshot `0.17.0-dev.2085+5e36170b5` during the compatibility renewal.
* **`zig-master`**: Tracks upstream `ziglang/zig` nightly builds.
* **`feat/<name>` / `fix/<name>`**: Branch off `main` for stable changes.

---

## 2. Fast Local Development & Git Hooks

Install local pre-commit hooks:
```bash
./scripts/setup-hooks.sh
```

Before opening a PR, run full local verification:
```bash
# 1. Format code
zig fmt src/ examples/ build.zig

# 2. Run unit tests
zig build test
```
