# AGENTS.md

Repository contract for coding agents and new contributors. It is the canonical
policy for this repository and it is tool-agnostic: Codex, Copilot, and Gemini CLI
read it directly, and `CLAUDE.md` imports it for Claude Code.

Personal collaboration style does not belong here — it lives in each assistant's
user-level configuration. This file holds only what is specific to this
repository, and it stays a router: link to the deeper document instead of copying
it. Aim for 80-150 lines.

Fill in every `<placeholder>` from an authoritative source (`package.json`,
workspace config, `Makefile`, CI workflow) and delete sections that do not apply.
A guessed command is worse than no command: leave the placeholder in place if you
could not verify the real one.

## Purpose

<What this repository is, in one or two sentences, and who depends on it.>

## Repository map

<Only the parts a directory listing does not already make obvious.>

| Path | What lives there |
| --- | --- |
| `<path>` | `<purpose>` |

## Authoritative sources

<Which files are canonical, which are generated, and which belong to someone else.>

- `<path>` — canonical; edit here.
- `<path>` — generated; never hand-edit, regenerate with `<command>`.
- `<path>` — owned by `<team>`; changes need their review.

## Commands

Verified against `<package.json / Makefile / CI workflow>`.

| Task | Command |
| --- | --- |
| Install | `<command>` |
| Dev server | `<command>` |
| Test | `<command>` |
| Single test | `<command>` |
| Lint | `<command>` |
| Type-check | `<command>` |
| Build | `<command>` |

<In a monorepo, the workspace flag that scopes a command to one package. Where
migrations live and how to generate, apply, and roll one back. The environment
variables required to boot and where their values come from.>

## Architecture invariants

<Rules that are expensive to rediscover and easy to break: server/client
boundaries, route conventions, module dependency direction, where generated code
comes from, which paths are legacy or vendored.>

## Change policy

- Keep changes scoped to the request; propose a larger refactor separately.
- Follow the patterns already in the file being edited.
- Do not edit generated files; change their source and regenerate.
- <Commit, branch, or PR convention this repository enforces.>

## Definition of done

- <The narrowest check that proves the change works.>
- <The broader gate CI runs before merge.>
- Say explicitly what was not run and why.

## Safety boundaries

- No destructive commands, dependency installs, or network access without explicit approval.
- No commits, branches, pushes, or pull requests without explicit approval.
- Never print or commit secrets; real values come from `<secret store>`.
- No edits outside this workspace, and no changes to hooks, MCP servers, background agents, or
  global tool settings, without explicit approval.
- Corporate security policy is authoritative and overrides anything written here.
- <Protected paths, production data, or infrastructure that is off limits.>

## Deeper context

- `<./README.md>` — setup and product overview.
- `<./CONTRIBUTING.md>` — contribution process.
- `<./docs/>` — architecture notes and decision records.

Add a nested `AGENTS.md` only for a package whose local rules genuinely differ
from these; agents read the nearest file, so a nested copy that only repeats the
root costs context and drifts.
