---
name: debt-ledger
description: Collect the deliberate-simplicity tradeoff annotations left in the code (`// TRADEOFF(ceiling: ...; upgrade: ...): ...`) across the repo into a single ledger — location, ceiling, upgrade path, note. Use for "debt ledger", "list tradeoffs", "what shortcuts did we take", "debt-ledger". Pairs with the TRADEOFF convention in CLAUDE.md / persona and the annotations written by /lazy.
---

# Debt Ledger

Surface every deliberate, named tradeoff in the codebase so accepted debt stays visible instead of rotting as an anonymous `// TODO`.

## Convention being collected

The persona's tradeoff annotation (see CLAUDE.md):

```
// TRADEOFF(ceiling: <what this solution maxes out at>; upgrade: <path when the ceiling is hit>): <short note>
```

The comment marker varies by language (`//`, `#`, `--`, `<!-- -->`). Match the `TRADEOFF(` token, not the comment syntax.

## Steps

1. **Grep** the repo for the `TRADEOFF(` token across source files (respect `.gitignore`; skip vendored/`node_modules`).
2. **Parse** each hit into: file, line, ceiling, upgrade path, note.
3. **Flag malformed annotations** — a `TRADEOFF` that omits `ceiling:` or `upgrade:` is incomplete; list it under a separate "needs detail" group rather than silently dropping it.
4. **Report** as a single ledger.

## Output

```
TRADEOFF ledger — <N> entries (<M> need detail)
```

| Location (`file:line`) | Ceiling | Upgrade path | Note |
|---|---|---|---|

Then a "needs detail" list for malformed entries. Do not editorialize or auto-fix — this is a read-only inventory. If zero annotations exist, say so plainly (it may mean the convention is not being used, not that there's no debt).
