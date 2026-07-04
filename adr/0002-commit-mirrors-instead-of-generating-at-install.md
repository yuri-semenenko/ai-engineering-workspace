# ADR-0002: Commit the mirrors instead of generating them at install time

- **Status:** Accepted
- **Date:** 2026-07-04
- **Deciders:** Yuri Semenenko

## Context

ADR-0001 established that each tool's content is generated from a single canon.
That leaves an open question: *when* is it generated? Two options — generate the
mirrors at install time from the canon, or generate them ahead of time and commit
the result. A second goal constrains the answer: each tool folder should be
**standalone-portable**. You should be able to copy `codex/` alone onto a machine
and have its installer work against the files already present, with no build step
and no access to the canon.

## Decision

We will generate the mirrors ahead of time and **commit them** (under
`codex/references/`). The sync script regenerates them from the canon; the drift
guard (ADR-0001) ensures the committed copy matches. Installers consume the
committed files directly and never run a build.

## Consequences

### Positive
- Each tool folder is a complete, inspectable, copyable unit. `codex/` works when
  copied on its own.
- Installers stay trivial: copy files, no generation, no dependency on the canon
  being present or a shell being able to build it.

### Negative
- Generated artifacts live in version control, which is normally an anti-pattern.
  We accept it deliberately and make it safe with the drift guard.

### Neutral
- The canon and its committed mirror both change in the same commit after a canon
  edit; reviewers see both halves of the change together.

## Alternatives Considered

- **Generate at install time.** Rejected: `codex/` could no longer be copied
  alone — it would need the canon and a working shell to build itself, defeating
  standalone portability.
- **Don't commit; require a build step before use.** Rejected: adds friction and
  a toolchain dependency to what should be a copy-and-go install.

## References

- [`docs/architecture.md`](../docs/architecture.md) — "Why mirrors are committed
  rather than generated at install."
- ADR-0001 — the single-canon decision this builds on.
