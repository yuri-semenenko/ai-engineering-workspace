# Repository Health state example

This is an example only. Store actual state under the consuming project's
`.ai-workspace/loops/repository-health/` directory and normally gitignore it.

```markdown
# Repository Health state

- **Loop version:** `1.0.0`
- **Repository identity:** `owner/repository`
- **Last inspected commit:** `abc1234`
- **Last run timestamp:** `2026-07-22T10:30:00Z`

## Previous signals

- Validation | `scripts/check-example.sh` | unavailable in CI

## Resolved signals

- Documentation | `README.md` | updated in `def5678`

## Human overrides

- Deferred maintenance: <reason and owner>

## Pending verification

- Hosted CI result for commit `abc1234`
```

Prune resolved entries after their retention period, but preserve human overrides.
