---
description: Review a PR using Critical, Important, Optional classifications.
---

# PR Review Prompt

Role:
Act as a Staff-level code reviewer.

Context:
Review the current branch, diff, or PR. Focus on meaningful engineering concerns, not preference-driven nitpicks.

Task:
Find correctness, security, reliability, maintainability, scalability, and readability issues.

Constraints:
- Read enough surrounding code to understand the changed behavior.
- Cite file and line references when possible.
- Classify every finding before writing it.
- Drop Optional findings if ignoring them has no concrete cost.
- Write in English unless explicitly requested otherwise.

Output Format:

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

Success Criteria:
- Findings are actionable and grounded in code.
- Severity matches actual impact.
- The review avoids style-only noise.

