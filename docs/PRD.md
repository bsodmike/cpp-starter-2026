# PRD: New C++ Project Setup (2026 Baseline)

_As of 2026-11-11. Amended 2026-11-11 during the M1-M4 build; see
[Decisions taken](#decisions-taken) and [Amendments](#amendments)._

## Overview

Build a new C++ project skeleton on **C++23 + CMake 4.x + Ninja + vcpkg (manifest
mode)**, with sanitizers, clang-tidy, and a three-OS CI matrix on day one. C++26
features stay opt-in, because the C++26 draft failed its ISO ballot in October
2026 and its final shape is still open.

**Problem.** Teams starting a C++ codebase lose weeks to undecided toolchain
choices, then pay for them for years: unpinned dependencies, warnings that pile
up, no sanitizer coverage, and builds that only work on one laptop. This PRD
fixes those choices up front so the receiving engineer has a working skeleton in
about a week and the full baseline in three.

**Audience.** The engineer or small team taking over the repo bootstrap;
reviewers who sign off on toolchain decisions.

**Scope.** A generic cross-platform project (Linux, macOS, Windows) that
produces at least one library target, one executable, and a test suite.
Domain-specific needs (GPU, embedded, game engine) are layered on afterwards.

## Decisions taken

The project is named **ACME**: CMake project `ACME`, option prefix `ACME_`,
namespace `acme::`, public includes `#include <acme/core/thing.hpp>`.

| Question | Decision | Recorded in |
| --- | --- | --- |
| Library or application? | Both. `acme::core` static library plus the `acme` executable, as the scope requires | [README](../README.md) |
| Static or shared by default? | Static. `BUILD_SHARED_LIBS` is untouched, so a consumer can flip it; `POSITION_INDEPENDENT_CODE` is on | `src/core/CMakeLists.txt` |
| Licence | MIT | [ADR](adrs/2026-11-11.adr-mit-licence.md) |
| Test framework | GoogleTest 1.18.0 | [ADR](adrs/2026-11-11.adr-googletest-over-catch2.md) |
| Extra targets | x64 Linux/Windows and arm64 macOS only for v1. Linux arm64 runners exist (`ubuntu-26.04-arm`) and can be added without new code | this table |
| CI host | GitHub Actions | `.github/workflows/` |
| Binary cache backend | GitHub Actions cache, keyed on OS + compiler + preset + `vcpkg.json` hash. Move to S3 or Artifactory when a second repo needs to share it | [ADR](adrs/2026-11-11.adr-vcpkg-manifest-mode.md) |
| Language baseline | C++23, C++26 opt-in per build | [ADR](adrs/2026-11-11.adr-cxx23-baseline.md) |
| Modules | Headers for v1; module scanning off | [ADR](adrs/2026-11-11.adr-headers-not-modules.md) |

## Goals and non-goals

The repo is done when a new contributor goes from `git clone` to green tests with
two commands, on any of the three OSes.

**Goals**

1. **Reproducible builds.** Compiler range, CMake minimum, and every dependency
   version are pinned in the repo.
2. **One-command workflows.** `cmake --workflow --preset dev` configures, builds,
   and tests. No hand-typed flags.
3. **Safety on by default.** Strict warnings as errors in CI, ASan + UBSan on
   every PR, standard-library hardening on in debug builds.
4. **Consistent style.** clang-format and clang-tidy run locally (pre-commit) and
   in CI with the same config.
5. **Cross-platform CI.** Linux (GCC and Clang), macOS (Apple Clang), Windows
   (MSVC) on every PR, under 15 minutes with caching.
6. **Ready to ship.** `cmake --install` and a CPack package work; a release tag
   produces artifacts and an SBOM.

**Non-goals**

- Adopting C++20 named modules or `import std;` for project code (revisit in
  2027, see Risks).
- Supporting compilers older than the floor in the toolchain table.
- Bazel, Meson, xmake, or build2. CMake is the decision; alternatives are noted
  only as rejected options.
- Domain features, product code, or performance tuning.

## Toolchain requirements

Target **C++23** with compiler extensions off. Floors are CI-enforced in
`cmake/CompilerFloor.cmake`; the pinned versions live in `.tool-versions`.

**Why C++23, not C++26.** WG21 finished C++26 technical work in March 2026
([Sutter](https://herbsutter.com/2026/03/)), but the ISO DIS ballot failed in
late October 2026 over Contracts
([iThome](https://www.ithome.com.tw/news/180248)). WG21 meets on 16 November to
decide next steps. C++26 features (reflection, `std::execution`, hardened
library) may be enabled per build behind `ACME_ENABLE_CXX26`, which applies only
to the build-only options target and so can never reach a public header.

| Component | Floor (CI-enforced) | Pinned | Notes |
| --- | --- | --- | --- |
| Language | C++23 | C++23 | `CMAKE_CXX_STANDARD 23`, `CMAKE_CXX_STANDARD_REQUIRED ON`, `CMAKE_CXX_EXTENSIONS OFF`, plus `cxx_std_23` on `acme::options` |
| [GCC](https://phoronix.com/news/GCC-16.2-Released) | 14 | **15.2.0** | Newest on `ubuntu-26.04`. GCC 16.2 exists but is not on a hosted runner; GCC 16 defaults to gnu++20, so always pin `-std` |
| [Clang / LLVM](https://www.phoronix.com/news/LLVM-23.1-Released) | 21 | **22.1.2** | Newest on `ubuntu-26.04`. Also the source of clang-format, clang-tidy, clangd. 23.1.5 is current upstream |
| Apple Clang | **AppleClang 17.0** | Xcode 26.x (AppleClang 21.0) | Apple Clang versions do not track Xcode versions: Xcode 26.x reports AppleClang 21.0.0, so an Xcode-numbered floor is unusable. `macos-26` offers Xcode 26.3 to 26.6 |
| [MSVC](https://learn.microsoft.com/cpp/overview/compiler-versions) | 14.50 (LTS to Nov 2028) | VS 2026 18.11 | Requires the `windows-2025-vs2026` runner label; see Amendments |
| [CMake](https://www.kitware.com/cmake-4-4-1-available-for-download/) | 3.30 | **4.4.5** | `cmake_minimum_required(VERSION 3.30...4.4)` |
| Generator | Ninja 1.11 | **1.13.2** | Ninja Multi-Config optional for IDE users |
| Package manager | vcpkg (manifest mode) | baseline `2ec0f174` | Conan 2 is the documented fallback |
| Linker | system default | mold (Linux), lld (fallback) | Probed at configure time, not named in presets |
| Compiler cache | none | ccache / sccache | Probed and wired through `CMAKE_CXX_COMPILER_LAUNCHER` |
| Test framework | GoogleTest 1.15 | **1.18.0** | `gtest_discover_tests`; Catch2 v3 remains a drop-in alternative |

**Package manager decision.** vcpkg wins for this project: it is CMake-native (a
JSON manifest plus a toolchain file), and `builtin-baseline` pins every port
version in one commit hash. Choose Conan 2 instead only if the team must publish
prebuilt binaries to a private remote or needs many per-package build options.
Never mix the two in one repo, and avoid `FetchContent` for anything except the
build's own tooling.

**Pinning rule.** Every tool version lives in exactly one place: the devcontainer
image and the CI matrix both read `.tool-versions`, through
`scripts/tool-version.sh`.

## Repository layout and build configuration

Use a target-based CMake layout with one library, one app, and tests, driven
entirely by `CMakePresets.json`; no `include_directories()` or global flags.

**Directory tree**

```
acme/
|-- CMakeLists.txt            # project(), options, the two interface targets
|-- CMakePresets.json         # committed: dev, ci-*, release presets + workflows
|-- CMakeUserPresets.json     # gitignored: personal overrides
|-- vcpkg.json                # dependencies + builtin-baseline
|-- vcpkg-configuration.json  # registries, overlay ports
|-- .tool-versions            # single source of tool pins
|-- cmake/                    # CompilerFloor, ProjectWarnings, Sanitizers,
|                             # Hardening, Coverage, BuildAccel, Install, Packaging
|-- src/
|   `-- core/                 # library target acme::core
|       |-- include/acme/core/   # public headers only
|       `-- *.cpp
|-- app/                      # executable target acme_app
|-- tests/                    # unit tests, sanitizer self-tests, consumer project
|-- benchmarks/               # optional, off by default
|-- scripts/                  # tool-version reader, suppression check, staged tidy
|-- docs/                     # PRD, ADRs, dependency allowlist
|-- .clang-format  .clang-tidy  .editorconfig  .pre-commit-config.yaml
|-- .devcontainer/
`-- .github/workflows/
```

Added to the tree during implementation: `scripts/` (the readers and checks that
CI and pre-commit share), `tests/selftest/` and `tests/cmake/` (the sanitizer
self-tests), `tests/consumer/` (the standalone `find_package` project), and
`docs/adrs/`.

**Build rules**

1. Every flag is attached to a target. Shared settings live on **two**
   `INTERFACE` targets rather than one, because an exported options target
   would push our warnings and sanitizer flags onto consumers:
   `acme::options` for public usage requirements (exported) and
   `acme::build_options` for build-only strictness, linked through
   `$<BUILD_INTERFACE:>`. See
   [the ADR](adrs/2026-11-11.adr-split-options-targets.md).
2. Public headers go under `include/acme/<lib>/` so includes read
   `#include <acme/core/thing.hpp>`.
3. Libraries export an alias (`acme::core`) and install a CMake package config,
   so consumers use `find_package(ACME CONFIG REQUIRED)`.
4. `CMAKE_EXPORT_COMPILE_COMMANDS ON` in every preset for clangd and clang-tidy.
5. Options are prefixed `ACME_` and default to developer-friendly values only
   when the project is top-level.

**Presets.** Committed configure, build, test, package and workflow presets at
schema version 6, so `cmake --workflow --preset dev` runs end to end. Optional
accelerators (ccache, mold) are probed in CMake rather than named in presets, so
a fresh clone works on a machine without them.

| Preset | Compiler | Build type | Extras |
| --- | --- | --- | --- |
| `dev` | host default | Debug | ASan + UBSan, library hardening, sanitizer self-tests, ccache |
| `dev-clang` | Clang | Debug | Same as `dev`, libc++ |
| `ci-linux-gcc` / `ci-linux-clang` | GCC / Clang | Debug | Warnings as errors, sanitizers, coverage on GCC |
| `ci-linux-tsan` | Clang | Debug | ThreadSanitizer; nightly only |
| `ci-macos` | Apple Clang | Debug | ASan + UBSan |
| `ci-windows` | MSVC | Debug | `/W4 /WX`, ASan |
| `release` | host default | RelWithDebInfo | Hardening flags, LTO on executables, no sanitizers |

**Modules policy.** Project code uses headers in v1. All three compilers can
build `import std;`, but CMake still gates it behind an experimental UUID that
has changed between releases, and IDE support is partial
([wrocpp, May 2026](https://wrocpp.github.io/posts/modules-2026/)). Module
scanning is switched off, since no target uses modules. One spike ticket
evaluates modules again after CMake stabilises `import std`.

## Quality gates

A PR merges only when it compiles warning-free on all four compilers, passes
tests under ASan + UBSan, and is clean under clang-format and clang-tidy.

| Gate | Tool / setting | Where it runs | Blocks merge |
| --- | --- | --- | --- |
| Warnings (GCC/Clang) | `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion -Wnon-virtual-dtor -Wold-style-cast -Wimplicit-fallthrough -Wcast-align -Wunused -Woverloaded-virtual -Wdouble-promotion -Wformat=2`, plus GCC-only `-Wnull-dereference -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast` | Every build | Yes, with `-Werror` in CI only |
| Warnings (MSVC) | `/W4 /permissive- /Zc:__cplusplus /Zc:preprocessor /utf-8` plus selected `/w14xxx` | Every build | Yes, with `/WX` in CI only |
| Memory + UB | `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined` | `dev` and CI Debug | Yes |
| Sanitizers actually work | `tests/selftest/` deliberate OOB read and signed overflow, each passing only when the sanitizer reports it | `dev` and CI Debug | Yes |
| Threads | `-fsanitize=thread` | Nightly Clang job | No, triaged within 2 days |
| Library hardening | `_GLIBCXX_ASSERTIONS` (libstdc++), `_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST` (libc++), `_ITERATOR_DEBUG_LEVEL` default (MSVC Debug) | Debug and release builds | Yes |
| Formatting | clang-format, `.clang-format` committed | pre-commit + CI | Yes |
| Static analysis | clang-tidy: `bugprone-*`, `cert-*`, `concurrency-*`, `cppcoreguidelines-*`, `misc-*`, `modernize-*`, `performance-*`, `portability-*`, `readability-*` minus a short, commented exclusion list | CI on changed files; full run nightly | Yes on changed files |
| Unit tests | GoogleTest via `ctest --preset` | Every CI job | Yes |
| Install is consumable | `cmake --install` from the `release` preset, then `find_package(ACME)` from `tests/consumer/` | Dedicated CI job | Yes |
| Coverage | gcovr (GCC) or llvm-cov, uploaded as an artifact | Linux GCC job | Report only; 80% line target by M4 |
| Fuzzing | libFuzzer targets for any parser or decoder | Nightly, 10 min per target | No |

**Rules for exceptions.** A suppression (`// NOLINT(check)`,
`#pragma warning`) must name the specific check and carry a one-line reason.
`scripts/check-suppressions.sh` rejects blanket forms in CI and pre-commit.
Repo-wide exclusions live in `.clang-tidy` with their rationale beside the list;
`tests/.clang-tidy` holds the test-only relaxations.

**Local loop.** `pre-commit` runs clang-format, a fast clang-tidy on staged
files, and the suppression check, so CI rarely fails on style. The tidy hook
skips cleanly when no build tree is configured yet.

## CI/CD and developer experience

Seven GitHub Actions jobs on every PR: five build-matrix jobs each calling one
`cmake --workflow` preset, plus the install-consumer and clang-format jobs, with
vcpkg binary caching and ccache keeping warm runs under 15 minutes.

| Job | Runner | Compiler | Preset | Notes |
| --- | --- | --- | --- | --- |
| linux-gcc | `ubuntu-26.04` | GCC 15 | `ci-linux-gcc` | Coverage report |
| linux-clang | `ubuntu-26.04` | Clang 22 + libc++ | `ci-linux-clang` | clang-tidy on changed files |
| linux-floor | `ubuntu-24.04` | GCC 14 | `ci-linux-gcc` | Proves the compiler floor still builds |
| macos | `macos-26` | Apple Clang | `ci-macos` | arm64 |
| windows | `windows-2025-vs2026` | MSVC 14.5x | `ci-windows` | x64; add arm64 later if needed |
| install-consumer | `ubuntu-26.04` | GCC 15 | `release` | `cmake --install` then `find_package(ACME)` |
| format | `ubuntu-26.04` | - | - | clang-format over the tree |

**Runner pinning.** Pin explicit image labels, never `*-latest`. GitHub is
moving `ubuntu-latest` from 24.04 to 26.04 between 19 October and 19 November
2026, which can silently change compiler versions mid-sprint
([GitHub changelog](https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration));
as of 2026-11-11 `ubuntu-latest` is still 24.04. The same applies on Windows:
`windows-2025` provisioned Visual Studio 2022 (MSVC 14.4x, below our floor)
before the VS 2026 migration, so the explicit `windows-2025-vs2026` label is
what guarantees a conforming toolset.

**Compiler installation.** CI selects preinstalled compilers with
`update-alternatives` rather than adding a third-party apt repository, which
keeps the blocking path fast and free of an external supply-chain dependency.
`libc++` and `mold` are not preinstalled and are installed explicitly. Only the
nightly pre-release job uses `apt.llvm.org`, which is that job's purpose.

**Caching.** vcpkg binary cache through `VCPKG_DEFAULT_BINARY_CACHE` plus
`actions/cache`; ccache/sccache cached per job key (OS + compiler + preset +
`vcpkg.json` hash).

**Other pipelines**

- Nightly: full clang-tidy, TSan, and a build against the newest compiler
  pre-releases (non-blocking). Fuzzers to follow with the first parser.
- Release (on `v*` tag): `release` preset, CPack archives per OS, SBOM,
  checksums, artifact attestations, GitHub Release draft.
- Dependency review: OSV-Scanner on `vcpkg.json` changes and weekly on `main`.
- Dependabot or Renovate opens monthly PRs to bump `builtin-baseline` and pinned
  GitHub Actions SHAs.

**Developer experience**

- **Devcontainer** with the pinned GCC, Clang, CMake, Ninja, and vcpkg, built by
  reading `.tool-versions` inside the image build; works in VS Code and
  Codespaces.
- **Editors**: clangd reading `compile_commands.json` is the supported path for
  VS Code, Neovim, and CLion. Visual Studio 2026 opens the folder through
  `CMakePresets.json` directly.
- **Onboarding**: the `README` "Getting started" section gives two routes in,
  the devcontainer and a native toolchain, and both end at the same command,
  `cmake --workflow --preset dev`; `CONTRIBUTING.md` documents presets,
  pre-commit setup, where each flag belongs, and how to add a dependency.

## Security and supply chain

Release binaries ship with the OpenSSF-recommended hardening flags, every
dependency is pinned to an exact version, and each release carries an SBOM.

**Hardening flags (release preset).** Follow the
[OpenSSF Compiler Options Hardening Guide for C and C++](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++),
kept in `cmake/Hardening.cmake`. Every flag is probed with
`check_cxx_compiler_flag` / `check_linker_flag` before use, because the set is
architecture- and version-dependent.

| Toolchain | Flags |
| --- | --- |
| GCC 14+ | `-fhardened` (umbrella flag), plus `-Wl,-z,nodlopen -Wl,-z,noexecstack` |
| Clang / Apple Clang | `-D_FORTIFY_SOURCE=3` (non-Debug only), `-fstack-protector-strong`, `-fstack-clash-protection`, `-fcf-protection=full` (x86) or `-mbranch-protection=standard` (arm64), `-ftrivial-auto-var-init=zero`, `-Wl,-z,relro,-z,now` (ELF) |
| MSVC | `/sdl /guard:cf /Qspectre`, link with `/CETCOMPAT /DYNAMICBASE /HIGHENTROPYVA /NXCOMPAT` |
| All | Library hardening macros from Quality gates stay on in release builds (fast mode only) |

**Dependencies**

- `vcpkg.json` sets `builtin-baseline`; any exception uses `overrides` with an
  exact version and a comment saying why.
- A curated allowlist in `docs/dependencies.md` names each dependency, its
  licence, and an owner. New dependencies need one reviewer from the owners file.
- GitHub Actions are pinned by commit SHA, not tag.

**SBOM and scanning**

- Release workflow emits a CycloneDX SBOM and attaches it to the GitHub Release.
- OSV-Scanner runs on PRs that touch `vcpkg.json` and weekly on `main`.
- Release artifacts get SHA-256 checksums and GitHub artifact attestations.

**Repo hygiene.** Branch protection on `main` (required checks, one review,
signed commits optional), secret scanning with push protection, and a
`SECURITY.md` with a reporting route.

## Acceptance criteria

The handoff is complete when every box below is ticked on `main`. Verification
status as of 2026-11-11 is noted per item; see
[Verification status](#verification-status).

- [x] Fresh clone + `cmake --workflow --preset dev` passes with no manual steps
      beyond installing the pinned tools. _Verified on Linux arm64 (Clang 23.1.5
      + libc++) and on macOS arm64 (Apple Clang 21.0.0, Xcode 26, Homebrew CMake
      and Ninja, vcpkg manifest mode). Windows is still unverified and needs the
      first CI run._
- [ ] All CI jobs are required checks and pass; warm-cache wall time under 15
      minutes. _Requires a push; no CI run has happened yet._
- [x] A deliberately introduced out-of-bounds read fails CI under ASan; a
      deliberate signed overflow fails under UBSan. _Automated as
      `tests/selftest/`; both verified reporting genuine sanitizer diagnostics._
- [x] A new warning on any compiler fails CI. _`ACME_WARNINGS_AS_ERRORS=ON` in
      every `ci-*` preset; verified building clean under `-Werror` with the full
      warning set._
- [x] clang-format and clang-tidy run in pre-commit and CI with identical
      configs. _Both read the committed `.clang-format` and `.clang-tidy`;
      verified clean locally._
- [x] `cmake --install` + `find_package(ACME)` works from a separate consumer
      project (tested in CI). _Verified locally from the `release` preset; the
      `install-consumer` job does it in CI._
- [ ] Tagging `v0.1.0` produces per-OS archives, checksums, and an SBOM on a
      draft GitHub Release. _CPack archive verified locally; the workflow is
      unrun._
- [ ] Devcontainer opens and builds in VS Code and Codespaces. _Dockerfile
      written; no Docker available in the authoring environment._
- [x] `README`, `CONTRIBUTING.md`, `SECURITY.md`, and `docs/dependencies.md`
      exist and match the repo.

## Verification status

What was actually executed while building this skeleton, on Debian 12 arm64 with
CMake 4.4.5, Ninja 1.13.2 and Clang 23.1.5 + libc++ sideloaded from upstream
release archives:

| Check | Result |
| --- | --- |
| `cmake --workflow` (debug, sanitizers, `-Werror`) | 16/16 tests pass from a clean tree |
| `cmake --workflow` (release, hardening, LTO) | 14/14 tests pass |
| ASan self-test | Reports `heap-buffer-overflow`, test passes on that report |
| UBSan self-test | Reports `signed integer overflow`, test passes on that report |
| `cmake --install` + `find_package(ACME)` | Consumer builds and runs against the release install |
| `cpack` | `acme-0.1.0-Linux-aarch64.tar.gz` with bin, include, lib and cmake config |
| clang-format | Clean across all sources |
| clang-tidy | Clean across all sources |
| `scripts/check-suppressions.sh` | Clean; rejects all four blanket forms tested |
| `actionlint` | Clean across all four workflows, including its shellcheck pass |
| Hardening probes | `-fcf-protection=full` correctly rejected on arm64, `-mbranch-protection=standard` accepted |
| macOS, Apple Clang 21.0.0 (Xcode 26) | `cmake --workflow --preset dev` configures, builds and tests, including the ASan and UBSan self-tests |
| vcpkg manifest mode, real run | `gtest:arm64-osx@1.18.0` installed from the pinned baseline and cached, on macOS |

**Verified later, on a developer Mac:** the macOS path and vcpkg manifest mode.
`cmake --workflow --preset dev` runs green with Apple Clang 21.0.0 under Xcode
26, and vcpkg installed `gtest:arm64-osx@1.18.0` from the pinned baseline. That
run is also what exposed the AppleClang floor bug in Amendment 10.

**Still not verified:** the GCC path (the authoring host had GCC 12.2, below the
floor); Windows and MSVC (no runner); the devcontainer image (no Docker
available); and every GitHub Actions workflow end to end. In the authoring
environment `codeload.github.com` was blocked, so GoogleTest was built from
source there and consumed through the same `find_package(GTest)` path vcpkg
satisfies; the macOS run has since exercised vcpkg itself.

## Milestones

The core skeleton is usable after week 1; the full scope lands in three weeks for
one engineer.

| Milestone | When | Scope | Exit gate |
| --- | --- | --- | --- |
| M1 Skeleton | Days 1-3 | Tree and CMakeLists; presets and vcpkg; lib, app, first tests | Dev workflow green on all three OSes |
| M2 CI and gates | Days 4-7 | CI matrix; warnings as errors; sanitizers, tidy | **All checks required on `main` (end of week 1)** |
| M3 Dev experience | Week 2 | Devcontainer; pre-commit, clangd; README, CONTRIBUTING | Devcontainer builds in VS Code and Codespaces |
| M4 Ship-ready | Week 3 | Hardening flags; install and CPack; SBOM, nightly jobs | `v0.1.0` tagged with artifacts and SBOM |

Week 1 closes when every CI check is required on `main`, which is the point the
team can start product work.

All four milestones' deliverables are committed. What remains is execution that
needs infrastructure this environment does not have: a first CI run to prove the
matrix, a devcontainer build, and a `v0.1.0` tag.

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| C++26 is delayed or loses Contracts after the failed DIS ballot | High | Low | Baseline is C++23; C++26 stays opt-in per build |
| GCC 16 changed the ABI of some C++20 library components versus older GCC ([migration notes](https://www.elcsoft.cl/en/blog/tech/2026/05/03/gcc-16-technical-migration-guide-cpp20-sarif/)) | Medium | Medium | Never mix prebuilt binaries across GCC majors; vcpkg binary cache keyed on compiler version |
| `ubuntu-latest` and other floating labels change compilers under us | High | Medium | Explicit runner labels, including `windows-2025-vs2026`; pinned versions selected from `.tool-versions` |
| Pinned compilers lag the PRD's recommendation because hosted runners lack GCC 16 / Clang 23 | High | Low | Floors are 14 and 21, well below the pins; nightly job tracks pre-releases ([ADR](adrs/2026-11-11.adr-pin-to-runner-toolchains.md)) |
| MSVC 14.52 slips past November 2026 | Medium | Low | Floor is 14.50 LTS; CMake maps C++23 to `/std:c++latest` until 14.52 |
| CMake `import std` gate changes between releases | High | Low | Modules are a non-goal for v1; scanning is off |
| Sanitizer or tidy noise erodes trust in CI | Medium | Medium | Changed-files tidy on PRs, TSan nightly-only, named suppressions only |
| Someone installs from a sanitizer build and ships an unlinkable package | Medium | Medium | `cmake/Install.cmake` warns at configure time; CI installs from `release`; the consumer job would catch it ([ADR](adrs/2026-11-11.adr-split-options-targets.md)) |
| LTO in a distributed static library produces an archive consumers cannot link | Medium | Medium | LTO is applied to executables only; the installed library stays native objects |
| A restricted network blocks `codeload.github.com`, so vcpkg cannot fetch ports | Low | Medium | Use `X_VCPKG_ASSET_SOURCES` or a pre-populated binary cache; `git clone` alone is not enough |

## Open questions

All of the PRD's original open questions are resolved in
[Decisions taken](#decisions-taken). What is still open:

- [ ] Does the team want Linux arm64 (`ubuntu-26.04-arm`) and Windows arm64 in
      the matrix, or is x64 plus Apple silicon enough for now?
- [ ] Who are the named owners in `docs/dependencies.md`? It currently lists a
      single placeholder owner.
- [ ] Is the 80% line-coverage target by M4 the right number, and should it ever
      become blocking rather than report-only?
- [ ] Which mailbox receives security reports if GitHub private vulnerability
      reporting is not enabled?

## Amendments

Changes made to this document on 2026-11-11 while implementing it, each driven by
something found during the build:

1. **Pinned compiler versions lowered to what hosted runners carry** (GCC 15.2,
   Clang 22.1 instead of 16.2 and 23.1), with floors unchanged at GCC 14 and
   Clang 21. GCC 16 has no Ubuntu package and neither compiler is on a hosted
   image. [ADR](adrs/2026-11-11.adr-pin-to-runner-toolchains.md)
2. **Windows runner changed from `windows-2025` to `windows-2025-vs2026`.**
   `windows-2025` provisioned Visual Studio 2022 with MSVC toolset 14.4x, below
   this PRD's own 14.50 floor.
3. **One options target became two.** An exported options target forces our
   warnings and sanitizer flags onto consumers, so public usage requirements and
   build-only strictness are now separate targets.
   [ADR](adrs/2026-11-11.adr-split-options-targets.md)
4. **LTO scoped to executables.** A static library built with `-flto` holds
   bitcode that plain `ld` rejects, which broke the `find_package` acceptance
   criterion until it was scoped.
5. **Install from a sanitizer build is now a documented hazard** with a
   configure-time warning, and the CI install test uses the `release` preset.
6. **Sanitizer acceptance criteria became automated tests.** The deliberate OOB
   read and signed overflow are two binaries in `tests/selftest/` that pass only
   when the sanitizer reports the defect, rather than a manual check.
7. **Module scanning explicitly disabled**, since the modules policy is
   headers-only and scanning costs a `clang-scan-deps` run per translation unit.
   [ADR](adrs/2026-11-11.adr-headers-not-modules.md)
8. **Optional accelerators moved out of the presets.** Naming ccache or mold in a
   preset breaks a fresh clone on a machine without them, so both are probed at
   configure time.
9. **CI job count rose from five to seven**, adding the install-consumer and
   clang-format jobs that the acceptance criteria imply.
10. **AppleClang floor corrected from 26.4 to 17.0.** The PRD stated the Apple
    Clang floor as an Xcode version, but Apple Clang is versioned against the
    upstream LLVM release it is built from: Xcode 26.x reports AppleClang
    21.0.0. A floor of 26.4 rejected every Mac, which is how it was found. The
    floor is now chosen from libc++ `<expected>` and `<format>` support.
11. **Warning and clang-tidy check lists extended** to what is actually
    configured, and the GCC-only warnings separated, since Clang errors on
    `-Wnull-dereference`.

## Sources

- [Herb Sutter, C++26 trip report, March 2026](https://herbsutter.com/2026/03/)
- [iThome, C++26 DIS ballot result](https://www.ithome.com.tw/news/180248)
- [Phoronix, GCC 16.2 released](https://phoronix.com/news/GCC-16.2-Released)
- [Phoronix, LLVM/Clang 23.1 released](https://www.phoronix.com/news/LLVM-23.1-Released)
- [Kitware, CMake 4.4.1](https://www.kitware.com/cmake-4-4-1-available-for-download/)
- [Microsoft Learn, MSVC compiler versions](https://learn.microsoft.com/cpp/overview/compiler-versions)
- [Microsoft C++ blog, MSVC 14.52 release candidate](https://devblogs.microsoft.com/cppblog/msvc-build-tools-version-14-52-release-candidate-now-available)
- [wrocpp, C++ modules in 2026](https://wrocpp.github.io/posts/modules-2026/)
- [GitHub changelog, Ubuntu 26.04 runners and ubuntu-latest migration](https://github.blog/changelog/2026-09-17-ubuntu-26-generally-available-and-latest-migration)
- [OpenSSF Compiler Options Hardening Guide](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++)
- [GCC 16 migration guide (ELC Soft)](https://www.elcsoft.cl/en/blog/tech/2026/05/03/gcc-16-technical-migration-guide-cpp20-sarif/)
- [actions/runner-images](https://github.com/actions/runner-images) - the source
  for every runner toolchain version quoted above, read on 2026-11-11
