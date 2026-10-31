---
name: handoff
description: Use at a task boundary before starting a fresh session, or when the user says handoff, write a handoff, save state before a new session, сделай handoff, сохрани контекст, resume from handoff <path>, or продолжи по handoff. Writes or resumes one work stream's state file; not memory, and deleted when the stream closes. Different from context-brief, an in-chat brief for the next pass of the same session.
---

# Handoff

A fresh session is cheap only if nothing that matters dies with the old context. A handoff carries what the next session needs to continue without re-deriving it: the next step, the state, the decisions and their reasons. Leave out whatever the next session can re-read from git, the PR, the ticket, or durable notes.

## When

At a task boundary: write the handoff, then suggest a fresh session with the resume line. Which moments are boundaries, and when not to offer one, is the Session Hygiene rule in `$CODEX_HOME/references/persona.md`. When the boundary is the stream's last PR merging, close the stream instead of writing.

## Write

- Path: `~/.handoffs/<key>/<stream>.md`. `<key>` is the main checkout's directory name plus a short hash of the repository's identity: its `origin` URL as configured, or the main checkout's absolute path when there is no `origin`. Every worktree of one repository gets the same key, and two repositories that share a name do not. The hash covers exact bytes, so run one of these as written rather than translating it; both print the same key:

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

  The PowerShell form reads git's output as UTF-8 and strips `.git` case-sensitively, as `basename` does; without either, a non-ASCII path or a `.GIT` suffix prints a different key. The URL goes into the hash, never into the path or the handoff, so a credential in it does not land there. Renaming the checkout's directory, changing `origin`, or moving a checkout that has none changes the key. `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic.
- When a write lands at a different path from the handoff this session resumed (one under the older `~/.handoffs/<repo>/` layout, or under a key that has since changed), list the old path under Pointers as `Supersedes <path>`. Nothing moves, renames, or deletes it before Close.
- The directory sits outside every repository and every assistant's config directory, because a handoff carries work details. Never write one inside a repository. If the sandbox blocks the write, ask for approval rather than falling back to a path in the workspace.
- One file per stream, overwritten each time. It is state, not a log. Skip empty sections and stay under about 60 lines.
- Before overwriting an existing file, decide whether it is this stream's: it is when this session resumed from it or wrote it, or when its repo path is this checkout's and its branch, PR, or ticket is the work in hand. A matching branch alone is not enough: two clones of one repository share the key and often the branch. If only the repo path differs, ask whether this checkout moved; replace the file only if it did. Anything else (another clone, another branch, or a stream that reused the name and was never closed) is not yours to replace: show the user what it holds and agree a different `<stream>`.

Sections, in order:

1. Title: `# <stream>: <one-line goal>`, then one line with the update time, `Repo` and the main checkout path, worktree path, branch and short sha, PR link and state, ticket link.
2. `## Next step`: the first concrete action, specific enough to run without asking.
3. `## State`: done, in progress, not started, one line each, with its evidence (commit, test run, PR link).
4. `## Decisions`: what was decided, by whom, and why, plus rejected options with the reason. This is the part git does not keep.
5. `## Constraints`: rules the user set this session that bear on the next step. Authorizations given here (commit, push, PR, apply) are history, not permission: the next session asks again.
6. `## Open`: questions for the user, and what is being waited on.
7. `## Pointers`: absolute paths and links.

A lesson that outlives the stream belongs in the user's durable notes, not in the handoff. Copy anything the next step needs from a temporary directory into `~/.handoffs/<key>/<stream>/`.

After writing, give one paste-ready line for the next session: `$handoff resume ~/.handoffs/<key>/<stream>.md`.

## Resume

1. Read the file.
2. Check the live state before acting: `git -C <worktree> status -sb`, `git -C <worktree> log -1 --oneline`, and `gh pr view <url> --json state,reviewDecision,headRefOid` when there is a PR. If it drifted from the handoff, say what changed and plan from the live state.
3. State the next step in one line and continue. Ask again for any authorization the handoff mentions.

## Close

When the stream ends (its last PR merged, or the work abandoned), fold anything durable into the user's notes, then delete the stream's file (`<key>/<stream>.md`, or the older path it was resumed from) and every path it lists as `Supersedes`, and, if it exists, the `<stream>/` folder beside it. Never delete the `<key>/` or `<repo>/` directory itself; other streams live there.
