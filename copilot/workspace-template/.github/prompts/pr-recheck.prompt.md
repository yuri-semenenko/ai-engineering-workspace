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
3. Read the new commits and current diff, then record three separate things for
   each open thread, with the file:line and the commit that addresses it:
   - Severity, from the first review: Critical / Important / Optional. When the
     thread does not state it, classify it from what it describes and mark the
     severity as inferred.
   - Status: `addressed` / `partial` / `not addressed` /
     `wont-fix (author replied)`. A `wont-fix` reply is the author's position,
     not the reviewer's acceptance.
   - Blocks approval: `yes`, `no`, or `no (accepted risk)`. A Critical or
     Important thread blocks unless it is `addressed` or its risk is accepted. An
     Optional thread does not block.

   Accepting a risk is a decision about what remains, recorded with its reason:
   why the risk is small, where it is mitigated, or the follow-up ticket. On a
   Critical or Important item, thread or new finding alike, the decision is the
   user's: propose it with the reason, keep the item blocking, and mark it
   `no (accepted risk)` only after the user says yes. Record the agreed reason as a
   drafted reply on the thread, posted on confirmation like any comment.

   `addressed` means the scenario the
   thread described no longer happens, not that the cited line changed; a regression
   test added for it counts only if it would fail without the fix. Read it against
   the fix, or, when that is cheap, run it with the fix taken out in an isolated
   copy of the PR head (a scratch copy or `git worktree add --detach`, never your
   working tree or the PR branch, nothing committed or pushed). When that cannot
   be done safely, or the run errors or times out, say the failure was read, not
   observed.
4. Scan the changed code for new findings, classified Critical / Important / Optional,
   including regressions the fix itself introduced on adjacent paths. A new Critical
   or Important finding blocks approval unless its risk is accepted the same way;
   a new Optional one does not.

Constraints:
- Write in English unless explicitly requested otherwise.
- Plain prose in any posted comment. No arrow, tilde, or em-dash symbols. No
  AI-sounding phrasing.
- Anti-nitpick gate: drop Optional findings whose cost of ignoring is none.
- Cite file and line for every point.
- Gather then judge: read the open threads and the new work first, then build the matrix and rule. The gathering pass is evidence, not the verdict.

Decision gate:
- Clean path: if nothing blocks approval (no thread and no new finding is marked
  `yes` in steps 3 and 4), resolve the `addressed` threads (GraphQL
  `resolveReviewThread`; resolution is reversible) and leave every other thread
  open. Open Optional threads and new Optional findings do not change this path;
  list them as non-blocking, with any new ones drafted as comments. Do NOT
  auto-approve: approving a PR is an outward action, so state that the PR is clean
  and wait for an explicit yes before running `gh pr review <id> --approve`.
  Show the non-blocking drafts with that question: approving and posting them are
  separate yeses, and an approval alone posts nothing. Print the matrix and the
  line `all clear - N threads resolved, M non-blocking items open; ready to approve`.
- Blocked path: otherwise, when anything blocks approval, do not approve and do
  not resolve unaddressed threads. Output the matrix, the new draft comments, and
  any proposed risk acceptance with its reason, then wait for confirmation before posting or
  resolving anything. Resolution and approve are separate confirmations. A
  confirmation covers the drafts it names; a finding added after it is confirmed
  on its own. An explicit instruction earlier in the chat to post this recheck's
  comments is that confirmation; do not ask for it twice.

Output Format:

```markdown
## Verification matrix
| Thread (file:line) | Severity | Original point | Status | Blocks approval | Evidence (commit) |

## New findings   (draft, not posted)
### Critical / Important (blocking) / Optional (non-blocking)

## Verdict
<ready to approve | still blocked> - <one sentence>. Next action.
```

If a section is empty, write `_None._`.

Success Criteria:
- Every prior open thread has a clear, evidence-backed status.
- Nothing is approved or resolved while a real blocker remains, and no risk is
  marked accepted on the author's word alone.
- New comments read like genuine peer feedback, not a classification dump.
