# Persona

The persona is the single source of truth for how the assistant collaborates with you. It splits into two layers:

- **Methodology canon** — fixed, the same for every adopter. Simplicity ladder, RFC/ADR format, PR-review tiers, verification exit criterion, anti-patterns, session hygiene, model-tier delegation, git conventions. This is the reusable value of the kit.
- **Identity header** — yours. Role, seniority framing, primary stack, package manager, repo layout, issue tracker, output language. These are the only `{{PLACEHOLDERS}}` in the templates.

## Files

| File | Role |
| --- | --- |
| `persona.template.md` | Full persona, canon + `{{PLACEHOLDERS}}`. Also the sync canon mirrored to `codex/references/persona.md`. |
| `CLAUDE.template.md` | Condensed version, shaped for `~/.claude/CLAUDE.md`. |
| `persona.md` | **Generated, gitignored.** Your filled full persona. |
| `CLAUDE.md` | **Generated, gitignored.** Your filled condensed persona. |

## Generate yours

```bash
scripts/create-persona.sh            # interactive; Enter accepts each default
scripts/create-persona.sh --defaults  # accept everything, no prompts (CI)
```

```powershell
powershell -NoProfile -File .\scripts\create-persona.ps1
powershell -NoProfile -File .\scripts\create-persona.ps1 -Defaults
```

The wizard asks only about the identity header, then writes `persona/persona.md` and `persona/CLAUDE.md`. The per-tool installers pick those up automatically:

- Claude Code installs `CLAUDE.md` to `~/.claude/CLAUDE.md` and `persona.md` to `~/persona.md`.
- Codex installs the filled `persona.md` to `$CODEX_HOME/references/persona.md` (falling back to the committed template mirror if you copy `codex/` standalone).

## Editing the canon

To change the shared methodology, edit `persona.template.md` (and `CLAUDE.template.md` to match), then regenerate your files and the Codex mirror:

```bash
scripts/create-persona.sh --defaults
scripts/sync-codex-references.sh
```

The drift guard (`--check`) enforces that `codex/references/persona.md` stays a verbatim mirror of `persona.template.md`.
