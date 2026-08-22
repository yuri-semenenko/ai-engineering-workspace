# ADR-0012: Tier labels over pinned model slugs

- **Status:** Accepted
- **Date:** 2026-08-22
- **Deciders:** Yuri Semenenko

## Context

The persona canon already picks models by tier — routine, default, escalation —
rather than by version number, and ADR-0010 made subagent delegation fire inside
the skills. What was missing is the shape of the delegation itself: which
sequences of agents are worth running, and where the parent keeps the decision.

Codex is where the gap shows. It can delegate to subagents with per-agent model
and sandbox choices, which makes it tempting to commit a small set of named
agents such as explorer, implementer, reviewer, and architect, each pinned to the
current model family. The workflow idea is sound, but concrete model slugs change
faster than this repository's methodology should.

The tools also differ in what their own config can express:

- Claude Code takes a **tier alias** in agent frontmatter and in the delegation
  call (`sonnet`, `opus`, `haiku`, or the field omitted to inherit) — the same
  vocabulary the canon already uses.
- Codex and Gemini name a **concrete model** in config, and those names churn.
- Copilot has no subagent mechanism; its only tier lever is the model picker on
  the request.

So "do not hardcode the model" is not one rule. It is one rule about version
slugs and a different question about tier labels.

## Decision

Express delegation policy as tier labels plus named workflows in the portable
canon, and let each tool adapter supply the mechanism.

**1. The canon gains the workflows.** `gather -> judge`,
`explore -> implement -> review`, and
`explore -> architect -> decide -> implement -> review` land in
`docs/principles/working-with-agents.md` and in both persona templates, so the
Gemini mirror picks them up by regeneration. The step names are roles, not skill
names; each tool maps them onto its own inventory. The `decide` step always
belongs to the parent.

**2. Tier aliases may be committed; version slugs may not.** Where a tool's
config accepts the tier vocabulary itself, using it is not hardcoding.
`claude-code/.claude/agents/project-agent.template.md` sets `model: sonnet`,
which is a tier rather than a version, and it stays. What this ADR rules out is
pinning a version slug into anything an installer puts on a machine.

**3. Codex routes by tier at runtime.** Because Codex config can only name a
concrete model, its adapter documents the tier mapping in `codex/README.md` and
`codex/PROMPT_FOR_CODEX.md` instead of shipping agent TOMLs. Codex users choose
overrides per run; the repository ships none.

ADR-0010 holds: subagents gather or do bounded mechanical work, and the parent
keeps synthesis, judgment, and final responsibility.

## Consequences

### Positive

- The delegation policy survives model-family churn without repo-wide config
  updates.
- The portable canon stays tool-neutral: it talks about tiers, roles, and
  workflows, not one tool's model names.
- Codex gets practical routing guidance while its installer surface stays small.
- The alias/slug line is explicit, so a later adapter can commit tier-keyed agent
  definitions for a tool whose config speaks tiers, without contradicting this
  record.

### Negative

- For Codex the policy is prose, not checkable config, so nothing enforces it at
  install time.
- Codex users must map tiers to the models currently available to them.
- The workflow list now appears in the canon and in two Codex-owned files, and
  only the persona and Gemini copies are drift-guarded. Keeping the labels
  identical is manual until a guard covers the block.

### Neutral

- No installer changes for any tool.
- Gemini receives the workflows through the existing `GEMINI.md` mirror; no
  Gemini-specific work was needed.
- Copilot is unchanged. With no subagent mechanism, its prompts keep the degraded
  sequential gather-then-judge form from ADR-0010; the tier vocabulary still
  applies to its model picker.
- Validation continues to cover mirrors, skill structure, Gemini commands, and
  recommended-skill references, but not model routing, because no routing file is
  shipped.

## Alternatives Considered

- **Commit Codex role TOMLs pinned to the current model family.** Rejected:
  model slugs churn every few months, and hardcoded configs would make a stable
  methodology repo track runtime naming instead of engineering policy.
- **Ban model fields from every committed config, tier aliases included.**
  Rejected: it would delete the working `model: sonnet` in the Claude agent
  template and forbid the one case where a tool speaks the canon's own
  vocabulary.
- **Every subagent inherits the parent model.** Rejected as a blanket rule.
  Inheritance is the right default when no override has a stated reason, but as a
  policy it gives up the cost and context benefits of routine-tier gathering and
  mechanical work.
- **Prompt-only dynamic model selection with no documented workflows.** Rejected:
  it leaves delegation ad hoc. The repo should state when to split work and when
  not to.
- **A generic orchestration framework.** Rejected: this kit ships process
  methodology and tool adapters, not an autonomous implementation framework.

## References

- ADR-0010 — tiered delegation in skills.
- ADR-0011 — declared gather/judge review orchestration.
- [`docs/principles/working-with-agents.md`](../docs/principles/working-with-agents.md)
  — portable model-tier, workflow, and delegation guidance.
- [`codex/README.md`](../codex/README.md) — Codex-specific delegation notes.
