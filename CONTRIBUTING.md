# Contributing to zfetch ⚡

Thank you for contributing to `zfetch`! To maintain code quality and stability in the Zig ecosystem, we follow strict quality gates.

---

## 1. Compiler Versioning & Branch Strategy

* **`main` (Protected)**: Production releases (`vX.Y.Z`) are cut exclusively from `main`.
* **`feat/zig-0171-upgrade-20261109`**: Upgrades package 1.1.1 to the pinned Zig 0.17.1 compiler.
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

## 한국어 Zig 0.17.1 개발 가이드

패키지 버전은 `build.zig.zon`의 `1.1.1`, 최소 Zig 버전은 `0.17.1`입니다.
전역 Zig 설치를 바꾸지 말고 내려받은 컴파일러의 절대 경로를 지정하세요.
Python 3.12 이상이 로컬 HTTP 및 패키지 소비자 검증에 필요합니다.

```bash
ZIG=/absolute/path/to/zig-0.17.1/zig
"$ZIG" version
"$ZIG" fmt --check src/ examples/ build.zig build.zig.zon
"$ZIG" build test --summary all
"$ZIG" build --summary all
python3 tests/smoke.py --zig "$ZIG" --work-dir "$PWD/.zig-cache/smoke"
```

스모크 테스트는 임시 디렉터리와 별도 Zig 캐시를 만들고, `127.0.0.1`의
자동 할당 포트에서만 HTTP 서버를 실행합니다. 종료 시 서버와 임시 파일을
정리하며 외부 HTTP 서비스나 인증 정보는 필요하지 않습니다.
실제 GET/POST, Bearer 및 JSON 헤더, 응답 해제 후 JSON 소유권을 검증합니다.
또한 `.paths`만 포함한 아카이브를 `zig fetch`로 가져와 패키지 자체의 빌드와
테스트를 실행하고, 별도 소비자 프로젝트에서 `zfetch` 모듈을 사용합니다.
`build.zig`가 예제 실행 파일을 정의하므로 `examples`도 반드시 `.paths`에 포함해야 합니다.

CI는 Linux/macOS에서 Zig 0.17.1로 같은 빌드·테스트·스모크 검증을 실행합니다.
`run-example`은 외부 httpbin.org를 사용하는 수동 예제이며 오프라인 검증 게이트가 아닙니다.
