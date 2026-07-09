# Persona

The persona is the single source of truth for how the assistant collaborates with you. It splits into two layers:

- **Methodology canon** — fixed, the same for every adopter. Simplicity ladder, RFC/ADR format, PR-review tiers, verification exit criterion, anti-patterns, session hygiene, model-tier delegation, git conventions. This is the reusable value of the kit.
- **Identity header** — yours. Discipline, seniority, role, primary stack, package manager, repo layout, issue tracker, output language. These are the only `{{PLACEHOLDERS}}` in the templates. Two of them shape the output beyond plain substitution: **seniority** fills the "Seniority Model" section (how to treat you), and **discipline** sets the background framing and the generated recommended-skills list. The methodology canon does not change with either (see [ADR-0003](../adr/0003-persona-discipline-and-seniority-axes.md)).

## Files

| File | Role |
| --- | --- |
| `persona.template.md` | Full persona, canon + `{{PLACEHOLDERS}}`. Also the sync canon mirrored to `codex/references/persona.md`. |
| `CLAUDE.template.md` | Condensed version, shaped for `~/.claude/CLAUDE.md`. |
| `persona.md` | **Generated, gitignored.** Your filled full persona. |
| `CLAUDE.md` | **Generated, gitignored.** Your filled condensed persona. |
| `recommended-skills.md` | **Generated, gitignored.** Which shipped skills to reach for first, from your discipline + seniority. |

## Generate yours

```bash
scripts/create-persona.sh            # interactive; Enter accepts each default
scripts/create-persona.sh --defaults  # accept everything, no prompts (CI)
```

```powershell
powershell -NoProfile -File .\scripts\create-persona.ps1
powershell -NoProfile -File .\scripts\create-persona.ps1 -Defaults
```

The wizard asks only about the identity header (starting with discipline and seniority), then writes `persona/persona.md`, `persona/CLAUDE.md`, and `persona/recommended-skills.md`. `--defaults` yields the `staff` + `fullstack` profile, byte-identical to the pre-axes output. The per-tool installers pick up the persona files automatically:

- Claude Code installs `CLAUDE.md` to `~/.claude/CLAUDE.md` and `persona.md` to `~/persona.md`.
- Codex installs the filled `persona.md` to `$CODEX_HOME/references/persona.md` (falling back to the committed template mirror if you copy `codex/` standalone).

## Editing the canon

To change the shared methodology, edit `persona.template.md` (and `CLAUDE.template.md` to match), then regenerate your files and the Codex mirror:

```bash
scripts/create-persona.sh --defaults
scripts/sync-codex-references.sh
```

The drift guard (`--check`) enforces that `codex/references/persona.md` stays a verbatim mirror of `persona.template.md`.
