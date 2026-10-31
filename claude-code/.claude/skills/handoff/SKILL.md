---
name: handoff
description: |
  Write a handoff file that carries one work stream across `/clear`, or resume
  from one. Use at a task boundary before suggesting `/clear`, or when the user
  says "handoff", "write a handoff", "save state before clear", "сделай handoff",
  "сохрани контекст перед clear", "resume from handoff <path>",
  "продолжи по handoff". Not memory: a handoff belongs to one work stream and is
  deleted when that stream closes.
---

# handoff

`/clear` is cheap only if nothing that matters dies with the context. A handoff carries what a fresh session needs to continue without re-deriving it: the next step, the state, the decisions and their reasons. It leaves out whatever the next session can re-read from git, the PR, the ticket, or memory.

## When

At a task boundary: write first, then suggest `/clear` with the resume line. Which moments are boundaries, and when not to offer one, is the Session Hygiene rule in the persona; it is not restated here. When the boundary is the stream's last PR merging, Close instead of writing.

## Write

Path: `~/.handoffs/<repo>/<stream>.md`. `<repo>` is the main checkout's directory name, the same from every worktree: `basename "$(git worktree list --porcelain | sed -n '1s/^worktree //p')" .git`. `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic.

The directory sits outside every repository and every assistant's config directory on purpose. A handoff carries work details, and a config directory can be a symlink into a repository (this kit's own symlink install links `~/.claude` to its checkout). Never write a handoff inside a repository or under a symlinked path.

One file per stream, overwritten each time. It is state, not a log.

Template. Skip empty sections and stay under about 60 lines:

```markdown
# <stream>: <one-line goal>

Updated <YYYY-MM-DD HH:MM>. Repo <path>, worktree <path>, branch <name> @ <short sha>, PR <url> (<state>), ticket <url>.

## Next step
The first concrete action, specific enough to run without asking.

## State
Done / in progress / not started, one line each, with its evidence (commit, test run, PR link).

## Decisions
What was decided, by whom, and why. Rejected options with the reason. This is the part git does not keep.

## Constraints
Rules the user set this session that bear on the next step. Authorizations given here (commit, push, PR, apply) are history, not permission: the next session asks again.

## Open
Questions for the user; what is being waited on (reviewer, CI, another PR).

## Pointers
Absolute paths and links.
```

Before writing:

- A lesson that outlives this stream (a gotcha, a user preference) goes into memory now, under the memory rules, and the handoff links it with `[[name]]` instead of repeating it.
- Anything the next step needs from the session scratchpad is copied to `~/.handoffs/<repo>/<stream>/`. The scratchpad belongs to one session, and a temp directory does not survive a reboot.

After writing, suggest `/clear` and give one paste-ready line for the next session:

```
/handoff resume ~/.handoffs/<repo>/<stream>.md
```

## Resume

1. Read the file.
2. Check the live state before acting: `git -C <worktree> status -sb` and `git -C <worktree> log -1 --oneline`, plus `gh pr view <url> --json state,reviewDecision,headRefOid` when there is a PR. If it drifted from the handoff (new commits, a review landed, the PR merged), say what changed and plan from the live state.
3. State the next step in one line and continue. Ask again for any authorization the handoff mentions.

## Close

When the stream ends (its last PR merged, or the work abandoned), close it instead of writing a handoff: fold anything durable into memory, then delete `<repo>/<stream>.md` with `rm` and, if it exists, the `<repo>/<stream>/` folder with `rm -r` (`rm -rf` is on the denylist in `settings.example.json`). Never delete `<repo>/` itself; other streams live there. To list them: `ls -lt ~/.handoffs/*/`.
