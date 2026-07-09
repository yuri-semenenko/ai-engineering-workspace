# ADR-0010: Operationalize tiered delegation inside the skills

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

The persona canon already defines model-tier delegation (`Model Defaults` +
`Delegation`): auto-delegate well-scoped mechanical work, broad read-only search,
and evidence-gathering to a cheaper-tier subagent, and keep architecture, review,
and hard judgment on the main-loop model. The principle exists, but the skills do
not point at it at their own decision points, so it does not reliably fire during
a debug, review, migration, or testing pass.

The three code-capable tools now all have native subagents with per-subagent
model tiers and read-only scoping:

- **Claude Code** — `Task`/`Agent` with a `model` override; the read-only
  `Explore` agent type.
- **Gemini CLI** — `.gemini/agents/*.md` with `model:` and a `tools:` allowlist;
  a built-in `codebase_investigator`.
- **Codex** — `spawn_agent` plus per-agent TOML with `model` and
  `sandbox_mode = "read-only"`; a built-in `explorer`.

Copilot has no subagent model. So the principle ports to three of four tools, and
degrades cleanly on the fourth.

## Decision

Wire a short, tool-agnostic delegation note into the skills that have a clear
gather/judge split: `debug`, `pr-classify`, `security-pass`, `migration-plan`,
`testing-checklist`. Each names what to hand to a cheaper-tier subagent (broad
read-only gathering, or mechanical generation) and what to keep on the main-loop
model (the judgment). The recurring rule: **a green check from a subagent is
evidence, not a verdict.**

- **Skills carry the decision, not the mechanism.** No per-tool subagent syntax
  in skill bodies; each runtime already knows how to spawn its own. This keeps the
  Claude canon and its verbatim Gemini mirror correct without naming a
  Claude-specific agent type, and lets the Codex and Copilot ports render natively
  (Copilot degrades to "gather in a focused pass, then judge").
- **Lean on each tool's built-in read-only explorer** (Gemini
  `codebase_investigator`, Codex `explorer`); do **not** ship ready-made agent
  definition files. Those would hardcode churning model IDs and widen the
  installer surface, against the kit's config-light identity.
- **Reaffirm ADR-0006: this is not codegen orchestration.** Delegation is a means
  the persona already endorses; the judgment and the writes stay under the main
  loop's review. The kit does not orchestrate autonomous multi-agent
  implementation.

## Consequences

### Positive
- The persona's delegation principle now fires at the point of use, in the skills
  where it pays: cheaper and faster gathering, judgment preserved.
- Portable: the tool-agnostic phrasing ports across Claude, Gemini, and Codex, and
  Copilot gets the useful degraded form (sequence the work, do not parallelize it).
- Nothing to drift: no per-tool syntax and no shipped agent files with hardcoded
  model IDs.

### Negative
- Five skills each carry one more section; each must stay a single tight note or
  they bloat.
- The gather/judge line is a judgment the model still has to apply; the skill can
  point at it but cannot enforce it.

### Neutral
- No new skills and no catalog-count change; the recommended-skills view is
  unaffected.
- The existing `complexity-audit` and `codebase-map` skills name Claude's
  `Explore` explicitly (they predate this stance). They can be harmonized to the
  tool-agnostic phrasing in a later pass; it is not required here.

## Alternatives Considered

- **Embed per-tool subagent config/syntax in each skill.** Rejected: the runtime
  already knows its own mechanism; embedding syntax bloats the skill, breaks the
  verbatim Gemini mirror, and drifts as the tools change.
- **Ship ready-made cheap read-only explore-agent definitions for Gemini and
  Codex.** Deferred: it hardcodes churning model IDs and adds installer surface,
  against the kit's config-light identity; the built-in explorers already cover
  read-only exploration. Revisit behind its own ADR if ever needed.
- **Leave delegation in the persona canon only.** Rejected: the principle is there
  but the skills never invoke it at their decision points, so in practice it does
  not fire during a run.

## References

- Persona `Model Defaults` and `Delegation` — the tiered principle this
  operationalizes.
- ADR-0006 — process skills, not codegen orchestration (reaffirmed here).
- ADR-0001 — one canon with generated, drift-guarded mirrors.
