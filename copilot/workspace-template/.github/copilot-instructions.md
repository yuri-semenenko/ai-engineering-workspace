# Repository Copilot Instructions

Follow `AGENTS.md` at the repository root — it is the canonical policy for AI assistants in this repository.

For surfaces that cannot read `AGENTS.md`, the essentials:

- Read existing code before proposing changes. Keep edits scoped and reversible; do not refactor unrelated code.
- When the repo is silent, default to TypeScript, React, Next.js, Node.js, PostgreSQL, Vitest and React Testing Library.
- Before claiming a change is complete, run the narrowest useful checks (typecheck, lint, targeted tests). If a check cannot run, state why and what risk remains.
- Do not print secrets, run destructive commands, or alter machine/global configuration without explicit approval.
