---
name: pull-request-workflow
description: Use when reviewing a PR, drafting PR feedback, classifying code-review comments, preparing a pull-request description, or creating copy-pasteable GitHub PR markdown.
---

# Pull Request Workflow

Support two related jobs: reviewing PRs and drafting PR descriptions. Use English for GitHub markdown unless the user explicitly asks otherwise.

## PR Review

Lead with findings. Classify every meaningful comment:

- **Critical** — correctness, security, reliability, data loss, auth bypass, broken happy path, severe regression.
- **Important** — maintainability, scalability, readability, missing tests for non-trivial logic, misleading boundaries.
- **Optional** — style or preference only when ignoring it has a real cost. Drop pure nitpicks.

Rules:

- Verify PR scope with `gh pr view`, PR URL/number, or `git diff <base>...HEAD`.
- Read the tests and PR description first to recover intended behavior, then read the implementation against that intent.
- Read enough surrounding code to validate each finding.
- Cite `path:line` for every issue.
- Order by severity, not by file.
- Classification is severity, not certainty: when unsure a finding is real, phrase it as a question, not an assertion, and do not inflate a Critical you cannot fully trace.
- End with verdict: approve, request changes, or needs discussion.

Format:

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

## Review Loop

For non-trivial PRs or when the user asks for a deeper pass, run the review as a loop:

1. Establish scope from the PR, issue, branch name, template, and diff.
2. Inspect from independent angles: correctness/regression risk, tests/validation, maintainability, and security/performance only when the diff touches those surfaces.
3. Merge findings into one ordered review. Do not duplicate comments across angles.
4. Split feedback into fixes worth doing now, optional improvements, and items to defer or ignore with a short reason.
5. If the user asks for `autofix`, apply only fixes worth doing now, then rerun targeted verification and inspect the final diff.

Do not blindly apply every review suggestion. If a finding depends on an unapproved product, scope, or architecture decision, pause and ask for that decision instead of coding around it.

## PR Description

When drafting the PR body:

- Mirror the repo's PR template if present.
- Inspect `git diff --stat HEAD` and the actual diff.
- Derive ticket keys from branch names when obvious.
- Include concrete, runnable test steps.
- For UI work, include a placeholder for screenshot or recording evidence.

Output the body as one raw markdown fenced block so it can be pasted into GitHub.
