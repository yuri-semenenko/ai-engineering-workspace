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

- **The exemption trusted the session's memory, not the file.** Two clones of
  one repository with the same `origin` share a key, and a resume line names a
  file, not a checkout. A session in one clone could resume the other clone's
  handoff, count it as its own because it had resumed it, and overwrite that
  clone's state with its own `Repo`. The exemption saved nothing in the case it
  was meant for: a file the session wrote carries its own `Repo` and its own
  work, so it passes the check anyway.
- **Resume never compared the checkout.** It read the file and checked the
  worktree the file names, so a session running in another clone continued
  without saying so.
- **Close ran no check at all.** It deleted the stream's file with `rm`, and a
  delete cannot be undone. An overwrite at least leaves the new state behind.

## Decision

1. **The ownership check runs on every overwrite, with no exemption.** Whether
   the session resumed or wrote the file is not part of the test: the file's
   `Repo` path and its branch, PR, or ticket are. The rest of the check stands as
   ADR-0019 decided it, including the question about a moved checkout. `Repo`
   holds the main checkout path, so it is compared with this repository's main
   checkout path, which every linked worktree shares, never with the directory
   the session runs in.
2. **Resume flags a foreign `Repo`.** When this repository's main checkout path
   is not the file's `Repo` path, it says so and asks before continuing. A
   session in a linked worktree of the same repository matches.
3. **Close runs the same check before deleting.** When the check fails, nothing
   is deleted and the user is shown the file.
4. **All four ports change together**, as ADR-0017 requires. The Copilot prompt
   never writes or deletes the file, and the overwrite check it hands the user
   already had no exemption, so it gains the resume check and the main-checkout
   comparison.

This supersedes the exemption in ADR-0019 decision 3. The rest of ADR-0019
stands.

## Consequences

### Positive

- A session that resumed another clone's handoff can no longer overwrite it
  without the user's answer.
- Close cannot delete another clone's state.
- The check reads the file every time, so it does not depend on what the session
  remembers about where the file came from.

### Negative

- A checkout that moved now prompts on resume as well as on the next write, so
  the user answers the same question twice for one move.
- `Repo` still sits inside the free-text `Updated` line. A note appended after
  the path, or a comma inside it, makes the comparison harder to read; the check
  is a judgment over path and work, not a string match, so it does not fail on
  that, but it is not exact either.

### Neutral

- A file this session wrote passes the check exactly as before, so the common
  path asks nothing new.

## Alternatives Considered

- **Keep the exemption and add only the Close check.** Rejected: the overwrite of
  a resumed foreign handoff, the first gap, stays open.
- **Give `Repo` a line of its own for an exact comparison.** Deferred: it changes
  the handoff format in four ports and needs a reading rule for every handoff
  written before it, while the check it would serve compares path and work, not
  one string.
- **Compare `Repo` alone.** Rejected for the reason ADR-0019 gives for branch
  alone: a moved checkout fails it, and the question about a move already covers
  that case.

## References

- [ADR-0017](./0017-handoff-skill.md),
  [ADR-0019](./0019-handoff-key-is-repository-identity.md).
- `claude-code/.claude/skills/handoff/SKILL.md`, `codex/skills/handoff/SKILL.md`,
  `gemini/commands/handoff.toml`,
  `copilot/workspace-template/.github/prompts/handoff.prompt.md`.
