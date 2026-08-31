# Architecture: canon → mirror

## The layers

Six layers of instruction reach an assistant from this repository. The rest of this document is about the one layer that gets copied into several tools and therefore needs a drift guard: the persona. This table exists so a change lands in the layer that owns it.

| Layer | Scope | Canonical location |
| --- | --- | --- |
| Persona | one person, every repository | `persona/persona.template.md`, `persona/CLAUDE.template.md` |
| Methodology | everyone, every repository | `docs/principles/` |
| Repository contract | everyone, one repository | that repository's root `AGENTS.md` |
| Skills | one class of task | `claude-code/.claude/skills/`, `codex/skills/`, `gemini/commands/`, `copilot/workspace-template/.github/prompts/` |
| Adapters | one tool | `claude-code/`, `codex/`, `copilot/`, `gemini/` |
| Guardrails | mechanically enforced | `settings.example.json`, `scripts/`, `.github/workflows/ci.yml` |

Persona and methodology are global and shared: one person's persona, one methodology, carried into every repository. A repository contract is neither, so it is committed in the repository it describes and never mirrored from here. Copying persona or methodology into one would fork them per project. See [`../adr/0014-agents-md-is-the-repository-contract.md`](../adr/0014-agents-md-is-the-repository-contract.md).

### Three files named `AGENTS.md`

| File | Scope | Reaches the tool by |
| --- | --- | --- |
| `AGENTS.md` (root) | this repository | committed here; root `CLAUDE.md` imports it for Claude Code |
| `codex/AGENTS.md` | personal and global | installed to `$CODEX_HOME/AGENTS.md` |
| `copilot/workspace-template/AGENTS.md` | a different repository | copied into that repo by the Copilot installer |

They are not mirrors of each other and no sync runs between them. Only the pairs listed below are generated. Codex and Copilot read `AGENTS.md` directly; Gemini CLI does because `gemini/settings.example.json` lists it in `context.fileName`. Claude Code reads `CLAUDE.md` rather than `AGENTS.md`, so every contract ships with a `CLAUDE.md` that imports it — the platform's own bridge, which cannot drift.

### Three files named `CLAUDE.md`

| Path or destination | Role |
| --- | --- |
| `CLAUDE.md` (root) | Claude Code adapter for this repository: the active `@AGENTS.md` import plus any Claude-only delta |
| `persona/CLAUDE.template.md` | canon for the condensed persona; mirrored to `gemini/references/GEMINI.md` |
| `persona/CLAUDE.md` -> `~/.claude/CLAUDE.md` | the developer's generated persona: user identity and collaboration layer, gitignored |

Tool discovery dictates the filename in all three cases, so none can be renamed; qualify which one you mean by its path. An adapter is not a second canonical source as long as it holds only the import, its own role, and genuine Claude-only deltas. That boundary is a convention, not something the drift guards can prove — [`../adr/0014-agents-md-is-the-repository-contract.md`](../adr/0014-agents-md-is-the-repository-contract.md) records it.

## The problem

The same persona and durable-memory context should drive multiple assistants. Editing that content in three places by hand guarantees drift. But each tool package must also stay **standalone-portable**: you should be able to copy `codex/` alone to a machine and have its installer work against the files already present, with no build step.

Those two goals conflict unless you commit generated artifacts on purpose.

## The design

One canon, committed mirrors, a guard that fails on drift.

```
persona/persona.template.md              (canon) ── sync ─▶ codex/references/persona.md            (mirror, full)
claude-code/.claude/memory-seed.example/ (canon) ── sync ─▶ codex/references/memory-seed.example/  (mirror)
persona/CLAUDE.template.md               (canon) ── sync ─▶ gemini/references/GEMINI.md            (mirror, condensed)
```

- **Canon** lives in `persona/` and `claude-code/`. You edit only here.
- **Mirrors** under `codex/references/` and `gemini/references/` are byte-for-byte copies, committed so each tool folder is self-contained.
- Codex takes the **full** persona, because it loads references on demand. Gemini takes the **condensed** one, because `GEMINI.md` is re-sent on every prompt.
- `scripts/sync-codex-references.{sh,ps1}` regenerates the mirrors from the canon.
- `--check` mode diffs canon against mirror and exits non-zero on any difference. Wire it as a pre-commit hook with `git config core.hooksPath scripts/hooks`.

## Why mirrors are committed rather than generated at install

If the mirrors were generated at install time, `codex/` could not be copied on its own — it would need the canon and a working shell to build itself. Committing the mirror keeps each tool folder a complete, inspectable unit. The cost is that you must regenerate and commit after editing the canon; the drift guard makes forgetting a hard error instead of a silent inconsistency.

## Codex skills are not mirrors

`codex/skills/` are hand-authored Codex ports (each with `SKILL.md` + `agents/openai.yaml`). There is no canon to generate them from, so the sync script does not touch their content. Instead it **validates their structure**: every skill directory has both files, the frontmatter `name:` matches the directory name, and the skills root holds only directories. The same drift guard enforces this on commit. There is no auto-fix — a malformed skill is a hard error you correct by hand.

`gemini/commands/` is the same kind of thing: hand-authored ports, owned where they live, validated rather than generated. The guard there checks that the directory holds only `*.toml` and that each file has a `prompt` field.

## The two layers of persona

The committed layer is the **template** (`persona.template.md`) and its mirror. The drift guard runs against templates, so the shipped repo stays honest regardless of what any user does locally.

Your **filled** persona (`persona/persona.md`, generated by the wizard) is a separate, gitignored, per-machine concern. Installers prefer it over the template when present. This keeps the public repo free of personal content while still letting the generator drive every tool from one wizard run.
