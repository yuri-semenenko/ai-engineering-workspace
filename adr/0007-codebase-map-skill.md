# ADR-0007: A `codebase-map` skill for fast orientation in unfamiliar code

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

The skill catalog helps you plan, build, review, and clean up code, but nothing
helps you *understand* code you did not write before you touch it. Landing in an
unfamiliar repo, a subsystem you don't own, or reviewing a PR in code you don't
know is a recurring weekly activity for a Staff IC.

The closest existing skill is the Codex `project-onboarding` workflow, but that
is scoped to authoring a durable `AGENTS.md` (agent configuration) and only
exists on Codex. Nothing orients a human or reviewer for comprehension, on any
tool. The gap is persona-aligned: ubiquitous language and domain boundaries
(pragmatic DDD), fast orientation, Chesterton's Fence (do not touch what you do
not understand), and the session-hygiene rule to explore via subagents rather
than inline grep.

## Decision

Add a `codebase-map` process skill, written in this kit's voice. Ship it to all
four tools, matching the parity of the rest of the catalog:

- Claude Code: `claude-code/.claude/skills/codebase-map/SKILL.md`
- Gemini CLI: `gemini/commands/codebase-map.toml`
- Copilot: `copilot/workspace-template/.github/prompts/codebase-map.prompt.md`
- Codex: `codex/skills/codebase-map/SKILL.md` + `agents/openai.yaml`

It is a read-first orientation pass that produces a short, high-signal map (what
it is, entry points, architecture sketch, domain glossary, key seams, risky
areas, how to run and test, known tradeoffs), fanning out via Explore subagents
on Claude to keep the main context lean. It is stateless prose: no persistent
repo artifact, no tracker.

Foreground it in the generated `recommended-skills.md` view for the profile that
owns orientation: the `learning-focused` workflow, in both
`scripts/create-persona.{sh,ps1}`.

Keep it distinct from the Codex `project-onboarding` skill: codebase-map orients
a reader for comprehension and can feed an `AGENTS.md` pass; project-onboarding
authors that durable config. Continue to decline the repo-wide context-document
and tracker pipeline (per ADR-0006).

## Consequences

### Positive
- Fills the comprehension-altitude gap with a skill that fits the persona's
  biases (ubiquitous language, Chesterton's Fence, subagent-first exploration).
- Ports cleanly: it is stateless prose, so no new repo state or tracker.
- Doubles as a safe pre-flight for pointing an agent at unfamiliar code.

### Negative
- One more process skill to maintain, and four near-parallel port files to keep
  roughly aligned as the skill evolves (the standing cost of the parity model).
- Adjacent to Codex `project-onboarding`; the boundary must be held in the prose
  or the two will blur.

### Neutral
- The default profile's generated `recommended-skills.md` now lists
  `codebase-map` under "Also in the catalog" (`architecture-focused` does not
  foreground it). The persona canon files (`persona.md`, `CLAUDE.md`) are
  unchanged.
- `check-recommended-skills.sh` validates the new name against the Claude catalog
  across all 32 profiles, so the mapping cannot reference a missing skill.

## Alternatives Considered

- **Fold it into Codex `project-onboarding` / an AGENTS.md pass.** Rejected:
  different job (comprehension vs durable agent config) and different audience (a
  reader vs the agent). codebase-map can precede and feed project-onboarding, not
  replace it.
- **Fold it into `/complexity-audit`.** Rejected: the audit is a critique of
  over-engineering; codebase-map is neutral comprehension. Different trigger,
  different output.
- **Fold it into `/debug`.** Rejected: debug drives a known failure; codebase-map
  orients before any failure is known.
- **Adopt a repo-wide context-document and glossary lifecycle wholesale.**
  Rejected as out of scope, per ADR-0006: it introduces persistent repo artifacts
  and a tracker dependency the kit avoids.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 / ADR-0004 — the persona axes and the recommended-skills view.
- ADR-0006 — the module-design skill and the declined context-document model.
