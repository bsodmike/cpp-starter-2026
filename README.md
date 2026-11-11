# ACME

A C++23 project skeleton: CMake presets, vcpkg in manifest mode, sanitizers,
clang-tidy, and a five-job CI matrix across Linux, macOS and Windows.

[![CI](https://github.com/inertialbox/experiment-cpp-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/inertialbox/experiment-cpp-starter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Quick start

Install the pinned tools (see [.tool-versions](.tool-versions)), set `VCPKG_ROOT`,
then:

```sh
cmake --workflow --preset dev
```

That configures, builds and tests in one command: a Debug build with
AddressSanitizer, UndefinedBehaviorSanitizer and standard-library hardening.

The devcontainer in [.devcontainer/](.devcontainer) already has every pinned
tool, so in VS Code or Codespaces "Reopen in Container" and run the same
command.

## What you get

| Target | Kind | Notes |
| --- | --- | --- |
| `acme::core` | static library | Public headers under `src/core/include/acme/core/` |
| `acme` (`acme_app`) | executable | Sums its integer arguments; the worked example |
| `acme_core_test` | GoogleTest binary | One test binary per library |
| `acme::options` | interface | Public usage requirements, exported to consumers |
| `acme::build_options` | interface | Warnings, sanitizers, coverage; build-tree only |

## Presets

`cmake --list-presets` shows them all. The ones you will use:

| Preset | Build type | What it adds |
| --- | --- | --- |
| `dev` | Debug | ASan + UBSan, library hardening, sanitizer self-tests |
| `dev-clang` | Debug | As `dev`, with Clang and libc++ |
| `release` | RelWithDebInfo | OpenSSF hardening flags, LTO on executables, no sanitizers |
| `ci-*` | Debug | The `dev` set plus warnings-as-errors; one per CI job |

Each has matching build, test and workflow presets, so
`cmake --workflow --preset <name>` always works. Personal overrides belong in
`CMakeUserPresets.json`, which is gitignored.

## Layout

```
CMakeLists.txt            project(), options, the two interface targets
CMakePresets.json         configure/build/test/package/workflow presets
vcpkg.json                dependencies, pinned with builtin-baseline
.tool-versions            the single source of tool pins
cmake/                    warnings, sanitizers, hardening, coverage, install
src/core/                 the acme::core library
app/                      the acme executable
tests/                    unit tests, sanitizer self-tests, consumer project
benchmarks/               off by default (-DACME_BUILD_BENCHMARKS=ON)
scripts/                  tool-version reader, suppression check, staged tidy
docs/                     PRD, ADRs, dependency allowlist
```

## Options

Every option is prefixed `ACME_` and defaults to a developer-friendly value only
when ACME is the top-level project.

| Option | Default | Purpose |
| --- | --- | --- |
| `ACME_BUILD_TESTS` | on when top-level | Build the test suite |
| `ACME_BUILD_BENCHMARKS` | `OFF` | Build the benchmarks |
| `ACME_ENABLE_SANITIZERS` | `OFF` | ASan + UBSan |
| `ACME_ENABLE_TSAN` | `OFF` | ThreadSanitizer; excludes ASan |
| `ACME_ENABLE_HARDENING` | `OFF` | OpenSSF release hardening flags |
| `ACME_ENABLE_LIBRARY_HARDENING` | on when top-level | Standard-library assertions |
| `ACME_WARNINGS_AS_ERRORS` | `OFF` | `-Werror` / `/WX`; CI turns this on |
| `ACME_ENABLE_COVERAGE` | `OFF` | gcov or source-based coverage |
| `ACME_ENABLE_IPO` | `OFF` | LTO, applied to executables only |
| `ACME_ENABLE_CXX26` | `OFF` | Opt into C++26 for this build |
| `ACME_SANITIZER_SELFTEST` | `OFF` | Build the deliberate-defect binaries |
| `ACME_ALLOW_UNSUPPORTED_COMPILER` | `OFF` | Bypass the compiler floor check |

## Using ACME from another project

```sh
cmake --workflow --preset release
cmake --install build/release --prefix /path/to/prefix
```

```cmake
find_package(ACME CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE acme::core)
```

Install from the `release` preset, not from a sanitizer build: those objects
reference the sanitizer runtime and will not link for a consumer. The build
warns if you try.

## Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - presets, pre-commit, adding a dependency
- [SECURITY.md](SECURITY.md) - reporting a vulnerability
- [docs/PRD.md](docs/PRD.md) - the requirements this repo implements
- [docs/adrs/](docs/adrs) - why the toolchain is what it is
- [docs/dependencies.md](docs/dependencies.md) - the dependency allowlist

## Licence

MIT. See [LICENSE](LICENSE).
