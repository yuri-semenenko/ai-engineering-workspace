# ADR-0019: Handoff folders are keyed by repository identity, not by directory name

- **Status:** Accepted
- **Date:** 2026-10-31
- **Deciders:** Yuri Semenenko

## Context

[ADR-0017](./0017-handoff-skill.md) decision 2 put each handoff at
`~/.handoffs/<repo>/<stream>.md`, with `<repo>` the main checkout's directory
name so that every worktree of one repository shares a folder. A directory name
does not identify a repository. Two forks with the same name, or two unrelated
local projects both called `api`, resolve to the same folder. When their streams
also share a name (a topic like `fix-tests`, or a ticket key reused across
trackers), the write mode overwrites one stream's state with the other's, and
nothing checked whose file it was before replacing it.

## Decision

1. **`<key>` replaces `<repo>`.** It is the main checkout's directory name, a
   hyphen, and the first eight hex characters of `git hash-object` over the
   repository's identity: the `origin` URL as configured
   (`git config --get remote.origin.url`, so a machine's `insteadOf` rewrites do
   not change it), or the main checkout's absolute path when there is no
   `origin`. Every worktree of a repository shares its config and its main
   checkout, so they all get the same key; two repositories with different
   remotes or locations do not. The URL goes into the hash, never into the path
   or the handoff.
2. **Each port ships the key command for a POSIX shell and for PowerShell, to be
   run as written.** The hash covers exact bytes, and a hand translation does
   not: piping the URL to `git hash-object` in PowerShell adds a line ending and
   prints a different key. The PowerShell form also reads git's output as UTF-8,
   because PowerShell otherwise decodes it with the console code page and hashes
   different bytes for a non-ASCII path, and it strips `.git` case-sensitively,
   as `basename` does. Both forms fall back to the path when `origin` is unset or
   empty. They were checked to print the same key in bash, PowerShell 7, and
   Windows PowerShell 5.1, including for a Cyrillic path, a Cyrillic `origin`,
   an empty `origin`, and a `.GIT` suffix.
3. **Write checks ownership before overwriting.** A file is this stream's when
   the session resumed from it or wrote it, or when its `Repo` path is this
   checkout's and its branch, PR, or ticket is the work in hand. A matching
   branch alone is not enough, because two clones of one repository share the
   key and often the branch. When only the `Repo` path differs, the skill asks
   whether the checkout moved and replaces the file only if it did. Anything else
   is shown to the user, who agrees a different stream name.
4. **Existing handoffs stay where they are.** Nothing renames or migrates files
   under the old `~/.handoffs/<repo>/` layout. A handoff there is resumed by its
   explicit path. When the next write lands at the new path, the new file lists
   the old one under Pointers as `Supersedes <path>`, and Close deletes both.
   The same applies when a key changes.
5. **All four ports change together**, as ADR-0017 requires. The Copilot prompt
   hands the user the commands, because it does not write the file itself.

This supersedes the definition of `<repo>` in ADR-0017 decision 2. The rest of
ADR-0017 stands.

## Consequences

### Positive

- Same-named repositories no longer share a folder, and the ownership check
  stops an overwrite in the cases a key cannot tell apart.
- The key needs only `git` and the shell the assistant already runs, and keeps
  the readable directory name as its prefix.
- The listing command stays `ls -lt ~/.handoffs/*/` and covers both layouts.

### Negative

- The key changes when the checkout's directory is renamed, when `origin`
  changes (a switch from HTTPS to SSH, a rename or a transfer), or when a
  checkout without a remote moves. The next write lands in a new folder and
  records the old file as superseded, so it is found again only through that
  write; a stream that is never written again leaves its old file for a manual
  close.
- Two clones of the same repository with the same `origin` share a key. The
  ownership check catches the collision, but the second clone has to pick a
  different stream name.
- The hash is opaque: the folder name alone no longer says which owner a
  repository belongs to.
- The command is longer than the old one-liner, and there are two of them.
  An assistant that improvises a third form can split one stream across two
  folders.

### Neutral

- Old handoffs expire with their streams: the first write after a resume moves
  the stream to the new layout and records the old path, and Close deletes
  both.

## Alternatives Considered

- **`<owner>/<repo>` parsed from the remote URL.** Rejected: readable, but every
  URL form (scp-style, HTTPS with credentials, ports, nested groups, local-path
  remotes) needs its own parsing rule, written four times.
- **`gh repo view --json nameWithOwner`.** Rejected: it needs `gh`, network
  access, and a GitHub remote.
- **The root commit hash.** Rejected: forks share it, an empty repository has
  none, and a history can have several.
- **Keep the directory name and add only the ownership check.** Rejected: it
  stops the overwrite but leaves same-named repositories competing for stream
  names. The check stays as a backstop.
- **Migrate old handoffs to the new layout.** Rejected: it renames user files
  automatically, and old handoffs expire with their streams anyway.

## References

- [ADR-0017](./0017-handoff-skill.md).
- `claude-code/.claude/skills/handoff/SKILL.md`, `codex/skills/handoff/SKILL.md`,
  `gemini/commands/handoff.toml`,
  `copilot/workspace-template/.github/prompts/handoff.prompt.md`.
