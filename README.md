# AI Engineering Workspace

**One engineering workflow. Every AI coding assistant.**

[![CI](https://github.com/yuri-semenenko/ai-engineering-workspace/actions/workflows/ci.yml/badge.svg)](https://github.com/yuri-semenenko/ai-engineering-workspace/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

A personalized AI engineering workspace for building one consistent engineering
workflow across Claude Code, OpenAI Codex, GitHub Copilot, and Gemini CLI.

This is not a prompt pack and not a codegen shortcut, and it is not about building
AI systems. It is a portable methodology layer for *using* AI to do software
engineering: a fixed engineering canon, a personalized identity layer, validated
skills/commands/prompts, and tool-specific adapters.

> AI tools change. Engineering principles don't. Encode the principles once and
> let them outlive the tools.

## What this gives you

- One engineering methodology across every supported AI tool.
- A persona wizard that adapts the assistant to your discipline, seniority,
  workflow, stack, and tooling.
- A generated recommended-skills view that tells you which shipped skills to
  reach for first.
- A `/start` onboarding entrypoint inside each supported tool.
- A tool-agnostic repository-contract convention (`AGENTS.md`) and a workflow
  that writes one from a repository's own evidence.
- Drift guards and CI checks so templates, mirrors, and skill references do not
  silently rot.
- ADRs that document why the architecture works this way.

## Why

Enterprise engineers rarely get to pick their AI assistant, and they often use
more than one. Each tool wants its configuration in a different place and format,
so the usual result is several divergent piles of per-tool prompts that drift
apart the moment you edit one. That is a dotfiles problem dressed up as engineering.

This kit inverts it. The durable layer — how you make decisions, review code,
write an RFC, define "done" — is written once as a canon and driven into every
tool by a sync layer with a drift guard that fails your commit when they
diverge. The config is the delivery mechanism; **the methodology is the product.**

## What makes it different

1. **Multi-assistant architecture.** One canonical persona, mirrored to Codex
   and Gemini with a sync script and a drift guard, plus curated, hand-authored
   skill and command ports whose structure the same guard validates. Edit the
   canon, regenerate the mirrors, commit both.
2. **Process skills, not codegen skills.** RFC, ADR, spec, the lazy-ladder,
   debt-ledger, complexity-audit, and a tiered PR-review flow. These encode
   judgment and discipline, not "write my code for me".
3. **Hardened setup.** Permission allow/deny lists, secret-scan and branch-guard
   hooks, and a protected-file guard: a working answer to "how do I let an agent
   loose without it doing something irreversible".

## Quick start

Prerequisites: `git`, plus `bash` and `jq` for the Claude Code hooks and
statusline. On Windows, Git for Windows supplies bash and `winget install
jqlang.jq` supplies jq. Without jq the hooks still exit cleanly but do nothing,
which is why the installer warns and the statusline says so.

```bash
git clone <your-fork-url> ai-engineering-workspace
cd ai-engineering-workspace

# 1. Generate your own persona (interactive; press Enter for sensible defaults).
scripts/create-persona.sh          # Windows: scripts\create-persona.ps1

# 2. Install the tool(s) you use. Each is independent.
claude-code/scripts/install.macos-linux.sh      # symlinks ~/.claude
codex/scripts/install.macos-linux.sh            # provisions $CODEX_HOME
copilot/scripts/install.macos-linux.sh [$HOME] [/path/to/workspace]
gemini/scripts/install.macos-linux.sh           # provisions ~/.gemini
```

Windows equivalents: `install.windows.ps1` in each `scripts/` folder. The Claude
installer runs the persona wizard for you on first install if you skipped step 1.

Already working inside a tool? The `/start` entrypoint (a Claude Code and Codex
skill, a Gemini command, or the Copilot `start` prompt) explains the wizard and
hands you the exact command for your shell. It is a thin pointer to
`scripts/create-persona.{sh,ps1}`, not a second copy of the wizard (see
[`adr/0005-start-entrypoint.md`](adr/0005-start-entrypoint.md)).

Nothing personal is committed: your generated `persona/persona.md`,
`persona/CLAUDE.md`, and `settings.json` are gitignored. (The committed root
`CLAUDE.md` is a different file — the repository's own Claude Code adapter, not
your profile.) The repo ships templates and a generator, not one person's file.

## How it works: canon → mirror

Claude Code is the canon. Codex references are committed **mirrors** so the
`codex/` folder stays standalone-portable (it can be copied to a machine alone and
its installer runs against files already present). A drift guard fails fast if a
mirror goes stale:

```bash
scripts/sync-codex-references.sh           # regenerate mirrors + validate codex skill structure
scripts/sync-codex-references.sh --check    # CI/pre-commit: fail on drift
git config core.hooksPath scripts/hooks     # enable the pre-commit drift guard once per clone
```

Full design in [`docs/architecture.md`](docs/architecture.md), and the reasoning
behind it as records in [`adr/`](adr/).

## Supported tools

| | Claude Code | Codex | Copilot | Gemini CLI |
| --- | --- | --- | --- | --- |
| Persona | `~/.claude/CLAUDE.md` (condensed) + `~/persona.md` (full) | `references/persona.md` (mirror) | `home/.copilot` instructions | `~/.gemini/GEMINI.md` (condensed, always-on) |
| Skills / prompts | 20 process skills + `/start` | 14 skill ports + `start` (`+ agents/openai.yaml`) | 16 workspace prompts + `start` + instruction files | 20 command ports + `start` (`.gemini/commands/*.toml`) |
| Delegation | tier alias in agent config, one shipped reviewer | runtime tier override, no agent files | model picker per request | built-in agent routing + `agents.overrides` |
| Guardrails | `settings.json` permissions + 6 hooks | always-on `$CODEX_HOME/AGENTS.md` | corporate-safe instructions | `settings.json` allowlist + hooks + sandbox |
| Repo contract | root `CLAUDE.md` importing `@AGENTS.md` | root `AGENTS.md`, root-down, closest wins | root `AGENTS.md` on CLI + VS Code, combined with `.github/` instructions | root `AGENTS.md` via `context.fileName` |
| Install mode | symlink (copy on Windows) | copy into `$CODEX_HOME` | Markdown copy only | copy into `~/.gemini` |
| Assumed constraint | full local control | portable seed, on-demand references | locked-down corporate laptop, Markdown-only | local control, sandbox available |

The architecture is tool-agnostic by design. Gemini CLI, the fourth tool, was
added as a new install target plus command ports with no change to the canon or
the other tools — the walk-through is in
[`docs/guides/adding-a-tool.md`](docs/guides/adding-a-tool.md). OpenCode, Cursor,
and others follow the same path.

## Personalization model

A persona file beats ad-hoc prompting because the assistant carries your
engineering judgment into every session without you restating it: simplicity
bias, functional-first defaults, when to challenge a requirement, how to classify
PR feedback, the definition of "done".

The project deliberately separates methodology from identity:

- **Methodology canon — fixed, shared by everyone.** Simplicity ladder, RFC/ADR
  format, PR-review tiers, verification exit criterion, anti-patterns, git
  conventions, and model-tier delegation. Nobody gets a different engineering
  methodology.
- **Identity layer — personalized, yours.** Generated by
  `scripts/create-persona.{sh,ps1}`: discipline (frontend or fullstack), seniority
  (mid, senior, staff, or principal), workflow (delivery, architecture, review, or
  learning focused), plus role, stack, package manager, repo layout, issue tracker,
  and output language.
- **Tool adapters — per assistant.** The same canon and identity reach each tool
  in its native format, by one of two routes. The **sync layer** generates the
  drift-guarded mirrors: the Codex references and Gemini `GEMINI.md`. The
  **wizard** renders your filled `persona/CLAUDE.md` and Copilot instructions,
  which are per-machine and gitignored, so no guard applies to them.

Seniority shapes how the assistant treats you (mid to principal); discipline
shapes the background framing; workflow shapes which skills the generated
`recommended-skills.md` view foregrounds. The methodology canon itself does not
change with any of them (see
[`adr/0003-persona-discipline-and-seniority-axes.md`](adr/0003-persona-discipline-and-seniority-axes.md)
and [`adr/0004-persona-workflow-axis.md`](adr/0004-persona-workflow-axis.md)).

`scripts/create-persona.sh` asks only about the identity layer and stitches it
onto the canon, producing your `persona/persona.md` (full), `persona/CLAUDE.md`
(condensed), and `persona/recommended-skills.md`. See
[`persona/README.md`](persona/README.md).

## Repository contract

Persona and methodology are global: they follow you into every repository. What
an agent needs to know about *one* repository — its commands, its generated
files, its invariants, what it must not touch — is a separate layer, and it lives
in that repository's root `AGENTS.md`. The convention is tool-agnostic: Codex and
Gemini CLI read it directly, Copilot CLI and VS Code Copilot read it as agent
instructions, and Claude Code reads `CLAUDE.md`, so each contract ships a
`CLAUDE.md` whose whole body is an `@AGENTS.md` import. Copilot is several
products and they do not all discover `AGENTS.md`; the per-surface matrix and
what "degraded" means are in [`copilot/README.md`](copilot/README.md).

`AGENTS.md` is a **router, not a knowledge base**. It answers what a competent
agent would not already know, what mistake is likely without the instruction,
where to read next, and how a change is verified — and it never carries persona,
general methodology, or a whole skill.

This repository has its own: [`AGENTS.md`](AGENTS.md). Two other files here share
the name and are not it:

| File | Scope | Reaches the tool by |
| --- | --- | --- |
| [`AGENTS.md`](AGENTS.md) | this repository | committed here, imported by root `CLAUDE.md` |
| `codex/AGENTS.md` | personal and global | installed to `$CODEX_HOME/AGENTS.md` |
| `copilot/workspace-template/AGENTS.md` | a different repository | copied into that repo by the Copilot installer |

To create or update the contract in another repository, use the Codex
`project-onboarding` skill: it inspects the repo read-only, derives commands from
`package.json` and CI rather than guessing them, patches an existing file instead
of overwriting it, and asks before writing. The reasoning is in
[`adr/0014-agents-md-is-the-repository-contract.md`](adr/0014-agents-md-is-the-repository-contract.md).

## Principles

The methodology is written out as prose you can read, disagree with, and adapt
without opening a config file — the simplicity ladder, review discipline, when to
reach for an RFC vs an ADR vs a spec, and how to drive an assistant like a senior
peer. This is the durable core of the kit.

Read it in [`docs/principles/`](docs/principles/).

## Skill catalog (Claude Code)

| Skill | Enforces | Trigger |
| --- | --- | --- |
| `rfc` | 10-section architecture RFC | "RFC for X", "design doc" |
| `adr` | records a decision already made | "ADR for X", "write up that decision" |
| `spec` | goal / non-goals / acceptance criteria before building | "spec this", "what does done mean" |
| `research` | primary-source evidence into a cited decision matrix, then hand off to RFC/ADR | "compare A vs B", "which library" |
| `lazy` | the laziest-solution-that-works ladder (YAGNI → stdlib → …) | "the lazy way", "minimal diff" |
| `module-design` | deep modules, small interfaces, when an abstraction earns its keep | "design this module", "is this abstraction worth it" |
| `migration-plan` | safe incremental migration: invariant, seam, slices, flags, rollback | "plan this migration", "strangler plan" |
| `complexity-audit` | whole-tree scan for over-engineering | "where are we over-built" |
| `debt-ledger` | collects `TRADEOFF(...)` annotations into one ledger | "list tradeoffs" |
| `codebase-map` | orient in unfamiliar code: entry points, domain glossary, seams, risky areas | "map this repo", "where do I start" |
| `debug` | reproduce → build a feedback loop → isolate → fix the cause | "why is X failing", "find root cause" |
| `pr-classify` | Critical / Important / Optional review triage | "review this PR" |
| `pr-comment` | fills the repo's PR template as copy-paste markdown | "prepare a PR description" |
| `pr-recheck` | second-pass re-review after fixes | "recheck the PR" |
| `security-pass` | staged remediation with an approval gate | "harden this", "security pass" |
| `commit` | small logical commits, ask-before-push | "commit", "commit plan" |
| `testing-checklist` | test pyramid, DAMP, TDD loop, failing-test-first | "what should I test here" |
| `web-security-checklist` | OWASP + LLM Top 10, STRIDE | "security review" |
| `web-performance-checklist` | Core Web Vitals, TTFB, FE/BE levers | "why is this page slow" |
| `humanizer` | strips telltale AI-writing patterns | "humanize this", "make it less AI" |

Codex ports the RFC/ADR/humanizer plus its own `architect`, `context-brief`,
`failure-investigation`, `project-onboarding`, `prompt-engineer`,
`pull-request-workflow`, `test-strategy`, `module-design`, `codebase-map`,
`research`, and `migration-plan` workflows. Copilot exposes the same ideas as
`.github/prompts/*.prompt.md`.

## Examples

The fastest way to tell a methodology from a prompt pack is to look at what it
produces. [`examples/`](examples/) walks one fictional engineering problem —
reliable outbound webhook delivery — through three skills: an RFC that explores
the options, an ADR that records the decision, and a tiered PR review of the
implementation.

## Hardening

The Claude Code package ships an opinionated `settings.example.json`:

- **Permission allowlist** — read-only git/gh, scoped npm/test/lint/build, common
  search tools. Everything else prompts.
- **Permission denylist** — `rm -rf`, force-push, hard reset, history rewrites,
  `npm publish`, `gh pr merge`, `node -e`, and similar irreversible or outbound
  actions.
- **Six hooks** — a model-tier reminder on heavy-reasoning commands,
  Prettier-on-write, a post-compaction guardrail re-assert, a default-branch
  commit guard, a secret-pattern scanner, and a protected-file (env/key/lockfile)
  guard.

Details and rationale in [`docs/hardening.md`](docs/hardening.md).

## Adapting it

1. Run `scripts/create-persona.sh` (or edit `persona/*.template.md` directly).
2. Give each repository you work in an `AGENTS.md`: copy
   `copilot/workspace-template/AGENTS.md` and its `CLAUDE.md` into the repo root
   and fill the placeholders, or run the Codex `project-onboarding` skill to
   derive them from that repository's own evidence.
3. Copy `claude-code/.claude/agents/project-agent.template.md`, rename it, and
   fill the role placeholders when you want a dispatchable Claude subagent for
   one project. It reads that project's stack and commands from the repository's
   `AGENTS.md` rather than restating them.
4. Replace `claude-code/.claude/memory-seed.example/` with your own memories, or
   delete it.
5. After editing any canon file, run the sync script and commit the regenerated
   mirrors.

## Roadmap

Conservative and honest — where the kit is going, not a wish list.

### Now

- Stabilize the personalized persona wizard across Bash and PowerShell.
- Keep the `discipline`, `seniority`, and `workflow` axes small and explicit.
- Improve the generated `recommended-skills.md` view so it explains *why* each
  skill is recommended and when to reach for it.
- Keep `/start` a thin onboarding pointer, not a second wizard.

### Next

- Add parity checks between the Bash and PowerShell persona generators.
- Ship a few example profiles (frontend + senior + review-focused; fullstack +
  staff + architecture-focused; frontend + mid + learning-focused).
- Print a short profile summary after the wizard runs.
- Add README walk-throughs for common adoption paths: Claude-first, Codex-first,
  Copilot-only, and multi-tool.

### Later

- Reconsider a profile resolver only if the identity matrix outgrows what the
  shell wizard can safely maintain.
- Add disciplines only when there is enough real methodology and skill content to
  support them.
- Explore a `/start` that can detect whether persona files already exist, without
  editing files behind your back.
- Make the skill catalog more machine-readable if the skill count grows.

### Non-goals for now

- No backend/QA discipline expansion without a clear methodology and skill set.
- No profile-specific methodology forks.
- No per-profile skill installation or hidden filtering.
- No Node.js build step or YAML resolver while the shell wizard stays manageable.

## Contributing

Contributions welcome. Two rules above all: keep it sterile (no personal or
employer data) and keep the canon and its mirrors in sync. See
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Security

The kit stores no user data and runs no service; its security surface is
accidental secret disclosure into the repo and the permission model you install.
Report vulnerabilities privately — see [`SECURITY.md`](SECURITY.md). Never commit
auth files, tokens, credentials, transcripts, logs, or machine-local state; the
`.gitignore` and write-time secret scan are backstops, not permission to be
careless.

## License

MIT License. Copyright © 2026 Yuri Semenenko. See [`LICENSE`](LICENSE).

Forking this? Update the copyright line in [`LICENSE`](LICENSE) to your own name
or handle.
