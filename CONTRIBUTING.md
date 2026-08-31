# Contributing to zfetch ⚡

Thank you for contributing to `zfetch`! To maintain code quality and stability in the Zig ecosystem, we follow strict quality gates.

---

## 1. Compiler Versioning & Branch Strategy

* **`main` (Protected)**: Targets **Official Stable Zig (`0.16.x`)**. All production releases (`vX.Y.Z`) are cut exclusively from `main`.
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
