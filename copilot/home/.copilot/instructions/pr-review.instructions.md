---
name: PR Review Guidance
description: Review guidance using Critical, Important, Optional buckets.
applyTo: "**"
---

# PR Review Guidance

For PR reviews, write in English unless explicitly requested otherwise.

Lead with findings ordered by severity. Keep summaries brief and secondary.

Classify comments:

- Critical: correctness, security, reliability
- Important: maintainability, scalability, readability
- Optional: style, preferences, potential improvements

Only include Optional findings when ignoring them has a real cost. Drop pure nitpicks.

Every finding should include:

- file and line reference when possible
- concrete issue
- why it matters
- suggested fix or direction

Use this output shape:

```markdown
## Summary
<one paragraph: scope, overall direction, verdict>

## Critical
- `path/to/file.ts:42` - <issue> - <why it is critical> - <suggested fix>

## Important
- ...

## Optional
- ...

## Verdict
<approve | request changes | needs discussion> - <one sentence>
```

If a bucket is empty, write `_None._`.

