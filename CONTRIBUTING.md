# Contributing

Thanks for your interest. This repo is a curated methodology kit, not a grab-bag of dotfiles, so contributions are held to two rules above all: **keep it sterile** and **keep the canon and its mirrors in sync**.

## Ground rules

- **No personal or employer data, ever.** No real names (beyond the LICENSE author), emails, employer or client names, internal system names, private paths, tokens, transcripts, or caches. Examples must be fictional and generic. The `.gitignore` and the write-time secret-scan hook are backstops, not permission to be careless.
- **Templates over specifics.** Anything project- or person-specific ships as a `*.template.md` with `{{PLACEHOLDERS}}` and how-to guidance, not as one person's filled-in config.
- **Process, not codegen.** Skills encode *how a senior engineer works* (RFC, ADR, review discipline, simplicity ladder). "Write my feature for me" prompts are out of scope.

## Local setup

```bash
scripts/create-persona.sh          # generate your own gitignored persona
git config core.hooksPath scripts/hooks   # enable the drift-guard pre-commit hook (once per clone)
```

## The canon → mirror workflow

Claude Code is the canon. The Codex and Gemini references are **generated mirrors**, committed so those folders stay standalone-portable. Never hand-edit a mirror.

```
persona/persona.template.md              (canon) ->  codex/references/persona.md           (mirror)
claude-code/.claude/memory-seed.example/ (canon) ->  codex/references/memory-seed.example/  (mirror)
persona/CLAUDE.template.md               (canon) ->  gemini/references/GEMINI.md           (mirror)
```

After editing any canon file:

```bash
scripts/sync-codex-references.sh        # regenerate mirrors + validate codex skill structure
scripts/sync-codex-references.sh --check # what the pre-commit hook runs; must pass
git add codex/references gemini/references
```

A stale mirror is a hard error (the pre-commit hook blocks the commit). See [`docs/architecture.md`](docs/architecture.md).

## Codex skills

`codex/skills/` are owned here (hand-authored, no canon to regenerate from). Each skill directory must have:

- a `SKILL.md` whose frontmatter `name:` matches the directory name, and
- an `agents/openai.yaml`.

The sync script validates this structure; there is no auto-fix.

## The repository contract

Root [`AGENTS.md`](./AGENTS.md) is this repository's contract for coding agents: ownership boundaries, the exact validation commands, the invariants, and which ADR to read before changing one of them. Root `CLAUDE.md` is the Claude Code adapter, because Claude Code reads `CLAUDE.md` and not `AGENTS.md`: it holds the `@AGENTS.md` import and may hold a genuinely Claude-only delta, but never a copy of a rule from the contract. Every repository-wide rule goes in `AGENTS.md`. `scripts/test-check-repository-contract.sh` runs the guard against the checkout and then its fixtures, and fails if a pairing, an `@AGENTS.md` import, or a referenced path breaks.

Two other files here are also called `AGENTS.md` and are **not** this contract: `codex/AGENTS.md` is the personal, global payload installed to `$CODEX_HOME`, and `copilot/workspace-template/AGENTS.md` is a template copied into someone else's repository. They are not mirrored into each other. See [`adr/0014-agents-md-is-the-repository-contract.md`](./adr/0014-agents-md-is-the-repository-contract.md).

## Commits and PRs

- Small, logically-grouped commits. Never batch unrelated changes.
- Do not add `Co-Authored-By` trailers or AI-attribution footers to commits or PR text.
- Write PR descriptions and review comments in English.
- Run `scripts/sync-codex-references.sh --check` and `scripts/test-check-repository-contract.sh`, and confirm the installers still run (`claude-code/scripts/install.macos-linux.sh`, `codex/scripts/install.macos-linux.sh`, `copilot/scripts/install.macos-linux.sh`) against a scratch `$HOME`/`$CODEX_HOME` before opening a PR that touches them.
- Touching a `.ps1` port, or anything the installers copy, means running the Windows suite too: `pwsh scripts\test-windows.ps1`. It drives the wizard and all four installers under both PowerShell 7 and Windows PowerShell, against a sandbox copy of the tree with `HOME` redirected, so it never touches your own `~/.claude`. CI runs it on `windows-latest`.

## What not to add

Auth files, tokens, credentials, session transcripts, logs, telemetry, plugin or model caches, system-managed skills, lockfiles, or any machine-local runtime state.
