# ADR-0001: One canon with generated, drift-guarded mirrors

- **Status:** Accepted
- **Date:** 2026-07-04
- **Deciders:** Yuri Semenenko

## Context

The same persona and durable-memory content must drive several AI assistants
(Claude Code, Codex, and more later). Each tool wants that content in its own
location and, in some cases, its own shape. Maintaining the same methodology by
hand in three places guarantees drift: an edit lands in one tool's config and
silently diverges from the others, and the "single engineering workflow" promise
quietly stops being true.

## Decision

We will keep a single **canon** — the persona template and the memory seed under
`persona/` and `claude-code/` — as the only place methodology content is edited.
Everything a second tool needs is **generated** from that canon by
`scripts/sync-codex-references.{sh,ps1}`. A `--check` mode diffs canon against the
generated output and exits non-zero on any difference; it runs as a pre-commit
hook and in CI, so a stale mirror is a hard error rather than a silent
inconsistency.

## Consequences

### Positive
- One edit point. The methodology cannot drift between tools without CI failing.
- The "one workflow, many tools" claim is enforced mechanically, not by
  discipline alone.

### Negative
- Editing the canon requires regenerating and committing the mirrors. Forgetting
  is caught by the guard, but it is an extra step.

### Neutral
- Contributors must run the sync script after touching canon files, and the
  pre-commit hook must be enabled once per clone.
- Not everything is generated: Codex skills are hand-authored ports with no canon
  to generate from, so the guard validates their *structure* instead of their
  content.

## Alternatives Considered

- **Hand-maintain each tool's config.** Rejected: drift is inevitable and
  invisible until someone notices two tools behaving differently.
- **Symlink one file into every tool location.** Rejected: tools expect different
  paths and shapes, and it breaks standalone portability (see ADR-0002).

## References

- [`docs/architecture.md`](../docs/architecture.md) — full design.
- ADR-0002 — why the mirrors are committed rather than generated at install time.
