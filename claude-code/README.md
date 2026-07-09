# Claude Code package

The canon of the kit. Skills, agents, hooks, and the persona all originate here; the Codex mirror is generated from it.

## Layout

```
.claude/
  skills/               17 process skills + a /start onboarding entrypoint (see the root README catalog)
  agents/
    project-agent.template.md   how-to template for a project-specific agent
  hooks/
    model-reminder.sh    UserPromptSubmit hook
  memory-seed.example/   fictional example memories (format demo; also the sync canon)
  settings.example.json  permissions + 5 hooks (no model pin / theme / plugins)
  statusline.sh          model · branch · dir status line
scripts/
  install.macos-linux.sh
  install.windows.ps1
```

## Install

```bash
scripts/install.macos-linux.sh
```

```powershell
powershell -NoProfile -File .\scripts\install.windows.ps1            # Copy mode (default)
powershell -NoProfile -File .\scripts\install.windows.ps1 -Mode Symlink
```

The installer:

1. Runs `scripts/create-persona.sh` if you have no persona yet (prompts, or defaults when non-interactive).
2. Symlinks `.claude` to `~/.claude` (Copy mode on Windows when symlinks are not permitted), backing up any existing config.
3. Provisions `~/.claude/CLAUDE.md`, `~/persona.md`, and `~/.claude/settings.json` (seeded from the example on first run).

`CLAUDE.md`, `persona.md`, and `settings.json` are gitignored — they are yours, not the repo's.

## Customizing

- **Agents:** copy `agents/project-agent.template.md`, rename it, fill the placeholders. One agent per project encodes that project's stack, conventions, and quality gate.
- **Memory:** replace `memory-seed.example/` with your own memories or delete it. Note it is also the sync canon for the Codex mirror — run `scripts/sync-codex-references.sh` after editing.
- **Permissions/hooks:** edit `settings.example.json` for the shipped defaults, or your local `settings.json` for machine-specific tweaks. See [`../docs/hardening.md`](../docs/hardening.md).
