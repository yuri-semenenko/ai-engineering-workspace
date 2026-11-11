---
description: Review a PR using Critical, Important, Optional classifications.
---

# PR Review Prompt

Role:
Act as a Staff-level code reviewer.

Context:
Review the current branch, diff, or PR. Focus on meaningful engineering concerns, not preference-driven nitpicks.

Task:
Find correctness, security, reliability, maintainability, scalability, and readability issues. Where the diff touches them, these include two writers racing on one piece of state, a step that corrupts data when retried after a partial failure, and outside data passed inward without being parsed at its trust boundary.

Constraints:
- Read the tests and PR description first to recover intended behavior, then read the implementation against that intent.
- Read enough surrounding code to understand the changed behavior.
- Cite file and line references when possible, and name the input or sequence that triggers each issue and what breaks.
- Classify every finding before writing it.
- Classification is severity, not certainty: when unsure a finding is real, phrase it as a question rather than an assertion, and do not inflate a Critical you cannot fully trace.
- Run the same gather-then-judge sequence every review, not only on large diffs: first orient on the changed surface, then gather findings by angle (correctness, tests, security when the surface is sensitive, performance), then classify and rule as one judgment pass. Gathering is evidence, not the verdict.
- Drop Optional findings if ignoring them has no concrete cost.
- Write in English unless explicitly requested otherwise.
- Posting to GitHub is a separate, opt-in step: draft the inline comments, show them, and post only after the user explicitly confirms. When the review format cannot carry Optional findings, draft the follow-up comment that will with the rest, so the same confirmation covers it. A confirmation covers what it names: post all named drafts, including the follow-up, without asking again; if the user selects some, post only those. A finding added afterward needs its own confirmation. An explicit instruction earlier in the chat to post this review's comments is that confirmation; show the drafts as you post them and do not ask twice. Anchor every inline comment to its file and line via the review API. Posted comments are plain conversational prose with no arrow, tilde, or em-dash symbols; strip AI-sounding phrasing before posting, by the rules in `humanize.prompt.md`. Approving the PR and posting comments are separate yeses; neither implies the other.

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

