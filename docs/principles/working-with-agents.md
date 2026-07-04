# Working with agents

The rest of the methodology is about engineering. This part is about the specific
skill of driving an AI assistant like a senior engineer would drive a capable but
over-eager junior: give it judgment, keep it on a leash, and don't pay senior
rates for junior work.

## Collaborate, don't dictate

The canon's first instruction to an assistant is to *not* start typing:

- Verify understanding before proposing a solution.
- Identify missing information and surface assumptions.
- Challenge unclear or questionable requirements.
- When proposing, explain the reasoning, discuss alternatives, name the
  trade-offs and risks.
- **Do not blindly agree.** Constructive disagreement, when justified, is the
  point of a senior collaborator. An assistant that only confirms your instinct
  is a faster way to be wrong.

## Touch only what you're asked to touch

The single biggest factor in whether an agent's change is mergeable:

> No drive-by refactors. No modernizing adjacent code. No rewriting files you
> brushed against. No deleting code you don't fully understand (Chesterton's
> Fence).

If there is unrelated work worth doing, name it separately — don't fold it into
the diff. A focused change gets reviewed and merged; a change that also
"cleaned up" four neighboring files gets unwound. This is a discipline agents
violate constantly by default, which is exactly why it's stated as a hard rule.

## Match the model to the task

Pick the model tier by task profile, not by version number, so the guidance
survives model releases:

- **Default tier** — architecture, code review, security review, complex
  debugging, RFC drafting. Cross-file judgment. Stays selected most of the time.
- **Routine tier** — mechanical edits, test writing, small refactors, doc
  updates, broad exploration and planning. Faster and cheaper, small quality gap
  on well-scoped work.
- **Escalation tier** — the top tier, as burst capacity for unusually hard
  problems or when the default tier is visibly wrong on something in its range.
  Not a daily driver.

### Delegation is the lever

The main-loop model can't downgrade itself. The way to actually use the cheaper
tiers is to **delegate routine work to subagents with a model override** instead
of grinding it on the main loop:

- **Auto-delegate** well-scoped mechanical work — bulk edits, test scaffolding,
  doc updates, codemod-style refactors, broad searches — to a routine-tier
  subagent. This also keeps large intermediate output out of the main context.
- **Ask first** when the split is ambiguous: the task mixes judgment with
  mechanics, touches architecture or security, or is hard to scope.
- **Keep on the main loop** anything needing cross-file judgment: architecture,
  review, RFC/ADR, hard debugging.

## Session hygiene

Context is a budget. Spend it on the current problem:

- **Clear on task boundaries.** When the work pivots to an unrelated task, start
  a fresh context rather than dragging the old one along. Auto-compaction is not
  a substitute for a clean slate.
- **Prefer subagents for exploration** over inline search loops. A read-only
  exploration agent keeps a broad search's intermediate results out of the main
  thread; you keep the conclusion, not the file dumps.
- **Use worktrees for parallel work streams** instead of juggling stashes.
- **Don't re-read what was just read** or re-run a status command from a moment
  ago. The harness already tracks that state.

## Safe autonomy

Judgment is only half of letting an agent work unattended. The other half is
making sure a mistake can't be irreversible. The kit ships a permission model and
a set of write- and command-time hooks so an assistant can act without a human
watching every call: an allowlist for safe-to-repeat actions, a denylist for the
irreversible and the outbound (`rm -rf`, force-push, history rewrites, publish,
merge), a secret-pattern scanner on writes, and a protected-file guard. The full
model and its rationale live in [`docs/hardening.md`](../hardening.md).

This is the practical answer to the question that gates real autonomy: *how do I
let an agent loose without it doing something I can't undo?*

## Accuracy over confidence

The last rule is the one that makes the rest trustworthy: when making a claim of
certainty — about security, about a library's behavior, about whether a tool
exists — verify it against code or docs first, and flag uncertainty explicitly
rather than overstating. An assistant confidently wrong is worse than one that
says "I'm not sure, let me check." The canon requires the second.
