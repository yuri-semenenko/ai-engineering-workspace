---
name: start
description: Onboarding entrypoint for this kit. Explains what the persona wizard does and gives the exact command to generate your own persona (persona.md, CLAUDE.md, recommended-skills.md) from the shared templates. Use when the user wants to get started, onboard to the workspace, or set up their persona. Does not run the wizard or edit files unless explicitly asked.
---

# Start

The onboarding entrypoint for the ai-engineering-workspace kit. This does not
reimplement anything: it points you at the one wizard that generates your
persona, `scripts/create-persona.sh` (or `.ps1` on Windows).

## What the persona wizard does

It stitches your identity header onto the fixed methodology canon and writes
three gitignored files under `persona/`:

- `persona.md` — your full persona (Codex installs this to `references/persona.md`)
- `CLAUDE.md` — the condensed version other tools use
- `recommended-skills.md` — which shipped skills to reach for first

It asks only about the identity header — discipline, seniority, workflow, then
role, stack, and tooling. The methodology canon (simplicity ladder, RFC/ADR
format, PR-review tiers, verification, git rules) is fixed and identical for
everyone. Press Enter to accept each default; `staff + fullstack +
architecture-focused` reproduces the shipped baseline.

## Steps

1. **Ask which shell the user is on** if it is not already obvious: a POSIX
   shell (macOS/Linux) or PowerShell (Windows). Do not assume.
2. **Give the exact command** for that shell (below), and let the user run it in
   their own terminal so the interactive prompts work.
3. **Point at the next step:** once the persona files exist, run the Codex
   installer (`codex/scripts/install.macos-linux.sh`, or the `.ps1` on Windows),
   which installs the filled `persona.md` into `$CODEX_HOME/references`.

### macOS / Linux (POSIX shell)

```bash
scripts/create-persona.sh             # interactive; Enter accepts each default
scripts/create-persona.sh --defaults  # accept everything, no prompts
```

### Windows (PowerShell)

```powershell
powershell -NoProfile -File .\scripts\create-persona.ps1
powershell -NoProfile -File .\scripts\create-persona.ps1 -Defaults
```

## Rules

- **Do not run the wizard or edit files yourself** unless the user explicitly
  asks. It is interactive and writes the user's personal files; hand over the
  command and let them drive.
- **Do not re-ask the wizard's questions here.** The wizard owns that flow; this
  skill only explains it and provides the command.
