# Gemini CLI package

Gemini CLI as a first-class install target: the condensed persona as an always-on
context file, the process skills as custom commands, and a permission allowlist
with guardrail hooks and the sandbox turned on.

## Layout

```
references/
  GEMINI.md            MIRROR of persona/CLAUDE.template.md (do not hand-edit)
commands/              20 hand-authored command ports + a start entrypoint (*.toml)
scripts/
  install.macos-linux.sh
  install.windows.ps1
settings.example.json  tool allowlist + guardrail hooks + sandbox
```

## Install

```bash
scripts/install.macos-linux.sh                  # into ~/.gemini
scripts/install.macos-linux.sh /custom/gemini   # explicit target
```

```powershell
powershell -NoProfile -File .\scripts\install.windows.ps1
```

The installer copies the context file to `$GEMINI_HOME/GEMINI.md` and the command
ports to `$GEMINI_HOME/commands/`, then seeds `settings.json` **only if you do not
already have one**, so an existing config is never clobbered. If you generated a
filled persona (`scripts/create-persona.sh`), it installs that over the template
mirror; otherwise it falls back to the committed mirror so a standalone `gemini/`
copy still works. Auth, logs, sessions, and cache are never touched.

`GEMINI.md` is re-sent on every prompt, which is why the mirror is the
**condensed** persona rather than the full one.

## What is a mirror and what is owned here

- `references/GEMINI.md` is a **generated mirror** of `persona/CLAUDE.template.md`.
  Never hand-edit it. Edit the canon and run `scripts/sync-codex-references.sh`
  from the repo root; `--check` fails on drift.
- `commands/` is **owned here**. The ports are hand-authored from the Claude
  skills, so the sync script does not regenerate their content. It validates the
  structure instead: the directory holds only `*.toml`.

See [`../docs/architecture.md`](../docs/architecture.md).

## Delegation in Gemini

Gemini can run subagents with a `model:` and a `tools:` allowlist per agent, and
it ships a built-in `codebase_investigator` for read-only exploration. This
package deliberately installs **no agent files**. Gemini's config names a
concrete model, and concrete model names churn faster than the methodology, so
committing them would make this repo track runtime naming
([`../adr/0012-tier-labels-over-pinned-model-slugs.md`](../adr/0012-tier-labels-over-pinned-model-slugs.md)).

Be clear about what that costs: with no agent files installed there is no
per-subagent tier to override. `codebase_investigator` runs on whatever model the
session is on, and so does anything else you delegate. The tier below is the tier
the work *wants* — you get it by picking the session model deliberately, or by
writing your own agent file with a concrete model in it and accepting that the
name will churn. Treat the table as a boundary map, not as a switch this package
wires up:

| Work | Tier the work wants | Boundary |
| --- | --- | --- |
| Broad search, orientation, evidence gathering | routine, read-only | Lean on the built-in `codebase_investigator`; it returns evidence, you interpret it. |
| Mechanical edits, fixtures, codemod-style work | routine | Well-scoped, non-overlapping write sets only. |
| Implementation carrying real judgment | default | The parent keeps scope and design. |
| Review, security judgment, architecture trade-offs | default or escalation | The parent owns the verdict. |

The canon's workflows ([`../docs/principles/working-with-agents.md`](../docs/principles/working-with-agents.md))
map onto the command ports: `explore` is `codebase_investigator` or
`/codebase-map`, `architect` is `/rfc` or `/module-design`, `decide` is yours with
`/adr` recording it, `review` is `/pr-classify`. `judge` never leaves the parent.

Inheriting the session's model is the default here, not a fallback. Do not
delegate trivial work, and do not put two agents on overlapping files.

## Guardrails

`settings.example.json` ships the sandbox enabled, a read-only
`run_shell_command` allowlist, and four hooks: a command guard that denies
irreversible or outbound commands and blocks commits on the default branch, a
secret-pattern scanner on writes, a protected-file guard for env/key/lockfiles,
and Prettier-on-write. Rationale in [`../docs/hardening.md`](../docs/hardening.md).
