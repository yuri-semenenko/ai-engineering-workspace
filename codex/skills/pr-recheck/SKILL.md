---
name: pr-recheck
description: Use for a second pass on a PR that already has review comments and new commits since. Marks each open thread addressed, partial, or not addressed, then either clears the PR or drafts new comments. The first-pass review is pr-classify.
---

# PR Recheck

Follow-up pass on a PR that has already been reviewed once. Assumes a prior round of inline comments exists and the author has pushed fixes since.

## Preconditions

Run `gh auth status`. Require a PR number or URL, or a checked-out branch with an open PR, and verify open state with `gh pr view <id> --json state,mergedAt`. If it is merged or closed, surface that and stop.

## Steps

1. **Load prior threads.** Fetch review threads through the GraphQL API; REST does not expose thread resolution state. Keep only the threads where `isResolved` is false.
2. **Load new work.** Get the diff and the commits since the previous review, then read the new code against the files it touches.
3. **Build the verification matrix.** Classify each open thread as `addressed`, `partial`, `not addressed`, or `wont-fix (author replied)`, each with a `path:line` and the commit that addresses it.
4. **Scan for new findings.** Re-reading changed code surfaces fresh issues. Classify them Critical, Important, or Optional per pr-classify, including its rule that a pure nitpick is dropped.

## Decision Gate

**Clear.** Only when every prior thread is `addressed` and there are zero new findings of any tier: resolve the addressed threads, print the matrix, and state that the PR is ready to approve. Do not approve. Approving is an outward action and needs an explicit yes first.

**Blocked.** If any thread is `partial`, `not addressed`, or `wont-fix`, or any new finding exists: do not approve, and do not resolve the threads that are not addressed. Output the matrix and the draft comments, then stop and wait.

Resolving threads, posting comments, and approving are three separate confirmations. Never bundle them into one yes.

## Posting

New inline comments follow the pr-classify rules and are drafted before they are posted. Write them as conversational English prose, without arrows, tildes, or em dashes, and run them through the humanizer skill first. Anchor each one to a `path:line`.

## Delegation

Delegate the gather, keep the judgment. Steps 1 and 2 go to a cheaper-tier subagent returning compact evidence: the unresolved threads, and what changed since the last review with `path:line`. The addressed and not-addressed matrix, the new-findings classification, and the decision gate stay on the main model. Resolving, posting, and approving are gated actions and are never delegated.

## Output

```markdown
## Verification matrix
| Thread (path:line) | Original point | Status | Evidence (commit) |

## New findings (draft, not posted)
### Critical / Important / Optional

## Verdict
<cleared | still blocked> — <one sentence>. Next action.
```

Write `_None._` for an empty section rather than dropping the heading.
