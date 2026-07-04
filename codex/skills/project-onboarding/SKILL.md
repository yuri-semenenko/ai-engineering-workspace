---
name: project-onboarding
description: Use when initializing, auditing, or updating a project's AGENTS.md, onboarding Codex to a repository, capturing repo-specific commands, or turning sparse project context into high-signal agent instructions.
---

# Project Onboarding

Create or improve a project-level `AGENTS.md` that helps Codex work in the repo without restating generic engineering advice.

## What To Capture

- Scripts: build, test, lint, typecheck, dev, format, and workspace flags.
- Single-test command with a concrete example.
- Migrations: location, generate/apply/rollback commands, Supabase workflow if relevant.
- Local DB and seed data setup.
- Required env vars and where values come from.
- Non-obvious repo structure, server/client boundaries, route conventions, and generated files.
- Auth, RLS, test harness, PR/commit conventions, CI gotchas, and monitoring only when they exist.

## What To Skip

- Full file trees.
- Generic "write tests" or "use TypeScript" advice.
- Stack summaries already visible in `package.json`.
- Friendly boilerplate.

## Process

1. Read existing `AGENTS.md`, `README`, `package.json`, test config, migration folders, and CI files.
2. Identify commands and gotchas from repo evidence, not guesses.
3. Keep `AGENTS.md` around 80-150 lines unless the repo genuinely needs more.
4. Prefer repo-specific facts over universal preferences.
5. If the repo already has good instructions, patch only stale or missing sections.

Use `$CODEX_HOME/references/memory-seed/project_claude_md_checklist.md` for the longer migrated checklist when needed.
