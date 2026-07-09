# ADR-0005: A thin `/start` onboarding entrypoint per tool

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

A new adopter clones the kit and has to discover that the first step is running
`scripts/create-persona.{sh,ps1}` to generate their persona. That command lives
in the top-level README, but once someone is already working inside an assistant
(Claude Code, Codex, Gemini CLI, or Copilot) there is no in-tool affordance that
explains the wizard or hands over the exact command for their shell. Each tool
has a native surface for exactly this kind of prompt (Claude/Codex skills,
Gemini commands, Copilot prompts), so the onboarding step can live where the
user already is.

## Decision

Add a `/start` entrypoint as a native surface in each tool:

- Claude Code: `claude-code/.claude/skills/start/SKILL.md`
- Codex: `codex/skills/start/SKILL.md` + `agents/openai.yaml`
- Gemini CLI: `gemini/commands/start.toml`
- Copilot: `copilot/workspace-template/.github/prompts/start.prompt.md`

Each surface is a **thin pointer**, not a second implementation of the wizard.
It explains what the wizard produces (the gitignored `persona.md`, `CLAUDE.md`,
and `recommended-skills.md`), notes that only the identity header varies while
the methodology canon is fixed, asks which shell the user is on, and hands over
the exact `scripts/create-persona.{sh,ps1}` command. The wizard logic stays
centralized in the two central scripts; the start surfaces only explain or
invoke them and never re-ask the wizard's questions.

The Claude and Codex skills explicitly instruct the model **not** to run the
wizard or edit files unless the user asks — the wizard is interactive and writes
the user's personal files. Copilot's `start` prompt is **copy-only and
corporate-safe**: it makes no claim of executing anything, and only surfaces the
manual command for the user to copy and run, consistent with the Copilot
package's locked-down posture.

`/start` is an onboarding entrypoint, distinct from the process skills. Docs
count it separately (for example "16 process skills + `/start`") so it does not
inflate the methodology-skill catalog.

## Consequences

### Positive
- Onboarding is discoverable from inside every supported tool, in that tool's
  native surface.
- No wizard logic is duplicated; the single source of truth stays
  `scripts/create-persona.{sh,ps1}`, so there is nothing to drift.
- No installer changes: each installer already copies its whole skills/commands/
  prompts directory, so the new surface ships automatically.

### Negative
- Four small near-parallel files to keep roughly aligned as the wizard evolves.
  Kept honest by their shared, deliberately minimal content rather than a
  generator.

### Neutral
- The Claude and Codex `start` skill directories now appear in the skill catalog,
  so the generated `recommended-skills.md` lists `start` under "Also in the
  catalog". Harmless: it is a shipped skill, just not one a workflow foregrounds.
- `start.toml` carries Gemini's `{{args}}` placeholder like every other command
  port; that is a Gemini argument slot, not an unfilled persona placeholder.

## Alternatives Considered

- **A single shared onboarding doc linked from each tool.** Rejected: it is not
  invocable as `/start` inside a tool, which is the whole point — users expect a
  native entrypoint, not a link to chase.
- **Have `/start` run the wizard for the user.** Rejected: the wizard is
  interactive and writes personal files. Auto-running it from an assistant fights
  the "do not edit files unless asked" rule and is impossible under Copilot's
  copy-only posture. The entrypoint hands over the command instead.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 / ADR-0004 — the persona identity-layer axes the wizard fills.
- [`README.md`](../README.md) — Quick start and the supported-tools table.
