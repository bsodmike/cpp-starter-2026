# AGENTS.md

Guidance for AI coding agents working in this repo.

## Context

- `docs/PRD.md` at the root of this project is the Product Requirements Document (PRD).
- _Grilling_ and/or _Planning_ (plan mode): at the end, record any appropriate changes in the PRD so that it always stays a valid document. You may create ADRs (Architecture Decision Records) as appropriate in `docs/adrs`. All ADRs should use the format `YYYY-MM-DD.adr-<DESC>.md`, where `<DESC>` is a short description that is (i) lowercase and (ii) separated by single dashes only.

## Writing code

- Do not use emojis anywhere in code or docs.

### Writing Rust code

- Limit comments to 1 to 2 lines and keep them short. If a comment adds nothing beyond what the function name already says, leave it out. Do not add verbose `///` doc comments that add no real information.

