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

Path: `~/.handoffs/<key>/<stream>.md`. `<key>` is the main checkout's directory name plus a short hash of the repository's identity: its `origin` URL as configured, or the main checkout's absolute path when there is no `origin`. Every worktree of one repository gets the same key, and two repositories that share a name do not. The hash covers exact bytes, so run one of these as written rather than translating it; both print the same key:

```sh
main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
id=$(git config --get remote.origin.url); [ -n "$id" ] || id=$main
printf '%s-%s\n' "$(basename "$main" .git)" "$(printf '%s' "$id" | git hash-object --stdin | cut -c1-8)"
```

```powershell
$enc = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$main = (git worktree list --porcelain)[0] -creplace '^worktree '
$id = git config --get remote.origin.url; if (-not $id) { $id = $main }
[Console]::OutputEncoding = $enc
$f = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($f, $id); $h = git hash-object $f; Remove-Item $f
'{0}-{1}' -f ((Split-Path -Leaf $main) -creplace '(?<=.)\.git$'), $h.Substring(0, 8)
```

The PowerShell form reads git's output as UTF-8 and strips `.git` case-sensitively, as `basename` does; without either, a non-ASCII path or a `.GIT` suffix prints a different key.

The URL goes into the hash, never into the path or the handoff, so a credential in it does not land there. Renaming the checkout's directory, changing `origin`, or moving a checkout that has none changes the key. `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic.

When a write lands at a different path from the handoff this session resumed (one under the older `~/.handoffs/<repo>/` layout, or under a key that has since changed), list the old path under Pointers as `Supersedes <path>`. Nothing moves, renames, or deletes it before Close.

The directory sits outside every repository and every assistant's config directory on purpose. A handoff carries work details, and a config directory can be a symlink into a repository (this kit's own symlink install links `~/.claude` to its checkout). Never write a handoff inside a repository or under a symlinked path.

One file per stream, overwritten each time. It is state, not a log. Before overwriting an existing file, decide whether it is this stream's: it is when this session resumed from it or wrote it, or when its `Repo` path is this checkout's and its branch, PR, or ticket is the work in hand. A matching branch alone is not enough: two clones of one repository share the key and often the branch. If only the `Repo` path differs, ask whether this checkout moved; replace the file only if it did. Anything else (another clone, another branch, or a stream that reused the name and was never closed) is not yours to replace: show the user what it holds and agree a different `<stream>`.

Template. Skip empty sections and stay under about 60 lines:

```markdown
# <stream>: <one-line goal>

Updated <YYYY-MM-DD HH:MM>. Repo <main checkout path>, worktree <path>, branch <name> @ <short sha>, PR <url> (<state>), ticket <url>.

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
- Anything the next step needs from the session scratchpad is copied to `~/.handoffs/<key>/<stream>/`. The scratchpad belongs to one session, and a temp directory does not survive a reboot.

After writing, suggest `/clear` and give one paste-ready line for the next session:

```
/handoff resume ~/.handoffs/<key>/<stream>.md
```

## Resume

1. Read the file.
2. Check the live state before acting: `git -C <worktree> status -sb` and `git -C <worktree> log -1 --oneline`, plus `gh pr view <url> --json state,reviewDecision,headRefOid` when there is a PR. If it drifted from the handoff (new commits, a review landed, the PR merged), say what changed and plan from the live state.
3. State the next step in one line and continue. Ask again for any authorization the handoff mentions.

## Close

When the stream ends (its last PR merged, or the work abandoned), close it instead of writing a handoff: fold anything durable into memory, then delete the stream's file (`<key>/<stream>.md`, or the older path it was resumed from) and every path it lists as `Supersedes` with `rm` and, if it exists, the `<stream>/` folder beside it with `rm -r` (`rm -rf` is on the denylist in `settings.example.json`). Never delete the `<key>/` or `<repo>/` directory itself; other streams live there. To list them: `ls -lt ~/.handoffs/*/`.
