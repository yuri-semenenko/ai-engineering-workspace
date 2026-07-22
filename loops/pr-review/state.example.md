# PR Review state example

This is an example only. Store actual state under the consuming project's
`.ai-workspace/loops/pr-review/` directory and normally gitignore it.

```markdown
# PR Review state

- **Loop version:** `1.0.0`
- **PR identifier:** `owner/repository#123`
- **Last inspected commit:** `abc1234`
- **Last run timestamp:** `2026-07-22T10:30:00Z`

## Previous findings

- Important | `src/example.ts:42` | Evidence summary

## Resolved findings

- Important | `src/example.ts:42` | Resolved in `def5678`

## Human overrides

- Accepted risk: <reason and owner>

## Pending verification

- CI run <identifier> is unavailable
```

Prune resolved entries after their retention period, but preserve human overrides.
