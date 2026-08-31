# Hardening

The Claude Code package ships `claude-code/.claude/settings.example.json`. The installer seeds it to `settings.json` (gitignored) on first run. It combines a permission model with six write- and command-time hooks. This is the practical answer to "how do I let an agent work autonomously without it doing something irreversible or leaking a secret".

## Permission model

Claude Code checks each tool call against allow/deny lists. Anything not matched prompts interactively.

**Allowlist (auto-approved)** covers actions that are safe to run unattended:

- Read-only git: `status`, `diff`, `log`, `show`, `branch`, `blame`, `rev-parse`, `ls-files`, `stash list/show`, `config --get`.
- Mutating-but-recoverable git: `add`, `commit -m`, `switch`, `fetch`, `stash push/pop`.
- Scoped npm: `install`/`ci`, `run test|lint|typecheck|format|build`, workspace flags, version checks.
- Test/lint binaries: `tsc`, `vitest`, `eslint`, `prettier`, `jest`, `next lint|build`.
- Search and inspection: `ls`, `pwd`, `which`, `tree`, `find .`, `rg`, `grep`, `jq`, `file`, `stat`, `wc`.
- Read-only `gh`: `pr view|list|diff|checks|status`, `issue view|list`, `repo view`, `run list|view`, `workflow list|view`.

**Denylist (always blocked)** covers the irreversible and the outbound:

- Destructive filesystem/git: `rm -rf`, `rm -fr`, `git reset --hard`, `git clean -fd[x]`, `git checkout --`, `git restore --staged`, `git branch -D`.
- History rewrites: `commit --amend`, `rebase -i`, `filter-branch`, force-push in every spelling.
- Publish/merge/delete: `npm publish|unpublish|deprecate`, `gh pr merge`, `gh release create`, `gh repo delete`.
- Arbitrary execution: `node -e`.

Adjust these to your stack. The lists are deliberately conservative; add stack-specific tools (cloud CLIs, DB tools) to the allowlist as you trust them, and keep anything irreversible or outbound on the denylist.

## Hooks

| Event | Hook | What it does |
| --- | --- | --- |
| `UserPromptSubmit` | model-reminder | On `/rfc` or `/adr`, reminds you to confirm the session is on your top reasoning tier. |
| `PostToolUse` (Write/Edit) | Prettier | Formats supported files on write, only when a Prettier config resolves. |
| `PostCompact` | guardrail re-assert | Re-injects the core persona rules after context compaction so they survive summarization. |
| `PreToolUse` (Bash) | branch guard | If a `git commit` runs on the default branch, prompts to create a feature branch first. |
| `PreToolUse` (Write/Edit) | secret scan | Blocks-to-ask when a write contains a private-key header or an AWS/GitHub/Slack token pattern. |
| `PreToolUse` (Write/Edit) | path guard | Prompts before editing `.env`, `*.pem`/`*.key`, or lockfiles (allows `.env.example` and friends). |

The hooks are shell + `jq`; they degrade to no-ops if a dependency is missing rather than blocking your work. The `Notification` hook uses `osascript` (macOS) and simply surfaces a desktop notification.

## Codex and Copilot guardrails

- **Codex** puts the hard rules in the global `$CODEX_HOME/AGENTS.md` installed from `codex/AGENTS.md`, which loads every session (references and skills are read on demand). Git guardrails and the "verify before claiming done" rule live there. A repository's own root `AGENTS.md` is a different file with a different scope — see [`../adr/0014-agents-md-is-the-repository-contract.md`](../adr/0014-agents-md-is-the-repository-contract.md).
- **Copilot** assumes a locked-down corporate laptop: Markdown-only, copy-only, no hooks or automation. Its instruction files tell the assistant not to bypass execution policy, install tools, configure MCP servers, or exfiltrate data.
