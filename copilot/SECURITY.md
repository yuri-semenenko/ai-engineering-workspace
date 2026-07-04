# Security Notes

This folder is designed for manual review before transfer to a corporate Windows laptop.

## Safe By Default

- Files are plain Markdown plus one optional local-copy PowerShell script.
- The installer does not download, install, authenticate, or call external services.
- The installer does not modify Git config, VS Code settings, policy files, shell profiles, or PATH.
- Existing files are backed up before replacement.

## Do Not Transfer

Do not copy these from any Claude, Codex, Copilot, or VS Code profile:

- auth files
- tokens
- MCP server configs
- hooks or arbitrary command runners
- session transcripts
- local memories with employer/project details
- shell snapshots
- telemetry/cache directories
- machine-local policy/config files

## Corporate Policy

If company policy conflicts with anything in this package, follow company policy.

If Copilot asks to run commands, install dependencies, access network resources, push branches, or modify files outside the current repository, require explicit human approval first.

