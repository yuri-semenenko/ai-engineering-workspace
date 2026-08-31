# ADR-0015: Codex skills carry canon names

- **Status:** Accepted
- **Date:** 2026-08-31
- **Deciders:** Yuri Semenenko

## Context

`codex/skills/` is owned here rather than generated: hand-authored ports with no
canon to regenerate from, so the sync guard validates their structure and never
their names ([ADR-0001](./0001-single-canon-with-generated-mirrors.md)). That
freedom let three of them drift from the canon vocabulary.

- `failure-investigation` is the canon `debug` skill under another name.
- `test-strategy` is the canon `testing-checklist` under another name.
- `pull-request-workflow` bundles what the canon splits three ways, into
  `pr-classify`, `pr-comment`, and `pr-recheck`.

Gemini, ported later, took the canon names as a matter of course: all 21 of its
command ports match a canon skill name exactly. Codex was the only outlier, and
nothing caught it, because ADR-0006 through ADR-0009 each added a skill without
saying which tools must carry it, or under what name.

The cost is invisible to the guards but real to a reader. ADR-0011 already
reasons about "the review skills (`pr-classify`, `pr-recheck`)" as kit
vocabulary, and those skills did not exist in Codex. `codex/README.md`
advertised `$debug`, which resolved to nothing. And the README's claim that
nobody gets a different engineering methodology is weakened when one practice
answers to two names depending on which assistant is open.

## Decision

A Codex skill that realizes a canon skill carries the canon's name, verbatim. A
Codex skill keeps a name of its own only where the canon has no counterpart.
Where the canon splits a practice across several skills, Codex splits it the same
way rather than bundling it.

Applied now:

| Was | Is |
| --- | --- |
| `failure-investigation` | `debug` |
| `test-strategy` | `testing-checklist` |
| `pull-request-workflow` | `pr-classify`, `pr-comment`, `pr-recheck` |

`architect`, `context-brief`, `project-onboarding`, and `prompt-engineer` keep
their names: the canon has no equivalent skill for any of them.

This rule governs names, not content. Codex ports stay deliberately condensed
against their canon counterparts, and this decision does not change that.

## Consequences

### Positive

- One vocabulary across the tools. ADR-0011's "review skills" now name real
  Codex skills, and a reader who learns the practice once can invoke it in any
  assistant.
- `$debug` resolves to a skill instead of nothing.
- `pr-recheck` becomes reachable in Codex at all. It previously existed as a
  single paragraph inside the bundle, which is not enough to run a second pass
  from.

### Negative

- Anyone who already installed Codex keeps the old directories in `$CODEX_HOME`.
  The installer copies and does not prune, so `failure-investigation`,
  `test-strategy`, and `pull-request-workflow` linger until removed by hand.
- The naming rule is a convention. The structure guard checks that a skill's
  frontmatter `name` matches its directory, which a divergent name satisfies
  just as well as a canon one, so nothing mechanical stops the next drift.

### Neutral

- `codex/skills/` goes from 15 entries to 17. The split adds two directories
  without adding any methodology.

## Alternatives Considered

- **Keep the divergence and document it.** Rejected: documenting two names for
  one practice still leaves a reader learning both, and it concedes the
  one-methodology claim rather than defending it.
- **Rename `architect` as well.** Rejected on the evidence. It is not a
  duplicate of `rfc`: it implements the persona's Decision-Making Framework and
  explicitly defers to `rfc` for the full ten-section format. ADR-0006
  considered folding `module-design` into it and rejected that, ADR-0009
  references it by name, and `docs/principles/working-with-agents.md` uses
  `architect` as the name of a step in the shared delegation workflow. Renaming
  it would contradict two accepted records and a principles document.
- **Port every remaining canon skill into Codex for full parity.** Rejected:
  matching counts is not the goal. Codex carries what its surface warrants, and
  a port with nothing to add is a file to maintain for no reader.
- **Add a guard that fails when a Codex skill name has no canon counterpart.**
  Rejected for now: four legitimate Codex-only skills exist, so the guard would
  need an allowlist, and that allowlist would be this ADR written in another
  format. Revisit if the drift recurs.

## References

- [ADR-0001](./0001-single-canon-with-generated-mirrors.md) — why `codex/skills/`
  is owned here rather than generated.
- [ADR-0011](./0011-declared-review-orchestration.md) — the review skills whose
  names this aligns Codex to.
- [`docs/principles/working-with-agents.md`](../docs/principles/working-with-agents.md)
  — the delegation workflow that gives `architect` its meaning as a step.
