# Contributing to ACME

## Getting set up

The devcontainer is the supported path and carries every pinned tool:

```sh
# VS Code: "Reopen in Container", or Codespaces
cmake --workflow --preset dev
```

Without the container, install the versions in [.tool-versions](.tool-versions)
and export `VCPKG_ROOT`. `scripts/tool-version.sh <tool>` prints a pin, and is
what CI and the devcontainer read, so nothing drifts.

Install the git hooks once:

```sh
pip install pre-commit
pre-commit install
```

## The build

Everything goes through presets; there are no hand-typed flags.

```sh
cmake --workflow --preset dev        # configure + build + test
cmake --preset dev                   # configure only
cmake --build --preset dev           # build only
ctest --preset dev                   # test only
ctest --preset dev -L unit           # just the unit tests
ctest --preset dev -R ParseInt       # one test by name
```

Build trees land in `build/<preset>/`. Put personal variations in
`CMakeUserPresets.json`, which is gitignored; inherit from a committed preset
rather than copying it:

```json
{
  "version": 6,
  "configurePresets": [
    { "name": "my-dev", "inherits": "dev", "cacheVariables": { "ACME_BUILD_BENCHMARKS": "ON" } }
  ]
}
```

## Where flags live

Two interface targets, and the distinction matters:

- **`acme::options`** carries public usage requirements, which means anything a
  consumer of the installed package must also compile with: the C++23 standard
  and the standard-library hardening macros. It is exported, so adding a flag
  here changes every downstream build. Keep it ABI-relevant only.
- **`acme::build_options`** carries warnings, sanitizers, hardening and
  coverage. Targets link it through `$<BUILD_INTERFACE:...>`, so it applies to
  this build tree and never reaches a consumer.

Never use `include_directories()`, `add_compile_options()` or `CMAKE_CXX_FLAGS`
in the project. Attach everything to a target.

## Adding a library

1. `src/<name>/` with `include/acme/<name>/` for public headers only.
2. In its `CMakeLists.txt`: create the target, add an `acme::<name>` alias, set
   `EXPORT_NAME`, declare public headers through a `FILE_SET`, and link
   `PUBLIC acme::options` plus `PRIVATE $<BUILD_INTERFACE:acme::build_options>`.
3. `add_subdirectory()` it from the root, add it to the `install(TARGETS ...)`
   list in `cmake/Install.cmake`, and give it its own test binary in `tests/`.

Public headers are included as `#include <acme/<name>/thing.hpp>`.

## Adding a dependency

1. Add it to `vcpkg.json`, under a feature if it is only needed for tests or
   benchmarks. Use `"version>="` and leave `builtin-baseline` to pin the rest.
2. Add a row to [docs/dependencies.md](docs/dependencies.md) with its licence
   and an owner. A new dependency needs a review from an existing owner.
3. `find_package(...)` it in the `CMakeLists.txt` that needs it, and link the
   imported target; never a bare library name.
4. Do not add `FetchContent` for project dependencies, and never mix Conan into
   this repo. See [the vcpkg ADR](docs/adrs/2026-11-11.adr-vcpkg-manifest-mode.md).

To move the whole dependency set forward, bump `builtin-baseline` to a newer
vcpkg commit and update the `vcpkg` pin in `.tool-versions` to match.

## Quality gates

A PR merges when it compiles warning-free on four compilers, passes under ASan
and UBSan, and is clean under clang-format and clang-tidy.

| Gate | Locally |
| --- | --- |
| Formatting | `pre-commit run clang-format --all-files` |
| Static analysis | `clang-tidy -p build/dev <files>` |
| Tests + sanitizers | `cmake --workflow --preset dev` |
| Suppressions | `scripts/check-suppressions.sh` |
| Compiler floor | `cmake --preset dev` fails below it |

`-Werror` is CI-only, so a new compiler's new warning never blocks local work.

### Suppressions

A suppression names its check and says why:

```cpp
// NOLINTNEXTLINE(readability-simplify-subscript-expr)  <- plus a reason comment
```

`scripts/check-suppressions.sh` rejects blanket `NOLINT` and
`#pragma warning(disable)`, and runs in CI. To silence a check repo-wide
instead, add it to `.clang-tidy` with its rationale in the comment block beside
the list; `tests/.clang-tidy` does this for test-only relaxations.

## Sanitizer self-tests

`tests/selftest/` holds two binaries that each contain one deliberate defect, an
out-of-bounds read and a signed overflow. The tests pass only when the sanitizer
reports the defect, so they are how we know the sanitizers are actually wired
up. They are built only with `ACME_SANITIZER_SELFTEST=ON`, which the `dev` and
`ci-*` presets set. If you ever see them pass with sanitizers off, something is
wrong with the preset.

## Commits and PRs

- Branch off `main`; `main` is protected and requires passing checks.
- Keep the subject in the imperative mood and under 72 characters.
- A behaviour change comes with a test. A toolchain decision comes with an ADR
  in `docs/adrs/` named `YYYY-MM-DD.adr-<short-description>.md`.
- Update [docs/PRD.md](docs/PRD.md) when a decision there stops being true.

## No emojis

Not in code, comments, commit messages or docs.
