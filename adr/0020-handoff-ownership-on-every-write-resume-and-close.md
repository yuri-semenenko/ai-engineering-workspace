# ADR-0020: Handoff ownership is checked on every overwrite, on resume, and before close

- **Status:** Accepted
- **Date:** 2026-11-02
- **Deciders:** Yuri Semenenko

## Context

[ADR-0019](./0019-handoff-key-is-repository-identity.md) decision 3 made the
handoff write check ownership before overwriting. A file counted as this
stream's when the session had resumed from it or written it, or when its `Repo`
path was this checkout's and its branch, PR, or ticket was the work in hand.

That left three gaps:

- **The exemption never read the file.** Two clones of one repository with the
  same `origin` share a key, and a resume line names a file, not a checkout. A
  session in one clone could resume the other clone's handoff, count it as its
  own because it had resumed it, and overwrite that clone's state with its own
  `Repo`.
- **Resume never compared the checkout.** It read the file and checked the
  worktree the file names, so a session running in another clone continued
  without saying so.
- **Close ran no check at all.** It deleted the stream's file with `rm`, and a
  delete cannot be undone. An overwrite at least leaves the new state behind.

The exemption itself is needed. A stream can span several PRs, and one named for
a topic has no ticket to match. Once it moves on to its next branch or PR, the
file still names the last one, and only the exemption lets the session that
resumed it write it again.

## Decision

1. **The ownership check runs on every overwrite, and the exemption needs a
   matching `Repo`.** A file is this stream's when its `Repo` path is this
   repository's main checkout path and either this session resumed from it or
   wrote it, or its branch, PR, or ticket is the work in hand. Having resumed or
   written the file no longer counts on its own, because another clone's file
   always holds another `Repo`. The rest of the check stands as ADR-0019 decided
   it, including the question about a moved checkout. `Repo` holds the main
   checkout path, so it is compared with this repository's main checkout path,
   which every linked worktree shares, never with the directory the session runs
   in.
2. **Resume flags a foreign `Repo`.** When this repository's main checkout path
   is not the file's `Repo` path, it says so and asks before continuing. A
   session in a linked worktree of the same repository matches.
3. **Close runs the same check before deleting.** When the check fails, nothing
   is deleted and the user is shown the file.
4. **All four ports change together**, as ADR-0017 requires. The Copilot prompt
   never writes or deletes the file. The overwrite check it hands the user asks
   whether the file's branch, PR, or ticket is this stream's, which the user can
   answer for an earlier PR of the stream, so it gains only the resume check and
   the main-checkout comparison.

This supersedes the unconditional exemption in ADR-0019 decision 3. The rest of
ADR-0019 stands.

## Consequences

### Positive

- A session that resumed another clone's handoff can no longer overwrite it
  without the user's answer.
- Close cannot delete another clone's state.
- The check reads the file's `Repo` every time, so what the session remembers
  about where the file came from counts only for a file of this repository.

### Negative

- A checkout that moved now prompts on resume as well as on the next write, so
  the user answers the same question twice for one move.
- `Repo` still sits inside the free-text `Updated` line. A note appended after
  the path, or a comma inside it, makes the comparison harder to read; the check
  is a judgment over path and work, not a string match, so it does not fail on
  that, but it is not exact either.

### Neutral

- A file of this repository that the session resumed from or wrote passes the
  check as before, including after the stream moved on to its next branch or PR,
  so the common path asks nothing new.

## Alternatives Considered

- **Keep the exemption as it was and add only the Close check.** Rejected: the
  overwrite of a resumed foreign handoff, the first gap, stays open.
- **Drop the exemption.** Rejected: a stream that moved on to its next branch or
  PR, with no ticket to match, would fail the check on its own file and be told
  to pick a new name, while the `Repo` match alone already tells another clone's
  file apart.
- **Give `Repo` a line of its own for an exact comparison.** Deferred: it changes
  the handoff format in four ports and needs a reading rule for every handoff
  written before it, while the check it would serve compares path and work, not
  one string.
- **Compare `Repo` alone.** Rejected: one checkout can still hold a stream that
  reused the name and was never closed. Only the work, or this session having
  resumed or written the file, tells that file apart from this stream's.

## References

- [ADR-0017](./0017-handoff-skill.md),
  [ADR-0019](./0019-handoff-key-is-repository-identity.md).
- `claude-code/.claude/skills/handoff/SKILL.md`, `codex/skills/handoff/SKILL.md`,
  `gemini/commands/handoff.toml`,
  `copilot/workspace-template/.github/prompts/handoff.prompt.md`.
