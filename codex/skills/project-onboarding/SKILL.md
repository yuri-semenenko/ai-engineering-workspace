---
name: project-onboarding
description: Use when initializing, auditing, or updating a project's AGENTS.md, onboarding an agent to a repository, capturing repo-specific commands, or turning sparse project context into high-signal agent instructions.
---

# Project Onboarding

Create or update a repository's root `AGENTS.md`: the tool-agnostic contract for
how agents work in that repository.

`AGENTS.md` is a context router, not a codebase dump. It answers four questions
and nothing else: what would a competent agent not know about this repository,
what mistake is likely without this instruction, where should it read next, and
how is a change verified here. If a fact is derivable from `package.json` or a
directory listing, leave it out.

## Boundaries

- Never copy the persona, general engineering methodology, or a whole skill into
  the project contract. Those are global and shared; this file is repository-specific.
- Never invent a command. Every command comes from `package.json`, workspace
  config, `Makefile`, CI workflow, or existing developer docs. If discovery
  cannot settle a value, leave a `<placeholder>` and say so in the report.
- Target 80-150 lines. Longer than that and it stops being read.

## Process

1. **Inspect read-only first.** Do not write anything during discovery.
2. **Read what already exists:** root and nested `AGENTS.md`, `CLAUDE.md`,
   `.github/copilot-instructions.md`, `GEMINI.md`, `.cursor/rules/`, `README`,
   `CONTRIBUTING`, `package.json` (plus workspace config), test and lint config,
   migration directories, and CI workflows.
3. **Identify from evidence:** package manager and lockfile, repository layout
   (single package or workspaces), the build/test/lint/type-check/dev commands
   and the single-test invocation, architecture boundaries, generated files,
   protected or vendored paths, and the environment variables required to boot.
4. **Separate verified facts from inferences.** A command read from a script
   entry is verified; a command guessed from a framework convention is an
   inference and must be labelled as one.
5. **Detect an existing contract.** Check the root and every nested `AGENTS.md`.
6. **Prepare an update, never an overwrite.** Human-authored content stays.
   Patch stale sections, fill gaps, and leave anything you cannot verify alone.
7. **Present material ambiguities and conflicts before writing** — two
   plausible test commands, instructions that contradict the code, a stale
   command that no longer exists.
8. **Get explicit approval, then write.** Show the proposed diff, or the full
   file for a new one, and wait for a go-ahead before touching the repository.
9. **Recommend a nested `AGENTS.md` only** when a package or service genuinely
   has different local rules. Agents read the nearest file, so a nested copy that
   repeats the root only costs context and drifts.
10. **Validate every referenced path** against the working tree before writing.
    A contract that links to a file that does not exist is worse than silence.
11. **Wire up the tools the repository actually uses.** Codex and Copilot read
    `AGENTS.md` directly, and Gemini CLI does when `context.fileName` lists it.
    Claude Code does not: it reads `CLAUDE.md`, so add a `CLAUDE.md` whose body
    is `@AGENTS.md` rather than a second copy of the rules.
12. **Report** what was created, what was changed, what was inferred rather than
    verified, and what stayed unresolved.

## Sections to fill

Purpose; repository map (only the non-obvious parts); authoritative sources
(canonical, generated, other-team-owned); verified commands; architecture
invariants; change policy; definition of done; safety boundaries; links for
deeper context.

## Do not run

Do not execute build, test, migration, deployment, or network commands just to
confirm they work. Record them and let the user run them.

`$CODEX_HOME/AGENTS.md` is the personal, global layer and is not what this skill
writes. Keep repository facts out of it and in the repository's own `AGENTS.md`.
