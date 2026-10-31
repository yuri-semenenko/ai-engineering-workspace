---
name: handoff
description: Use at a task boundary before starting a fresh session, or when the user says handoff, write a handoff, save state before a new session, сделай handoff, сохрани контекст, resume from handoff <path>, or продолжи по handoff. Writes or resumes one work stream's state file; not memory, and deleted when the stream closes. Different from context-brief, an in-chat brief for the next pass of the same session.
---

# Handoff

A fresh session is cheap only if nothing that matters dies with the old context. A handoff carries what the next session needs to continue without re-deriving it: the next step, the state, the decisions and their reasons. Leave out whatever the next session can re-read from git, the PR, the ticket, or durable notes.

## When

At a task boundary: write the handoff, then suggest a fresh session with the resume line. Which moments are boundaries, and when not to offer one, is the Session Hygiene rule in `$CODEX_HOME/references/persona.md`. When the boundary is the stream's last PR merging, close the stream instead of writing.

## Write

- Path: `~/.handoffs/<repo>/<stream>.md`. `<repo>` is the main checkout's directory name, the same from every worktree: `basename "$(git worktree list --porcelain | sed -n '1s/^worktree //p')" .git`. `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic.
- The directory sits outside every repository and every assistant's config directory, because a handoff carries work details. Never write one inside a repository. If the sandbox blocks the write, ask for approval rather than falling back to a path in the workspace.
- One file per stream, overwritten each time. It is state, not a log. Skip empty sections and stay under about 60 lines.

Sections, in order:

1. Title: `# <stream>: <one-line goal>`, then one line with the update time, repo path, worktree path, branch and short sha, PR link and state, ticket link.
2. `## Next step`: the first concrete action, specific enough to run without asking.
3. `## State`: done, in progress, not started, one line each, with its evidence (commit, test run, PR link).
4. `## Decisions`: what was decided, by whom, and why, plus rejected options with the reason. This is the part git does not keep.
5. `## Constraints`: rules the user set this session that bear on the next step. Authorizations given here (commit, push, PR, apply) are history, not permission: the next session asks again.
6. `## Open`: questions for the user, and what is being waited on.
7. `## Pointers`: absolute paths and links.

A lesson that outlives the stream belongs in the user's durable notes, not in the handoff. Copy anything the next step needs from a temporary directory into `~/.handoffs/<repo>/<stream>/`.

After writing, give one paste-ready line for the next session: `$handoff resume ~/.handoffs/<repo>/<stream>.md`.

## Resume

1. Read the file.
2. Check the live state before acting: `git -C <worktree> status -sb`, `git -C <worktree> log -1 --oneline`, and `gh pr view <url> --json state,reviewDecision,headRefOid` when there is a PR. If it drifted from the handoff, say what changed and plan from the live state.
3. State the next step in one line and continue. Ask again for any authorization the handoff mentions.

## Close

When the stream ends (its last PR merged, or the work abandoned), fold anything durable into the user's notes, then delete `<repo>/<stream>.md` and, if it exists, the `<repo>/<stream>/` folder. Never delete `<repo>/` itself; other streams live there.
