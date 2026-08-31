# Repository Copilot Instructions

`AGENTS.md` at the repository root is this repository's contract and the canonical policy for every AI assistant here. Read it first. This file holds only what is specific to Copilot and must not restate the contract.

Copilot CLI and VS Code Copilot Chat both read `AGENTS.md` and combine it with this file rather than choosing between them, so anything repeated here is a second copy to keep in sync. Repository facts — stack, commands, architecture invariants, definition of done, safety boundaries — belong in `AGENTS.md`. Personal preferences, including which stack to assume when this repository is silent, belong in your own `~/.copilot/copilot-instructions.md`.

Copilot-specific notes:

- Path-scoped guidance lives in `.github/instructions/*.instructions.md`, selected by each file's `applyTo` globs. That mechanism is Copilot-only; the cross-tool equivalent is a nested `AGENTS.md` in the directory whose rules differ.
- A few Copilot surfaces read this file but not `AGENTS.md` — GitHub.com Copilot Chat is one. On such a surface, open `AGENTS.md` explicitly before assuming anything about this repository's stack, commands, or boundaries. Do not guess, and do not fall back to a generic stack.
