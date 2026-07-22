# ADR-0011: Declared gather/judge orchestration for the review skills

- **Status:** Accepted
- **Date:** 2026-07-22
- **Deciders:** Yuri Semenenko

## Context

ADR-0010 wired a tiered-delegation note into the gather/judge skills, `pr-classify`
among them. That note is ad-hoc ("on a large diff") and it never reached
`pr-recheck`. PR review is the kit's highest-frequency task, so the review pass is
exactly where an optional, per-run decision is the wrong default: the same
sequence should run every time.

A separate exploration proposed making review repeatable by adding a new
report-only orchestration layer with its own contracts, example state schemas, and
an L0-L3 autonomy ladder. It was rejected: it duplicated coverage the review
skills already provide, had no invocation path, and added validation weight
disproportionate to two hand-authored contracts. The transferable ideas from it
are the gather/judge split and an autonomy vocabulary, and both belong inside the
skills that already exist rather than in a layer above them.

## Decision

`pr-classify` (first pass) and `pr-recheck` (follow-up) declare a fixed, repeatable
gather/judge sequence instead of an ad-hoc one:

- **Gather** is read-only and isolatable to cheaper-tier subagents. `pr-classify`
  orients on the changed surface, then gathers by angle; `pr-recheck` loads the
  open threads and the new work. Each returns compact evidence with `file:line`,
  not conclusions.
- **Judge** stays on the main model: classification, the confidence call, the
  verification matrix, and the verdict. A subagent finding is evidence, not a
  ruling.

Each skill keeps its own action profile. `pr-classify` is report-first; posting
inline comments is opt-in and gated. `pr-recheck` may resolve threads, post, and
approve, but only behind its existing explicit confirmation gates. There is no
shared autonomy level: the action boundary lives in each skill.

Consistent with ADR-0010, the discipline is canon and tool-agnostic. Skills carry
the decision; each runtime supplies its own mechanism. Claude, Gemini, and Codex
get real subagent isolation; Copilot degrades to a sequential gather-then-judge
pass.

## Key boundaries

- Not a new orchestration layer, loop contract, or state file. Cross-run state
  stays where it already is: `pr-recheck` reads the PR's own review threads.
- Not a new skill. No catalog-count change.
- Not an autonomy ladder. Action limits stay per-skill and gated.

## Consequences

### Positive

- The highest-frequency task runs the same disciplined sequence every time:
  consistent reviews, cheaper gathering on lower tiers, judgment preserved.
- `pr-recheck` gains the delegation discipline it lacked.

### Negative

- Each of the two skills carries a slightly longer delegation note; they must stay
  tight or they bloat, the same risk ADR-0010 flagged.
- The sequence is a judgment the model still applies; a skill can point at it but
  cannot enforce it.

### Neutral

- Ports are owned-here and hand-authored, not generated. Each tool's PR-review
  port is updated by hand to match; the structure drift guard is unaffected.

## Alternatives Considered

- **A new report-only orchestration layer** with loop contracts, example state
  schemas, and an L0-L3 autonomy ladder. Rejected: duplicated existing skill
  coverage, no invocation path, validation weight out of proportion to two
  hand-authored contracts.
- **A single `pr-review` umbrella skill** composing the others. Deferred:
  `pr-classify` already composes angles internally, and a wrapper adds a skill plus
  a naming overlap with existing review commands for thin benefit. Revisit if a
  single entrypoint is later wanted.
- **Leave delegation ad-hoc.** Rejected: "on a large diff" makes the sequence
  optional, which is what undermines repeatability for a task run many times a day.

## References

- ADR-0010 — tiered delegation in skills; this sharpens the review pair.
- ADR-0006 — process skills, not codegen orchestration.
- `pr-classify` and `pr-recheck` skills.
