# ADR-0006: A `module-design` skill, and declining the context-document model

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

The skill catalog covers the altitudes around designing a module but not
designing the module itself:

- `/lazy` asks whether the code should exist at all — the rung before design.
- `/complexity-audit` scans the whole tree for over-engineering after the fact.
- `/rfc` (and the Codex `architect` skill) reason about system-level decisions.

Nothing covers the middle: shaping a module so a small, stable interface hides
substantial implementation. That is a recurring, persona-aligned concern
(information hiding, composition over inheritance, no premature abstraction).

A broader family of workflow skills is possible that would be built on a
repo-wide context-document and issue-tracker model: a glossary document with an
ADR lifecycle, a spec-to-tickets-to-implementation pipeline, and multi-session
investigation maps. Adopting that would introduce persistent repo artifacts and
a tracker dependency this kit has deliberately avoided.

## Decision

Add a `module-design` process skill, written in this kit's voice. Ship it to all
four tools, matching the parity of the rest of the catalog:

- Claude Code: `claude-code/.claude/skills/module-design/SKILL.md`
- Gemini CLI: `gemini/commands/module-design.toml`
- Copilot: `copilot/workspace-template/.github/prompts/module-design.prompt.md`
- Codex: `codex/skills/module-design/SKILL.md` + `agents/openai.yaml`

Foreground it in the generated `recommended-skills.md` view for the profiles
that own module design: the `architecture-focused` workflow and the `staff` /
`principal` seniority sets, in both `scripts/create-persona.{sh,ps1}`.

Explicitly **decline, for now**, the context-document / tracker pipeline (a
glossary-document lifecycle, spec-to-tickets-to-implementation automation, and
multi-session investigation maps). Those are a separate architectural
commitment, not a skill add, and the implementation-automation parts also cross
into codegen orchestration, against this kit's "process skills, not codegen
skills" identity.

## Consequences

### Positive
- Fills the design-altitude gap with a skill that fits the persona's biases.
- Ports cleanly: it is stateless prose, so no new repo state or tracker.
- Foregrounded only for the profiles who reach for it; every profile still ships
  it (recommended-skills is a view, not an install — see ADR-0003 / ADR-0004).

### Negative
- One more process skill to maintain, and four near-parallel port files to keep
  roughly aligned as the skill evolves (the standing cost of the parity model).

### Neutral
- The default profile's generated `recommended-skills.md` now lists
  `module-design`. The persona canon files (`persona.md`, `CLAUDE.md`) are
  unchanged; ADR-0004's byte-identical guarantee covers those, not the generated
  view.
- `check-recommended-skills.sh` validates the new name against the Claude
  catalog across all 32 profiles, so the mapping cannot reference a missing
  skill.

## Alternatives Considered

- **Fold it into `/complexity-audit`.** Rejected: the audit is a whole-tree,
  after-the-fact scan; module-design is a during-design aid. Different job,
  different trigger.
- **Fold it into `/rfc` or Codex `architect`.** Rejected: those operate at
  system altitude. Module-interface depth is a distinct, lower altitude.
- **Adopt a repo-wide context-document and tracker model wholesale.** Rejected
  as out of scope: it introduces persistent repo artifacts and a tracker
  dependency the kit avoids. Revisit behind its own ADR if a ubiquitous-language
  layer is ever wanted.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 / ADR-0004 — the persona axes and the recommended-skills view.
