# ACME

A C++23 project skeleton: CMake presets, vcpkg in manifest mode, sanitizers,
clang-tidy, and a five-job CI matrix across Linux, macOS and Windows.

[![CI](https://github.com/inertialbox/experiment-cpp-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/inertialbox/experiment-cpp-starter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Getting started

Two supported ways in. The devcontainer is the shortest path and matches CI
exactly; a native toolchain is fewer moving parts if you would rather not run
Docker. Either way the build itself is one command.

### Option A: devcontainer

Needs Docker (Docker Desktop, OrbStack and Colima all work) and VS Code with the
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension, or a GitHub Codespace.

1. Open the repository in VS Code.
2. **Reopen in Container** when prompted, or run
   `Dev Containers: Reopen in Container` from the command palette.
3. Wait for the image to build. It reads [.tool-versions](.tool-versions), so the
   container gets the pinned CMake, Ninja, GCC, Clang and vcpkg, with
   `VCPKG_ROOT` already set and the git hooks installed.
4. Build and test:

```sh
cmake --workflow --preset dev
```

The image is built for the host architecture, so Apple silicon and x86_64 both
work.

### Option B: native toolchain

Install a compiler at or above the floor, CMake and Ninja, then vcpkg.

**macOS**

```sh
xcode-select --install            # Apple Clang, if not already present
brew install cmake ninja ccache
```

**Linux (Debian or Ubuntu)**

```sh
sudo apt-get install -y ninja-build ccache mold
# Compilers: install the majors pinned in .tool-versions, for example
sudo apt-get install -y g++-15        # or clang-22 libc++-22-dev libc++abi-22-dev
```

CMake must be 3.30 or newer. If your distribution ships something older, take
the upstream archive:

```sh
version="$(./scripts/tool-version.sh cmake)"
curl -fsSLO "https://github.com/Kitware/CMake/releases/download/v${version}/cmake-${version}-linux-$(uname -m).tar.gz"
```

**Windows**

Install Visual Studio 2026 with the "Desktop development with C++" workload,
which provides MSVC, CMake and Ninja. Run the commands below from a
**Developer Command Prompt** (or **Developer PowerShell**) so the MSVC
environment is set.

**Then, on every platform**, check out vcpkg at the pinned baseline:

```sh
git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
git -C ~/vcpkg checkout --detach "$(./scripts/tool-version.sh vcpkg)"
~/vcpkg/bootstrap-vcpkg.sh -disableMetrics     # bootstrap-vcpkg.bat on Windows
export VCPKG_ROOT=~/vcpkg                      # add to your shell profile
```

And build:

```sh
cmake --workflow --preset dev
```

### What that command does

`cmake --workflow --preset dev` configures, builds and tests in one step: a
Debug build with AddressSanitizer, UndefinedBehaviorSanitizer and
standard-library hardening. The first run builds GoogleTest through vcpkg, so
expect a few minutes; later runs reuse the binary cache.

`dev` uses whichever compiler is first on your `PATH`. To pick Clang with
libc++ explicitly, use `dev-clang`.

### If configure rejects your compiler

The build enforces the floors in [cmake/CompilerFloor.cmake](cmake/CompilerFloor.cmake)
(GCC 14, Clang 21, AppleClang 26.4, MSVC 19.50) and fails with a message naming
the version it found. Install a newer compiler, or override it deliberately:

```sh
cmake --preset dev -DACME_ALLOW_UNSUPPORTED_COMPILER=ON
```

That warns and continues instead of failing. C++23 support may be incomplete
below the floor, so treat it as a stopgap rather than a setting to keep.

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
