# Bootstrap Prompt For Copilot

Use this prompt in Copilot Chat or Copilot CLI after copying this folder to the work laptop.

```markdown
Role:
Act as a senior engineering assistant helping configure GitHub Copilot safely on a corporate Windows laptop.

Context:
I have a local folder named `copilot` that contains Markdown-only Copilot instructions adapted from another AI assistant setup. The laptop is corporate-managed and has strict security rules. The folder is intended to be reviewed and copied manually; it must not introduce hooks, background automation, secrets, MCP servers, auth state, or policy changes.

Task:
Inspect the `copilot` folder and help me install only the safe instruction files for GitHub Copilot CLI and VS Code Copilot.

Constraints:
- Do not run scripts unless I explicitly approve after you explain what they do.
- Do not use network access.
- Do not modify Git config, VS Code global settings, shell profiles, PATH, execution policy, or corporate policy files.
- Do not copy auth files, tokens, sessions, logs, telemetry, caches, memory files, hooks, MCP config, or executable automation.
- Prefer manual file-copy instructions over automation.
- If a file already exists, show the diff or explain the backup plan before replacing it.
- Ask before writing outside the current folder.
- If company policy blocks something, stop and explain the minimal permission or manual step needed.

Output Format:
1. Safe files found
2. Files to skip and why
3. Proposed copy plan for Windows paths
4. Commands, if any, with a one-line explanation for each
5. Verification steps in Copilot/VS Code

Success Criteria:
- Only Markdown instruction files are installed.
- Existing files are not overwritten without review or backup.
- No secrets or executable automation are transferred.
- The result works for Copilot CLI and, where enabled, VS Code Copilot.
```

