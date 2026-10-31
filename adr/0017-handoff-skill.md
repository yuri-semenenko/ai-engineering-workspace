# ADR-0017: A `handoff` skill across all four tools, written outside every repository

- **Status:** Accepted
- **Date:** 2026-10-30
- **Deciders:** Yuri Semenenko

## Context

The persona already tells the assistant to suggest a fresh context at a task
boundary, because auto-compaction is not a substitute for a clean one. The rule
was cheap to follow and expensive to obey: clearing threw away the next step, the
decisions taken in the session and the reasons behind them, and the constraints
the user had set. Git keeps none of those. So the suggestion tended to be skipped
exactly when the session was longest and a clean context would help most.

The boundaries were also drawn too coarsely. "One unrelated task to another"
misses the pivots inside a single ticket: a PR changing state, or a review round
fully worked through with new work next.

Two existing places could have held the missing state and do not fit:

- **Memory** is durable and cross-session by design. A work stream's next step
  is neither: it is wrong a week later, and leaving it in memory turns memory into
  a log.
- **The repository** is where the work is, and a handoff names branches, tickets,
  and decisions that may not belong in a shared tree. In this kit's own symlink
  install, `~/.claude` is a link into a checkout, so even a config directory is
  not safely outside a repository.

## Decision

1. **A `handoff` skill ships to all four tools** at catalog parity: a Claude Code
   skill, a Codex skill with `agents/openai.yaml`, a Gemini command, and a Copilot
   workspace prompt. It has three modes: write at a boundary, resume from a path,
   and close when the stream ends.
2. **One file per work stream, at `~/.handoffs/<repo>/<stream>.md`.** `<repo>` is
   the main checkout's name, so every worktree of one repository shares a folder;
   `<stream>` is the ticket key or a kebab-case topic. The path is outside every
   repository and every assistant's config directory, and it is the same for all
   four tools. The file is overwritten each time: state, not a log.
3. **A handoff is not memory and not permission.** A lesson that outlives the
   stream goes to memory and the handoff links it. Authorizations recorded in a
   handoff are history; the next session asks again. Resume checks the live git
   and PR state before acting, and closing a stream deletes its file.
4. **Copilot returns the handoff instead of writing it.** Its package is
   copy-only and its instructions forbid edits outside the workspace, so the
   prompt hands the user a Markdown block to save. Codex and Gemini write the
   file and ask for approval when their sandbox blocks a write outside the
   workspace, rather than falling back to a path inside it.
5. **The canon names the boundaries; the skill does not restate them.** The
   persona's Session Hygiene rule says when to write one and when not to (not
   mid-step, not with background work running or a question unanswered). The
   skill points at that rule.

## Consequences

### Positive

- Suggesting a fresh context stops costing the session's reasoning, so the
  suggestion can actually be taken.
- One path for all tools means one rule to remember. A handoff written in one
  assistant can be resumed in another, as a side effect rather than a goal.
- Nothing about a work stream lands in a repository or in a config directory a
  symlink may point into a repository.

### Negative

- Handoffs accumulate if streams are never closed. The close step and the
  `ls -lt ~/.handoffs/*/` listing are the only cleanup; nothing prunes them.
- A fifth location under the home directory, next to each tool's own. It is
  outside every tool's install and backup logic, so an uninstall leaves it.
- The Copilot port depends on the user saving the block. If they do not, the
  handoff is lost with the chat.

### Neutral

- The Claude Code port is the canon wording; the other three are hand-authored
  ports under the same name, per [ADR-0015](./0015-codex-skills-carry-canon-names.md).
- The skill is not foregrounded by the persona wizard; like every skill it ships
  to every profile.
- Codex's `context-brief` stays. It is an in-chat brief for the next pass of the
  same session, with no file and no lifecycle; both descriptions now say which is
  which, so the word "handoff" does not trigger the wrong one.

## Alternatives Considered

- **Each tool's own config directory** (`~/.claude/handoffs` and so on).
  Rejected: in a symlink install that directory is inside a checkout, which puts
  work details one `git add` away from a commit.
- **Write handoffs into memory.** Rejected: memory is for what stays true; a next
  step is stale within days, and the stream's file is deleted on close.
- **A gitignored folder in the repository.** Rejected: an ignore rule is a
  backstop, not a boundary, and a worktree or a fresh clone may not carry it.
- **Claude Code only.** Rejected: the boundary rule lives in the shared persona,
  so every tool that reads it needs a way to act on it.

## References

- `persona/persona.template.md` § Session Hygiene, and its condensed form.
- `claude-code/.claude/skills/handoff/SKILL.md`, `codex/skills/handoff/`,
  `gemini/commands/handoff.toml`,
  `copilot/workspace-template/.github/prompts/handoff.prompt.md`.
