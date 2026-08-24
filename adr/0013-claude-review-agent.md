# ADR-0013: One shipped review agent for Claude Code

- **Status:** Accepted
- **Date:** 2026-08-22
- **Deciders:** Yuri Semenenko

## Context

ADR-0010 declined to ship ready-made agent definitions for two reasons: they
would hardcode churning model IDs, and they would widen the installer surface.
ADR-0012 split the first reason in half. A version slug churns; a tier alias does
not, and Claude Code's agent frontmatter takes the alias. So for Claude the model
argument is no longer an obstacle, and the second reason is the only one left.

That second reason is a real filter, because the platform already ships agents.
`Explore` is a read-only gatherer, routine-tier when the dispatch says so.
`Plan` covers multi-step
planning. `general-purpose` covers bounded mechanical work. Anything this kit
ships has to be something those do not already do, or it is custom code standing
where the platform already provides.

The canon's `explore -> implement -> review` names a review step, and that is the
gap. Claude Code has no built-in reviewer, and the kit's own review skills
(`pr-classify`, `pr-recheck`) run on the main loop. For a PR written by someone
else that is correct. For code the assistant just wrote it is not: the context
that produced the change is the worst context to judge it from, which is the
whole reason the workflow has a separate review step.

There is also a mechanical detail. The Claude installer symlinks the entire
`.claude` tree, so any file under `agents/` is installed. A file there is never
inert documentation, which shapes what form a shipped agent should take.

## Decision

Ship exactly one agent for Claude Code, and enforce the alias rule in CI.

1. **`claude-code/.claude/agents/independent-review.md`** is a working agent, not
   a template. Its `model` is the default-tier alias, it carries no Edit or Write
   tool, and it needs no per-project values. It reads the intent first, then the
   implementation against that intent, and returns candidate findings with
   `file:line` in the kit's Critical / Important / Optional buckets, plus an
   explicit list of what it could not check. It keeps Bash, because `git diff`
   and `gh pr view` are most of what makes a review possible, so its read-only
   posture is a contract in the prompt plus the shipped denylist rather than a
   capability boundary. Nothing ships on the escalation alias: the canon treats
   escalation as a manual session-level switch, not an agent-file setting.
2. **No gather agent.** Built-in `Explore` is the read-only gatherer, on the
   routine tier when the dispatch asks for it. Shipping our own would put custom
   code where the platform already provides, against the simplicity ladder.
3. **CI asserts the rule.** Every `model:` field in a committed file must name a
   tier alias. This is what makes ADR-0012 checkable rather than aspirational,
   for the one tool that can express it.
4. **The verdict does not move.** The agent proposes severities; classification,
   the confidence call, and the ruling stay on the main loop. ADR-0010 and
   ADR-0011 are unchanged in substance.

ADR-0010's deferral now reads as scoped to the tools whose config names a
concrete model, which is Codex and Gemini.

## Consequences

### Positive

- `explore -> implement -> review` has a real third step on Claude instead of a
  main-loop reread of its own work.
- The tier policy is config plus a CI check, not only prose, so it cannot drift
  silently.
- One shipped agent rather than a set: the installer surface grows by a single
  file, and every future candidate has to clear the same bar of not duplicating a
  built-in.

### Negative

- The installer now places a reviewer in every install, whether or not that user
  wants review delegated. Deleting the file is the opt-out, which is a blunt one.
- The agent's prompt is another artifact to maintain, and it overlaps in content
  with `pr-classify`'s classification rules. If the buckets are ever redefined,
  both change.
- An independent read removes the writer's context but not the reader's blind
  spots. A subagent can be confidently wrong, so the main loop still pays a
  triage pass over what comes back.
- The reviewer is not read-only by capability. The shipped allowlist passes some
  state-changing commands through Bash (`git add`, `git commit -m`, `git switch`,
  `npm install`), so a misbehaving run could touch the tree. Removing Bash would
  make the boundary real at the cost of the diff, which is the input the review
  exists to read.

### Neutral

- No skill changes. The review skills keep their own flow and gates.
- Codex and Gemini are unaffected: their config names a concrete model, so
  ADR-0012 still rules out shipping agent files for them.
- No canon change. This is an adapter-level decision about one tool's mechanism.

## Alternatives Considered

- **Ship a gather agent as well.** Rejected: built-in `Explore` already is the
  read-only routine-tier gatherer, so a shipped copy would be duplication rather
  than leverage.
- **Ship nothing and document the mechanisms only.** Rejected: it leaves
  ADR-0012's machine-checkability gap open for the single tool whose config could
  close it, and keeps `gather -> judge` dependent on the model remembering a
  prose rule.
- **Ship it as `independent-review.template.md`.** Rejected: the installer
  symlinks the whole tree, so a template under `agents/` is installed anyway. A
  reviewer needs no project-specific values, so a placeholder would be strictly
  worse than a working agent.
- **Make the reviewer a skill instead of an agent.** Rejected: a skill runs in
  the calling context, and independence from that context is the entire value
  here.
- **Drop Bash so the read-only property is capability-enforced.** Rejected for
  now: without it the agent cannot read the diff, and passing the diff in the
  dispatch spends the main-loop context that delegating was meant to save. The
  trade is recorded rather than hidden, and the option is documented in
  `claude-code/README.md` for anyone who wants the harder boundary.
- **Ship the reviewer on the routine alias, matching the project agent.**
  Rejected: the canon puts code review on the default tier, and a reviewer that
  misses defects costs more than it saves. The project agent works inside
  conventions its own file spells out; the reviewer does not.

## References

- ADR-0010 — tiered delegation in skills; its deferral is narrowed here.
- ADR-0011 — declared gather/judge review orchestration; the verdict boundary
  it draws is preserved.
- ADR-0012 — tier labels over pinned model slugs; this is the first place the
  alias half is used in config.
- [`claude-code/README.md`](../claude-code/README.md) — the Claude delegation
  mapping.
