---
name: pr-classify
description: Use when reviewing a PR, triaging code-review feedback, or deciding what is worth commenting on. Classifies every finding as Critical, Important, or Optional and ends with a verdict. The follow-up pass after fixes is pr-recheck.
---

# PR Classify

Lead with findings. Use English for GitHub markdown unless the user explicitly asks otherwise.

## Classification

- **Critical** — correctness, security, reliability, data loss, auth bypass, broken happy path, severe regression.
- **Important** — maintainability, scalability, readability, missing tests for non-trivial logic, misleading boundaries.
- **Optional** — style or preference only when ignoring it has a real cost. Drop pure nitpicks.

## Rules

- Verify PR scope with `gh pr view`, PR URL/number, or `git diff <base>...HEAD`.
- Read the tests and PR description first to recover intended behavior, then read the implementation against that intent.
- Read enough surrounding code to validate each finding.
- Cite `path:line` for every issue.
- Order by severity, not by file.
- Classification is severity, not certainty: when unsure a finding is real, phrase it as a question, not an assertion, and do not inflate a Critical you cannot fully trace.
- End with verdict: approve, request changes, or needs discussion.

## Review Loop

For non-trivial PRs or when the user asks for a deeper pass:

1. Establish scope from the PR, issue, branch name, template, and diff.
2. Inspect from independent angles: correctness/regression risk, tests/validation, maintainability, and security/performance only when the diff touches those surfaces.
3. Merge findings into one ordered review. Do not duplicate comments across angles.
4. Split feedback into fixes worth doing now, optional improvements, and items to defer or ignore with a short reason.
5. If the user asks for `autofix`, apply only fixes worth doing now, then rerun targeted verification and inspect the final diff.

Do not blindly apply every review suggestion. If a finding depends on an unapproved product, scope, or architecture decision, pause and ask for that decision instead of coding around it.

## Delegation

Delegate the reading, keep the ruling. Run the same sequence every review, not only on large diffs: a cheaper-tier subagent orients on the changed surface, subagents gather by angle (correctness, tests, security when the surface is sensitive, performance) returning compact findings with `path:line`, and classification plus the verdict stay on the main model. A subagent finding is evidence, not a ruling.

## Output

```markdown
## Summary
<scope and verdict>

## Critical
- `path/to/file.ts:42` — <issue> — <impact> — <suggested fix>

## Important
_None._

## Optional
_None._

## Verdict
<approve | request changes | needs discussion> — <one sentence>
```

Write `_None._` for an empty section rather than dropping the heading. For the PR body itself, use pr-comment.
