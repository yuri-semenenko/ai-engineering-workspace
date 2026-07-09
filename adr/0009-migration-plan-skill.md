# ADR-0009: A `migration-plan` skill for safe incremental migrations

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

Migration and refactor planning in long-lived codebases — framework upgrades,
design-system swaps, API version migrations, legacy-to-modern replacement — is a
recurring per-sprint activity, and the kit only touches it as one bullet: the
`Migration Strategy` section inside `/rfc` (and the Codex `architect` skill that
defers to it). There is no operational loop for the execution: no seam placement,
no strangler / adapter / expand-contract shapes, no feature-flag lifecycle, no
before/after verification, no rollback criteria.

That gap is persona-aligned: evolutionary architecture, incremental migrations,
vertical slices over big-bang cutover, and keeping user-visible behavior stable.

## Decision

Add a `migration-plan` process skill, written in this kit's voice. Ship it to all
four tools, matching the parity of the rest of the catalog:

- Claude Code: `claude-code/.claude/skills/migration-plan/SKILL.md`
- Gemini CLI: `gemini/commands/migration-plan.toml`
- Copilot: `copilot/workspace-template/.github/prompts/migration-plan.prompt.md`
- Codex: `codex/skills/migration-plan/SKILL.md` + `agents/openai.yaml`

It runs a fixed loop: pin the invariant, map current to target and name the seam,
choose a migration shape, slice into independently shippable steps, gate each with
before/after verification, plan rollout and rollback, and sequence by risk. It is
stateless prose: no persistent repo artifact, no tracker.

Foreground it in the generated `recommended-skills.md` view for the profiles that
own migrations: the `staff` and `principal` seniority sets and the
`architecture-focused` workflow, in both `scripts/create-persona.{sh,ps1}` — the
same placement as module-design and research.

Position it as the executable plan an RFC hands off to, not a competing design
doc, and keep it paired with `module-design` for seam and adapter choices.

## Consequences

### Positive
- Turns the RFC's one-line Migration Strategy into a repeatable, reversible loop.
- Fits the persona's evolutionary-architecture and incremental-migration biases.
- Ports cleanly: it is stateless prose, so no new repo state or tracker.

### Negative
- One more process skill to maintain, and four near-parallel port files to keep
  roughly aligned (the standing cost of the parity model).
- Broad subject (strangler, adapter, flags, rollback); the skill must stay one
  tight loop or it will sprawl into a handbook.

### Neutral
- The default profile's generated `recommended-skills.md` now lists
  `migration-plan`. The persona canon files (`persona.md`, `CLAUDE.md`) are
  unchanged.
- `check-recommended-skills.sh` validates the new name against the Claude catalog
  across all 32 profiles.

## Alternatives Considered

- **Leave migration planning inside `/rfc` section 9.** Rejected: the RFC decides
  whether and what to migrate; the execution plan is a different altitude and a
  different trigger, and cramming both bloats the RFC and buries the rollback plan.
- **Fold it into `/module-design`.** Rejected: module-design shapes the target
  interface; migration-plan sequences getting there safely. They pair, they are
  not the same job.
- **Fold it into `/spec`.** Rejected: spec pins "done" for one change;
  migration-plan sequences many changes over time behind a stable invariant.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 / ADR-0004 — the persona axes and the recommended-skills view.
- ADR-0006 / ADR-0007 / ADR-0008 — module-design, codebase-map, and research, the prior catalog additions.
