# Dependency allowlist

Every third-party dependency is listed here with its licence and an owner. A new
dependency needs a review from one of the owners below, and a row in this table
in the same PR.

Versions are pinned by `builtin-baseline` in [vcpkg.json](../vcpkg.json), which
is a single vcpkg commit that fixes the version of every port at once. The
baseline commit is mirrored in [.tool-versions](../.tool-versions).

## Build and test dependencies

| Dependency | Version | Licence | Used by | Owner | Why |
| --- | --- | --- | --- | --- | --- |
| [GoogleTest](https://github.com/google/googletest) | 1.18.0 | BSD-3-Clause | `tests/` (feature `tests`) | @inertialbox | Unit test framework; `gtest_discover_tests` integrates with CTest |
| [google/benchmark](https://github.com/google/benchmark) | 1.9.5 | Apache-2.0 | `benchmarks/` (feature `benchmarks`) | @inertialbox | Micro-benchmarks; off by default |

`acme::core` and `acme_app` have **no** runtime dependencies beyond the C++
standard library. Keep it that way unless there is a reason in a PR.

## Toolchain

Pinned in [.tool-versions](../.tool-versions), not here. See
[the C++23 baseline ADR](adrs/2026-11-11.adr-cxx23-baseline.md) for the
compiler floors and why they are what they are.

## Rules

1. **vcpkg manifest mode only.** No `FetchContent` for project dependencies, no
   Conan in the same repo, no vendored copies. See
   [the package manager ADR](adrs/2026-11-11.adr-vcpkg-manifest-mode.md).
2. **Pin through the baseline.** Use `"version>="` for a floor. An `overrides`
   entry needs an exact version and a comment saying why it deviates.
3. **Licence check.** Permissive licences (MIT, BSD, Apache-2.0, BSL-1.0) are
   fine. Anything copyleft (GPL, LGPL, AGPL) or source-available (SSPL, BUSL)
   needs a decision recorded in an ADR before it goes in.
4. **Test-only dependencies belong behind a feature** in `vcpkg.json`, so a
   consumer building the library does not pay for them.
5. **Actions are dependencies too.** Pin them by commit SHA with the version in
   a trailing comment.

## Reviewing a bump

Dependabot or Renovate opens monthly PRs against `builtin-baseline` and the
pinned action SHAs. Before merging one:

- Read the upstream changelog for ABI or behaviour changes.
- Confirm CI is green on all five jobs, including the compiler-floor job.
- Never reuse a binary cache across compiler major versions; the cache key
  already includes the compiler, so this is automatic in CI.
