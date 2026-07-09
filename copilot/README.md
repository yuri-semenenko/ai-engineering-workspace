# Copilot package

GitHub Copilot instructions for a locked-down corporate laptop. Markdown-only, copy-only, no hooks, no automation, no secrets. This is the package you can install where you do not control the machine.

## Layout

```
home/.copilot/
  copilot-instructions.md          personal collaboration + safety instructions
  instructions/
    architecture.instructions.md
    pr-review.instructions.md
    typescript-react-next.instructions.md
    writing-style.instructions.md
workspace-template/
  AGENTS.md                        repo-level agent guidance
  .github/
    copilot-instructions.md
    instructions/                   backend, frontend, performance, security
    prompts/                        14 prompts: start, rfc, adr, debug, module-design, testing, lazy, pr-*, humanize, ...
scripts/
  install.macos-linux.sh
  install.windows.ps1
SECURITY.md
PROMPT_FOR_COPILOT.md               bootstrap prompt to paste into Copilot
```

## Install

```bash
# personal instructions only:
scripts/install.macos-linux.sh

# personal instructions + a workspace template into a repo:
scripts/install.macos-linux.sh "$HOME" /path/to/your/repo
```

```powershell
powershell -NoProfile -File .\scripts\install.windows.ps1
powershell -NoProfile -File .\scripts\install.windows.ps1 -TargetHome $env:USERPROFILE
```

The installer copies Markdown instruction files into `~/.copilot` and, when a workspace path is given, the `.github/` instructions and prompts into that repo. Existing files are backed up before replacement. No auth, hooks, MCP config, or automation is ever touched.

Run `scripts/create-persona.sh` (repo root) first so the installer uses your filled `copilot-instructions.md` — personalized by seniority and stack. Copying `copilot/` standalone without the wizard falls back to the committed template, which still contains `{{PLACEHOLDERS}}`.

## Why it is deliberately limited

Copilot here assumes the strictest environment: managed laptop, execution-policy restrictions, no permission to install tooling or configure background agents. The instruction files reinforce that posture (do not bypass policy, do not exfiltrate data, prefer manual auditable steps). If you have full local control, the Claude Code package gives you far more leverage. See [`SECURITY.md`](SECURITY.md).
