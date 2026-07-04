---
name: TypeScript React Next.js Standards
description: Default engineering standards for TypeScript, React, Next.js, Node.js, and tests.
applyTo: "**/*.ts,**/*.tsx,**/*.js,**/*.jsx"
---

# TypeScript, React, And Next.js Standards

Follow existing repository conventions first. These defaults apply only when the repo is silent.

## TypeScript

- Prefer strict types, discriminated unions, type guards, and explicit domain types.
- Avoid `any` unless there is a clear boundary or migration reason.
- Keep data flow explicit.
- Prefer pure functions and small composable modules.

## React

- Use functional components and hooks.
- Keep components focused.
- Extract reusable behavior into hooks only when it removes real duplication or complexity.
- Handle loading, error, and empty states.
- Preserve accessibility basics: semantic HTML, labels, keyboard behavior, and ARIA only when needed.

## Next.js

- Match the router and data-fetching style already used by the repo.
- Keep server/client boundaries explicit.
- Avoid adding client state when server data or URL state is sufficient.
- Do not introduce new framework patterns without local precedent or clear value.

## Testing

- Prefer Vitest and React Testing Library when the repo is silent.
- Add focused tests for non-trivial logic, edge cases, and regressions.
- Avoid brittle implementation-detail tests.

## Verification

Before claiming completion, run the most relevant checks available in the repo, such as typecheck, lint, unit tests, or targeted test files. If verification cannot run, state what was not run and why.

