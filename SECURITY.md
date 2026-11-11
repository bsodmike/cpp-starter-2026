# Security Policy

## Reporting a vulnerability

Report suspected vulnerabilities privately through GitHub's
[private vulnerability reporting](https://github.com/inertialbox/experiment-cpp-starter/security/advisories/new),
which opens a draft advisory visible only to the maintainers.

Do not open a public issue for a security report, and do not include a working
exploit in the initial report; a description of the class of problem and the
affected version is enough to start.

Expect an acknowledgement within three working days and an assessment within ten.
If a fix is needed we will agree a disclosure date with you before publishing.

> Replace the reporting address above with a monitored mailbox if private
> vulnerability reporting is not enabled for this repository.

## Supported versions

Until `v1.0.0`, only the latest tagged release receives fixes.

| Version | Supported |
| --- | --- |
| `0.1.x` | Yes |
| older | No |

## What we do on our side

- **Hardened release builds.** Release artifacts are compiled with the
  [OpenSSF Compiler Options Hardening Guide](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++)
  flag set, probed per toolchain in `cmake/Hardening.cmake`.
- **Standard-library hardening** stays on in debug and release builds.
- **Sanitizers on every PR.** ASan and UBSan gate merges; TSan runs nightly.
- **Pinned dependencies.** `vcpkg.json` pins every port through
  `builtin-baseline`; GitHub Actions are pinned by commit SHA.
- **Scanning.** OSV-Scanner runs on dependency changes and weekly on `main`.
- **Provenance.** Releases carry a CycloneDX SBOM, SHA-256 checksums and GitHub
  artifact attestations.

## Reporting a problem in a dependency

Report it upstream first, then open an issue here referencing the advisory so we
can pin or override the affected version in `vcpkg.json`.
