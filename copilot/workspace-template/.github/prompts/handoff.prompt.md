---
description: Handoff prompt — capture one work stream's state so a fresh chat can continue it without re-deriving anything.
---

# Handoff Prompt

Role:
Act as a senior engineer handing a work stream to a fresh session, which may be your own next chat.

Context:
A new chat starts with none of this conversation. The handoff carries what it needs to continue: the next step, the state, the decisions and their reasons. Anything the next session can re-read from git, the PR, or the ticket stays out.

Task:
Write the handoff for the current work stream. If the user instead gives an existing handoff, resume from it: compare it with the live state (branch, latest commit, PR status), say what drifted, and state the next step in one line.

Constraints:
- Do not write files outside this workspace. Return the handoff as one Markdown block for the user to save outside the repository, for example at `~/.handoffs/<key>/<stream>.md`, where `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic. `<key>` is the repository's directory name plus a short hash of its `origin` URL (or of the main checkout's path when there is no `origin`), so two repositories with the same name do not share a folder. Give the user the command that prints it, for their shell, exactly as written: the hash covers exact bytes, and a hand translation prints a different key.
  - POSIX shell: `main=$(git worktree list --porcelain | sed -n '1s/^worktree //p'); id=$(git config --get remote.origin.url); [ -n "$id" ] || id=$main; printf '%s-%s\n' "$(basename "$main" .git)" "$(printf '%s' "$id" | git hash-object --stdin | cut -c1-8)"`
  - PowerShell: `$enc = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); $main = (git worktree list --porcelain)[0] -creplace '^worktree '; $id = git config --get remote.origin.url; if (-not $id) { $id = $main }; [Console]::OutputEncoding = $enc; $f = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($f, $id); $h = git hash-object $f; Remove-Item $f; '{0}-{1}' -f ((Split-Path -Leaf $main) -creplace '(?<=.)\.git$'), $h.Substring(0, 8)`
- Never suggest saving it inside the repository; it carries work details.
- One handoff per stream, replaced each time. It is state, not a log. Stay under about 60 lines and skip empty sections. Tell the user, before they save over an existing file at that path, to check that its repo line names this checkout's path and that its branch, PR, or ticket is this stream's. A matching branch alone is not enough: two clones of one repository share the key and often the branch. If only the repo path differs, replace the file only if this checkout moved; otherwise pick a different `<stream>`.
- A handoff saved before the key existed stays at `~/.handoffs/<repo>/<stream>.md`; resume it by that path. When the new handoff replaces one at a different path, list the old path under Pointers as `Supersedes <path>` so it is deleted when the stream closes.
- Authorizations given in this chat (commit, push, PR) are history, not permission. The next session asks again.
- A lesson that outlives the stream belongs in durable notes, not the handoff.

Output Format:

1. Title line `# <stream>: <one-line goal>`, then one line with `Repo` and the main checkout path, branch and short sha, PR link and state, ticket link
2. Next step: the first concrete action, specific enough to run without asking
3. State: done / in progress / not started, one line each, with evidence
4. Decisions: what was decided, by whom, and why, plus rejected options
5. Constraints: rules the user set that bear on the next step
6. Open: questions and what is being waited on
7. Pointers: paths and links
8. One line the user can paste into the next chat to resume

Success Criteria:
- A fresh session can take the next step without asking anything already answered here.
- Nothing in it is re-derivable from git, the PR, or the ticket.
