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
  AGENTS.md                        repository contract (tool-agnostic)
  CLAUDE.md                        imports AGENTS.md for Claude Code
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

`AGENTS.md` is the repository contract and the file that holds the repository's facts: Copilot, Codex, and Gemini CLI read it directly, and `CLAUDE.md` is a one-line `@AGENTS.md` import because Claude Code does not read `AGENTS.md`. `.github/copilot-instructions.md` carries only the Copilot delta — a pointer to the contract, a note on the `applyTo` mechanism, and what to do on the few Copilot surfaces that read repository-wide instructions but not agent instructions. Copilot CLI *combines* every applicable instruction file and [defines no precedence between them](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions), so duplicating the contract here would create a second copy to keep in sync, not a safety net. Stack preferences stay personal, in your own `~/.copilot/copilot-instructions.md`, which this package installs from the persona wizard.

The template ships as placeholders on purpose. Fill them from `package.json`, workspace config, or CI before committing it, or use the `$project-onboarding` Codex skill to do it from repository evidence.

### Which Copilot surfaces get the repository contract

"Copilot" is not one product, and the surfaces do not discover the same files. This package targets **Copilot CLI** and **VS Code Copilot Chat** — the two named in [`PROMPT_FOR_COPILOT.md`](./PROMPT_FOR_COPILOT.md) — and both read `AGENTS.md`. Everything else is documented degraded compatibility rather than claimed support.

| Surface | Reads `AGENTS.md` | Reads `.github/copilot-instructions.md` | Effective mode |
| --- | :---: | :---: | --- |
| Copilot CLI | yes | yes | **Full** — primary target |
| VS Code Copilot Chat / agent mode | yes | yes | **Full** — primary target |
| Copilot cloud coding agent | yes | yes | Full, but not a target of this package |
| GitHub.com Copilot Chat | no | yes | Degraded |
| JetBrains and Visual Studio Chat | no | yes | Degraded |
| Eclipse and Xcode Chat | no | yes | Degraded |
| Copilot code review | only on GitHub.com | yes | Degraded |

Verified against [response customization](https://docs.github.com/en/copilot/concepts/prompting/response-customization), the [per-client support reference](https://docs.github.com/en/copilot/reference/custom-instructions-support), and the [CLI instructions page](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions).

Degraded means the contract is invisible to that surface and `.github/copilot-instructions.md` is all it receives. That file therefore tells it to open `AGENTS.md` explicitly and not to guess at a stack — a pointer, not a second copy of the contract. Duplicating the contract there would create two editable copies of the same repository facts for every target repository, which costs more than the degradation.

## Install

```bash
# personal instructions only:
scripts/install.macos-linux.sh

# personal instructions + a workspace template into a repo:
scripts/install.macos-linux.sh "$HOME" /path/to/your/repo
```

```powershell
# personal instructions only:
powershell -NoProfile -File .\scripts\install.windows.ps1

# personal instructions + a workspace template into a repo:
powershell -NoProfile -File .\scripts\install.windows.ps1 -TargetHome $env:USERPROFILE -WorkspacePath C:\path\to\your\repo
```

The installer copies Markdown instruction files into `~/.copilot` and, when a workspace path is given, the `.github/` instructions and prompts into that repo. Existing files are backed up before replacement. No auth, hooks, MCP config, or automation is ever touched.

Run `scripts/create-persona.sh` (repo root) first so the installer uses your filled `copilot-instructions.md` — personalized by seniority and stack. Copying `copilot/` standalone without the wizard falls back to the committed template, which still contains `{{PLACEHOLDERS}}`. The summary closes with a `Persona:` line naming the source it used and reporting that case as `TEMPLATE ONLY`, and it names the repository-level half whenever no workspace path was given.

## Why it is deliberately limited

Copilot here assumes the strictest environment: managed laptop, execution-policy restrictions, no permission to install tooling or configure background agents. The instruction files reinforce that posture (do not bypass policy, do not exfiltrate data, prefer manual auditable steps). If you have full local control, the Claude Code package gives you far more leverage. See [`SECURITY.md`](SECURITY.md).
