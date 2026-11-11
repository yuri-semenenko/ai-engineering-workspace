---
name: pr-review
description: Use when reviewing a PR, triaging code-review feedback, or deciding what is worth commenting on. Classifies every finding as Critical, Important, or Optional and ends with a verdict. The follow-up pass after fixes is pr-recheck.
---

# PR Review

Lead with findings. Use English for GitHub markdown unless the user explicitly asks otherwise.

## Classification

- **Critical** — correctness, security, reliability, data loss, auth bypass, broken happy path, severe regression, two writers racing on one piece of state, a step that corrupts data when retried after a partial failure.
- **Important** — maintainability, scalability, readability, missing tests for non-trivial logic, misleading boundaries, outside data passed inward without being parsed at its trust boundary.
- **Optional** — style or preference only when ignoring it has a real cost. Drop pure nitpicks.

## Rules

- Verify PR scope with `gh pr view`, PR URL/number, or `git diff <base>...HEAD`.
- Read the tests and PR description first to recover intended behavior, then read the implementation against that intent.
- Read enough surrounding code to validate each finding.
- Cite `path:line` for every issue, and name the input or sequence that triggers it and what breaks.
- Order by severity, not by file.
- Classification is severity, not certainty: when unsure a finding is real, phrase it as a question, not an assertion, and do not inflate a Critical you cannot fully trace.
- End with verdict: approve, request changes, or needs discussion.
- Posting to GitHub is a separate, opt-in step. Draft the inline comments, show them, and post only after the user explicitly confirms. When the review format cannot carry Optional findings, draft the follow-up comment that will with the rest, so the same confirmation covers it. A confirmation covers what it names: post all named drafts, including the follow-up, without asking again; if the user selects some, post only those. Draft and confirm a later finding on its own. An explicit instruction earlier in the conversation to post this review's comments is that confirmation; do not ask twice. Write posted comments as conversational English prose without arrows, tildes, or em dashes, run them through the humanizer skill, and anchor each to a `path:line`. Approving the PR and posting comments are separate yeses; neither implies the other.

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
