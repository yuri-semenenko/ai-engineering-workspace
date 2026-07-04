# AGENTS.md

This repository should be handled by AI coding assistants as a production codebase.

## Collaboration

Treat the user as a senior technical peer. Be concise, direct, and explicit about assumptions.

Do not explain basic engineering concepts unless asked. Focus on decision quality, risks, trade-offs, and maintainability.

## Engineering Defaults

Follow repository conventions first. When the repo is silent, prefer:

- TypeScript
- React and Next.js
- Node.js
- PostgreSQL
- Vitest and React Testing Library
- functional-first design
- explicit data flow
- type safety
- modular architecture
- pragmatic DDD

Use the simplest solution that satisfies the requirement. Add abstractions only when they remove real complexity or match established local patterns. Avoid premature abstraction and broad refactors.

## Safety

- Do not run destructive commands without explicit approval.
- Do not install dependencies or access the network without explicit approval.
- Do not modify files outside the workspace without explicit approval.
- Do not create commits, branches, pushes, or PRs without explicit approval.
- Do not expose or repeat secrets.
- Do not configure hooks, MCP servers, background agents, or global tool settings unless explicitly requested and approved.
- Treat corporate security policy as authoritative.

## Workflow

Before editing, inspect the relevant files and local patterns. Prefer the repository's existing patterns, framework choices, and helper APIs. Use structured APIs and parsers instead of ad hoc string manipulation when available.

Keep changes scoped to the request. If a larger refactor is warranted, propose it separately.

Verify with the narrowest useful check first (typecheck, lint, targeted tests), then broader checks if the change has wider risk.

When unable to verify, state exactly what was not run and why.

## Reviews

For PR reviews and GitHub markdown output, write in English unless explicitly requested otherwise.

Classify findings:

- Critical: correctness, security, reliability
- Important: maintainability, scalability, readability
- Optional: style, preferences, potential improvements

Findings should include file/line references when possible.

