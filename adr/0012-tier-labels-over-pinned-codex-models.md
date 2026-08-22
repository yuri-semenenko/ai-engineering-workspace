# ADR-0012: Tier labels over pinned Codex models

- **Status:** Accepted
- **Date:** 2026-08-22
- **Deciders:** Yuri Semenenko

## Context

Codex can delegate work to subagents with per-agent model and sandbox choices.
That makes it tempting to commit a small set of named Codex agents such as
explorer, implementer, reviewer, and architect, each pinned to the current model
family. The workflow idea is sound, but concrete model slugs change faster than
this repository's methodology should. The kit already separates portable canon
from tool adapters, and ADR-0010 chose skill-level gather/judge discipline over
shipping ready-made agent definitions.

## Decision

We will document Codex delegation as tier-aware workflows rather than commit
model-specific subagent configuration files. The stable policy is expressed in
terms of routine, default, and escalation tiers plus repeatable workflows:
`gather -> judge`, `explore -> implement -> review`, and
`explore -> architect -> parent decision -> implement -> review`. Codex users may
choose concrete model overrides at runtime, but the repository will not pin
current model slugs into installed agent configs.

## Consequences

### Positive

- The delegation policy survives model-family churn without repo-wide config
  updates.
- The portable canon remains tool-neutral: it talks about tiers and workflows,
  not Codex-only model names.
- Codex still gets practical routing guidance while keeping the package's
  installer surface small.
- ADR-0010 remains intact: subagents gather or perform bounded mechanical work;
  the parent agent keeps synthesis, judgment, and final responsibility.

### Negative

- The policy is less machine-checkable than committed per-role TOML files.
- Users must map tiers to the currently available Codex models at runtime.

### Neutral

- No Codex installer changes are required.
- Validation continues to cover mirrors, skill structure, Gemini commands, and
  recommended-skill references, but not model routing files because none are
  shipped.

## Alternatives Considered

- **Commit Codex role TOMLs pinned to the current model family.** Rejected:
  model slugs churn every few months, and hardcoded configs would make a stable
  methodology repo track runtime naming instead of engineering policy.
- **Every subagent inherits the parent model.** Rejected: inheritance is a good
  default when no override has a clear reason, but it gives up the cost and
  context benefits of routine-tier gathering and mechanical work.
- **Prompt-only dynamic model selection with no documented workflows.** Rejected:
  it leaves delegation ad hoc. The repo should state when to split work and when
  not to.
- **A generic orchestration framework.** Rejected: this kit ships process
  methodology and tool adapters, not an autonomous implementation framework.

## References

- ADR-0010 — tiered delegation in skills.
- ADR-0011 — declared gather/judge review orchestration.
- [`docs/principles/working-with-agents.md`](../docs/principles/working-with-agents.md)
  — portable model-tier and delegation guidance.
- [`codex/README.md`](../codex/README.md) — Codex-specific delegation notes.
