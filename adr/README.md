# Architecture Decision Records

This repository ships an `adr` skill. It would be a poor advertisement for the
skill if the repo recorded none of its own decisions. These ADRs capture the
non-obvious architectural choices behind the kit, for the contributor who later
asks "why is it built this way?"

They follow the format described in
[`docs/principles/documents.md`](../docs/principles/documents.md). ADRs are
immutable once accepted: a changed decision is a new ADR that supersedes the old
one, not an edit here.

| ADR | Decision | Status |
| --- | --- | --- |
| [0001](./0001-single-canon-with-generated-mirrors.md) | One canon with generated, drift-guarded mirrors instead of hand-maintaining each tool | Accepted |
| [0002](./0002-commit-mirrors-instead-of-generating-at-install.md) | Commit the mirrors rather than generating them at install time | Accepted |
| [0003](./0003-persona-discipline-and-seniority-axes.md) | Persona identity layer gains discipline and seniority axes; methodology canon stays fixed | Accepted |
| [0004](./0004-persona-workflow-axis.md) | Persona identity layer gains a workflow axis, shaping the recommended-skills view only | Accepted |
| [0005](./0005-start-entrypoint.md) | A thin `/start` onboarding entrypoint per tool, wrapping the central persona wizard | Accepted |

For a standalone example of the format applied to a fictional decision, see
[`examples/adr-sample.md`](../examples/adr-sample.md).
