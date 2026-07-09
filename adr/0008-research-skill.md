# ADR-0008: A `research` skill for evidence-backed technical decisions

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

The skill catalog can explore a design (`/rfc`), record a decision (`/adr`), and
pin down scope (`/spec`), but the evidence step that should precede an RFC or ADR
lives only implicitly inside them. Comparing libraries, frameworks, APIs, or
approaches with cited primary sources is a recurring weekly activity for a Staff
IC, and today it happens ad hoc.

A heavyweight research capability may exist in a given environment (for example a
fan-out web-search-and-verify report harness), but the kit cannot depend on tools
outside itself and stay portable. What the kit needs is lighter and different in
kind: a bounded, decision-oriented pass that produces a cited decision matrix and
a recommendation with explicit uncertainty, sized to the blast radius of the
decision rather than to how much could be read.

## Decision

Add a `research` process skill, written in this kit's voice. Ship it to all four
tools, matching the parity of the rest of the catalog:

- Claude Code: `claude-code/.claude/skills/research/SKILL.md`
- Gemini CLI: `gemini/commands/research.toml`
- Copilot: `copilot/workspace-template/.github/prompts/research.prompt.md`
- Codex: `codex/skills/research/SKILL.md` + `agents/openai.yaml`

It runs a fixed loop: frame the question and criteria, gather from primary
sources, capture and cite evidence, surface contradictions, build a decision
matrix, recommend with uncertainty, and hand off to `/rfc` or `/adr`. It is
stateless prose: no persistent repo artifact, no tracker.

Foreground it in the generated `recommended-skills.md` view for the profiles that
own technical selection: the `staff` and `principal` seniority sets and the
`architecture-focused` workflow, in both `scripts/create-persona.{sh,ps1}` — the
same placement as module-design.

## Consequences

### Positive
- Fills the evidence-capture gap at the front of the rfc/adr pipeline.
- Portable: kit-native and stateless, so it works without depending on any
  external research tool.
- Bounds a task that otherwise sprawls, by tying depth to the decision.

### Negative
- One more process skill to maintain, and four near-parallel port files to keep
  roughly aligned (the standing cost of the parity model).
- Overlaps in spirit with any heavier external research tool a user already has;
  the boundary (lightweight and decision-scoped, not a full report) must be held
  in the prose.

### Neutral
- The default profile's generated `recommended-skills.md` now lists `research`.
  The persona canon files (`persona.md`, `CLAUDE.md`) are unchanged.
- `check-recommended-skills.sh` validates the new name against the Claude catalog
  across all 32 profiles.

## Alternatives Considered

- **Leave research implicit inside `/rfc`.** Rejected: the RFC then carries both
  the evidence gathering and the option analysis, which bloats it and hides the
  sourcing. A separate, cited brief keeps each job honest.
- **Ship a full fan-out research-report harness.** Rejected: heavier than the
  daily need, harder to port across four tools, and duplicative of external tools
  a user may already run. The kit's value here is the decision-scoped loop.
- **Fold it into `/spec`.** Rejected: spec pins down what "done" means for a
  chosen change; research decides which change to make. Different altitude,
  different trigger.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 / ADR-0004 — the persona axes and the recommended-skills view.
- ADR-0006 / ADR-0007 — module-design and codebase-map, the prior two catalog additions.
