# ADR-0016: Subagents default to the routine tier, and a hook guards scripted fan-outs

- **Status:** Accepted
- **Date:** 2026-10-30
- **Deciders:** Yuri Semenenko

## Context

[ADR-0012](./0012-tier-labels-over-pinned-model-slugs.md) makes the delegation
policy a set of tier labels, and [ADR-0010](./0010-tiered-delegation-in-skills.md)
puts the gather/judge split into the skills. Both describe what a dispatch
should ask for. Neither covers what happens when a dispatch asks for nothing.

Claude Code resolves a subagent's model in this order: the per-call `model`
parameter, then the agent definition's `model` frontmatter, then the
`CLAUDE_CODE_SUBAGENT_MODEL` environment variable, then the main conversation's
model. With the variable unset, an omitted `model` silently takes the session's
model. On a session running the default tier, forgetting the field buys the
expensive outcome, and nothing shows it.

The `Workflow` tool makes that omission likely rather than occasional. A script
fans out many `agent()` calls at once; the tool's own example calls carry
`label`, `phase`, and `schema` but no `model`; and the permission dialog shows
only the script's `meta.description`, so the resolved tiers never reach the
approval gate. In practice, fan-outs written that way left a third or more of
their calls without a tier while the written rule was in force. A restated rule
had already been tried and had not held.

Permission rules match a tool and its arguments, never the contents of a script
argument, so this cannot be expressed in `permissions` alone.

## Decision

Invert the default and guard the omission. They fix different halves.

1. **`CLAUDE_CODE_SUBAGENT_MODEL` is `sonnet`** in the `env` block of
   `claude-code/.claude/settings.example.json`. An omitted `model` now costs the
   routine tier instead of the default one. It is an alias, so it stays inside
   ADR-0012. Per-call `model` and agent frontmatter both outrank it, so an
   explicit default-tier stage still works and `independent-review` keeps the
   `opus` tier [ADR-0013](./0013-claude-review-agent.md) gave it.
   `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is not set: it overrides per-call and
   frontmatter tiers, which would remove the sanctioned way to ask for the
   default tier.
2. **`hooks/workflow-model-guard.sh`** runs as a `PreToolUse` hook on
   `Workflow`. It counts `agent(` against `model:` in the script and returns an
   `ask` decision naming the shortfall when calls outnumber fields. It reads
   `scriptPath` before the inline `script`, because that field takes precedence
   and editing the persisted script is how a workflow is iterated, so a hook
   reading only `script` would be bypassed from the second run on. It is
   dependency-free: it scans the raw event as text and does not need `jq`.
3. **The canon names the rule in tool-neutral terms.** The persona's Delegation
   section says scripted fan-outs follow the same tiers, labelled per call by
   what the call does. The Claude-specific mechanism (the variable, the
   resolution order, the hook) lives in `claude-code/README.md` and here,
   because the condensed persona is also the Gemini mirror.

## Consequences

### Positive

- The cheap outcome is the default one. An omitted field is a small quality
  risk instead of a large bill, and the quality-critical spots are the ones that
  already name their tier.
- The guard lands before the spend, which a written rule cannot do, and it
  reaches the script of an unattended run as well as an attended one.

### Negative

- The failure changes sign rather than disappearing. A forgotten field now
  under-tiers judgment work, and a wrong tier shows up later as a missed defect
  rather than the same day as a cost. The exposure is narrow, because the
  shipped agent files name their tier and the review skills route judgment to
  the main loop, but it is not zero for ad-hoc delegation.
- `ask` is a prompt, not a block. It stops an attended run and enforces nothing
  against a run that auto-approves.
- Counting `agent(` against `model:` is a heuristic on JavaScript source. A
  nested call or a string literal can inflate either side. The hook's message
  says to report a false positive rather than edit the script to satisfy it.
- An `env` value applies at process start, so it does not affect a session that
  is already running.
- The resolution order above holds from Claude Code v2.1.251. Before that the
  variable outranked per-call and frontmatter tiers, so on an older build it
  would also pull `independent-review` down to `sonnet`.

### Neutral

- Per the Claude Code docs, the variable alone does not change the model of the
  built-in `Explore` and `Plan` subagents. Their tier still comes from the
  dispatch.
- `docs/hardening.md` gains a seventh hook.

## Alternatives Considered

- **Deny instead of ask.** Rejected: the count is a heuristic, and a false
  positive should cost one keypress rather than deadlock a script against a
  check it cannot satisfy. The kit's other content hooks ask for the same
  reason.
- **The hook alone, default left inherited.** Rejected: it only holds where the
  hook fires. The variable covers every spawn, including the ad-hoc ones no hook
  watches.
- **The variable alone.** Rejected: it makes the mistake cheap without making it
  visible, and the tier would still not be named per call as the canon asks.
- **`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` as a hard floor.** Rejected: it silences
  the explicit default-tier stage and the reviewer's tier from ADR-0013.
- **Another restatement of the rule.** Rejected on its record. Only the rule's
  absence from the canon was worth fixing with words, and that is what point 3
  does.

## References

- [ADR-0010](./0010-tiered-delegation-in-skills.md), [ADR-0012](./0012-tier-labels-over-pinned-model-slugs.md),
  [ADR-0013](./0013-claude-review-agent.md).
- `claude-code/.claude/settings.example.json`;
  `claude-code/.claude/hooks/workflow-model-guard.sh`;
  `persona/persona.template.md` § Delegation.
- Claude Code subagent docs, "Choose a model":
  <https://code.claude.com/docs/en/sub-agents>.
