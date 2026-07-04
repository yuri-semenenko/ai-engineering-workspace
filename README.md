# multi-ai-config

**Staff-engineer discipline for AI coding assistants: one persona canon, three tools, kept in sync by design.**

Most published AI-assistant configs cover a single tool and read like personal dotfiles. This is a methodology kit. You define *how a senior engineer works* once, and it drives Claude Code, OpenAI Codex, and GitHub Copilot from the same source of truth. Enterprise engineers rarely get to pick their tool; this setup follows you across whichever one the employer allows.

Three things make it different:

1. **Multi-assistant architecture.** One canonical persona plus a curated skill set, mirrored to Codex and Copilot with a sync script and a drift guard. Edit the canon, regenerate the mirrors, commit both.
2. **Process skills, not codegen skills.** RFC, ADR, spec, the lazy-ladder, debt-ledger, complexity-audit, and a tiered PR-review flow. These encode judgment and discipline, not "write my code for me".
3. **Hardened setup.** Permission allow/deny lists, secret-scan and branch-guard hooks, and a protected-file guard: a working answer to "how do I let an agent loose without it doing something irreversible".

## Quick start

```bash
git clone <your-fork-url> multi-ai-config
cd multi-ai-config

# 1. Generate your own persona (interactive; press Enter for sensible defaults).
scripts/create-persona.sh          # Windows: scripts\create-persona.ps1

# 2. Install the tool(s) you use. Each is independent.
claude-code/scripts/install.macos-linux.sh      # symlinks ~/.claude
codex/scripts/install.macos-linux.sh            # provisions $CODEX_HOME
copilot/scripts/install.macos-linux.sh [$HOME] [/path/to/workspace]
```

Windows equivalents: `install.windows.ps1` in each `scripts/` folder. The Claude installer runs the persona wizard for you on first install if you skipped step 1.

Nothing personal is committed: your generated `persona.md`, `CLAUDE.md`, and `settings.json` are gitignored. The repo ships templates and a generator, not one person's profile.

## Tool matrix

| | Claude Code | Codex | Copilot |
| --- | --- | --- | --- |
| Persona | `~/.claude/CLAUDE.md` (condensed) + `~/persona.md` (full) | `references/persona.md` (mirror) | `home/.copilot` instructions |
| Skills / prompts | 16 process skills | 9 skill ports (`+ agents/openai.yaml`) | 11 workspace prompts + instruction files |
| Guardrails | `settings.json` permissions + 5 hooks | always-on `AGENTS.md` | corporate-safe instructions |
| Install mode | symlink (copy on Windows) | copy into `$CODEX_HOME` | Markdown copy only |
| Assumed constraint | full local control | portable seed, on-demand references | locked-down corporate laptop, Markdown-only |

## The persona concept

A persona file beats ad-hoc prompting because the assistant carries your engineering judgment into every session without you restating it: simplicity bias, functional-first defaults, when to challenge a requirement, how to classify PR feedback, the definition of "done".

The kit splits it in two:

- **Methodology canon** (fixed, shared by everyone) — simplicity ladder, RFC/ADR format, PR-review tiers, verification exit criterion, anti-patterns, git conventions, model-tier delegation.
- **Identity header** (yours) — role, stack, tooling, output language.

`scripts/create-persona.sh` asks only about the header and stitches it onto the canon, producing your `persona/persona.md` (full) and `persona/CLAUDE.md` (condensed). See [`persona/README.md`](persona/README.md).

## Skill catalog (Claude Code)

| Skill | Enforces | Trigger |
| --- | --- | --- |
| `rfc` | 10-section architecture RFC | "RFC for X", "design doc" |
| `adr` | records a decision already made | "ADR for X", "write up that decision" |
| `spec` | goal / non-goals / acceptance criteria before building | "spec this", "what does done mean" |
| `lazy` | the laziest-solution-that-works ladder (YAGNI → stdlib → …) | "the lazy way", "minimal diff" |
| `complexity-audit` | whole-tree scan for over-engineering | "where are we over-built" |
| `debt-ledger` | collects `TRADEOFF(...)` annotations into one ledger | "list tradeoffs" |
| `debug` | reproduce → isolate → hypothesize → fix the cause | "why is X failing", "find root cause" |
| `pr-classify` | Critical / Important / Optional review triage | "review this PR" |
| `pr-comment` | fills the repo's PR template as copy-paste markdown | "prepare a PR description" |
| `pr-recheck` | second-pass re-review after fixes | "recheck the PR" |
| `security-pass` | staged remediation with an approval gate | "harden this", "security pass" |
| `commit` | small logical commits, ask-before-push | "commit", "commit plan" |
| `testing-checklist` | test pyramid, DAMP, failing-test-first | "what should I test here" |
| `web-security-checklist` | OWASP + LLM Top 10, STRIDE | "security review" |
| `web-performance-checklist` | Core Web Vitals, TTFB, FE/BE levers | "why is this page slow" |
| `humanizer` | strips telltale AI-writing patterns | "humanize this", "make it less AI" |

Codex ports the RFC/ADR/humanizer plus its own `architect`, `context-brief`, `failure-investigation`, `project-onboarding`, `prompt-engineer`, and `pull-request-workflow` workflows. Copilot exposes the same ideas as `.github/prompts/*.prompt.md`.

## Hardening

The Claude Code package ships an opinionated `settings.example.json`:

- **Permission allowlist** — read-only git/gh, scoped npm/test/lint/build, common search tools. Everything else prompts.
- **Permission denylist** — `rm -rf`, force-push, hard reset, history rewrites, `npm publish`, `gh pr merge`, `node -e`, and similar irreversible or outbound actions.
- **Five hooks** — a model-tier reminder on heavy-reasoning commands, Prettier-on-write, a post-compaction guardrail re-assert, a default-branch commit guard, a secret-pattern scanner, and a protected-file (env/key/lockfile) guard.

Details and rationale in [`docs/hardening.md`](docs/hardening.md).

## Architecture: canon → mirror

Claude Code is the canon. Codex references are committed **mirrors** so the `codex/` folder stays standalone-portable (it can be copied to a machine alone and its installer runs against files already present). A drift guard fails fast if a mirror goes stale:

```bash
scripts/sync-codex-references.sh           # regenerate mirrors + validate codex skill structure
scripts/sync-codex-references.sh --check    # CI/pre-commit: fail on drift
git config core.hooksPath scripts/hooks     # enable the pre-commit drift guard once per clone
```

Full design in [`docs/architecture.md`](docs/architecture.md).

## Adapting it

1. Run `scripts/create-persona.sh` (or edit `persona/*.template.md` directly).
2. Copy `claude-code/.claude/agents/project-agent.template.md`, rename it, and fill the placeholders to encode one project's stack and conventions.
3. Replace `claude-code/.claude/memory-seed.example/` with your own memories, or delete it.
4. After editing any canon file, run the sync script and commit the regenerated mirrors.

## Security posture

Do not add auth files, tokens, credentials, session transcripts, logs, telemetry, plugin/model caches, or machine-local runtime state. The `.gitignore` is a whitelist-style backstop, and the write-time hooks scan for secret patterns. Your generated persona and `settings.json` are gitignored by design.

## Contributing

Contributions welcome. Two rules above all: keep it sterile (no personal or employer data) and keep the canon and its mirrors in sync. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT. See [`LICENSE`](LICENSE) — set your name or handle in the copyright line before publishing.
