---
name: lazy
description: Apply the "laziest solution that actually works" enforcement ladder when writing or proposing code — question whether the work needs to exist (YAGNI), reach for stdlib / native platform / already-installed deps before custom code, prefer one line over fifty. Supports intensity lite | full (default) | ultra. Use when implementing a feature, scaffolding, or whenever the user wants the minimal viable change ("the lazy way", "minimal diff", "do the least that works"). Different from /simplify (which cleans up an existing diff after the fact) — /lazy runs the ladder before the code is written. Aligned to the persona's simplicity bias.
argument-hint: "[lite|full|ultra]"
---

# Lazy

Force the simplest, shortest, most minimal solution that still satisfies the requirement. The best code is the code you never wrote. This operationalizes the persona's "Simplicity wins" / anti-over-engineering bias into a concrete decision ladder applied *before* generating code.

## Decision ladder (stop at the first rung that works)

1. **Does it need to exist?** Can the requirement be dropped, deferred, or met by an existing path? (YAGNI)
2. **Standard library** — does the language stdlib already solve it?
3. **Native platform** — browser API, DB constraint, OS tool, framework primitive?
4. **Already-installed dependency** — reuse what the repo already pulls in; do not add a new dep for a few lines.
5. **One-liner** — can it be a single expression?
6. **Minimal implementation** — only now write the smallest working version.

## Rationalizations

Pre-written rebuttals to the excuses that precede over-building. If you catch yourself thinking the left column, the right column is the answer.

| Rationalization | Rebuttal |
|---|---|
| "We'll need this flexibility later." | YAGNI. Build it when later arrives — you'll know the real shape then. |
| "An abstraction makes this cleaner." | Two call sites don't justify a layer. Inline until the third forces the shape. |
| "A small dependency is easier than writing it." | A dep is a supply-chain and upgrade liability. For a few lines, the stdlib rung wins. |
| "This is the idiomatic / enterprise pattern." | Patterns serve problems, not vice versa. Name the problem this one solves here. |
| "It's only a few extra lines." | Every line is maintenance. The default is zero; each line must earn its place. |

## Intensity

- **lite** — build it as asked; mention the lazier path in one line, do not enforce.
- **full (default)** — enforce the ladder strictly; ship the shortest correct diff; reject speculative abstractions and boilerplate.
- **ultra** — YAGNI extremist: challenge whether the task should exist at all before writing anything, then ship the absolute minimum. Push back on requirements that smell speculative.

## Rules

- Code-first, explanation brief. If the explanation is longer than the code, that usually signals hidden complexity — reconsider.
- **Never simplify away** validation, error handling, security, accessibility, or an explicitly requested feature. Laziness is about *avoiding work*, not *cutting corners that matter*.
- When you deliberately ship a simpler-than-ideal solution, mark it with the persona's tradeoff convention so it is greppable later:
  `// TRADEOFF(ceiling: <what this maxes out at>; upgrade: <path when the ceiling is hit>): <note>`
  These are collected by `/debt-ledger`.
- For non-trivial logic, include one runnable self-check (test, assertion, or example) — minimal does not mean unverified.
- Prefer deleting code over adding it. A diff that removes lines is the laziest win of all.
