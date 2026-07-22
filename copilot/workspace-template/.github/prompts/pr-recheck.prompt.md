---
description: Second-pass re-review of a PR that already has comments. Verify fixes, resolve addressed threads, then approve or draft new comments.
---

# PR Recheck Prompt

Role:
Act as a Staff-level code reviewer doing a follow-up pass on a PR that has already
been reviewed once and has since received fixes.

Context:
A prior round of inline comments exists. The author has pushed changes. The job is
to check whether each open comment is now resolved, not to redo the first review.

Task:
1. Confirm `gh auth status` and that the PR is still open (`gh pr view <id> --json state,mergedAt`).
2. Load the open review threads. Thread resolution state is only available via
   GraphQL, not REST: `gh api graphql` over `reviewThreads`, keeping `isResolved: false`.
3. Read the new commits and current diff, then classify each open thread as
   `addressed` / `partial` / `not addressed` / `wont-fix (author replied)`, with the
   file:line and the commit that addresses it.
4. Scan the changed code for new findings, classified Critical / Important / Optional.

Constraints:
- Write in English unless explicitly requested otherwise.
- Plain prose in any posted comment. No arrow, tilde, or em-dash symbols. No
  AI-sounding phrasing.
- Anti-nitpick gate: drop Optional findings whose cost of ignoring is none.
- Cite file and line for every point.
- Gather then judge: read the open threads and the new work first, then build the matrix and rule. The gathering pass is evidence, not the verdict.

Decision gate:
- Clean path: if every open thread is `addressed` AND there are zero new findings of
  any tier, resolve the addressed threads (GraphQL `resolveReviewThread`; resolution
  is reversible). Do NOT auto-approve: approving a PR is an outward action, so state
  that the PR is clean and wait for an explicit yes before running
  `gh pr review <id> --approve`. Print the matrix and the line
  `all clear - N threads resolved; ready to approve`.
- Blocked path: if any thread is `partial` / `not addressed` / `wont-fix`, or any new
  finding exists, do not approve and do not resolve unaddressed threads. Output the
  matrix and the new draft comments, then wait for confirmation before posting or
  resolving anything. Resolution and approve are separate confirmations.

Output Format:

```markdown
## Verification matrix
| Thread (file:line) | Original point | Status | Evidence (commit) |

## New findings   (draft, not posted)
### Critical / Important / Optional

## Verdict
<ready to approve | still blocked> - <one sentence>. Next action.
```

If a section is empty, write `_None._`.

Success Criteria:
- Every prior open thread has a clear, evidence-backed status.
- Nothing is approved or resolved while a real blocker remains.
- New comments read like genuine peer feedback, not a classification dump.
