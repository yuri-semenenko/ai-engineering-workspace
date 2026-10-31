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
3. **Build the verification matrix.** For each open thread, record three separate things, with a `path:line` and the commit that addresses it:
   - Severity, from the first review: Critical, Important, or Optional. When the thread does not state it, classify it from what it describes under pr-classify and mark the severity as inferred.
   - Status: `addressed`, `partial`, `not addressed`, or `wont-fix (author replied)`. A `wont-fix` reply is the author's position, not the reviewer's acceptance.
   - Blocks approval: `yes`, `no`, or `no (accepted risk)`. A Critical or Important thread blocks unless it is `addressed` or its risk is accepted. An Optional thread does not block.

   Accepting a risk is a decision about what remains, recorded with its reason: why the risk is small, where it is mitigated, or the follow-up ticket. On a Critical or Important item, thread or new finding alike, the decision is the user's: propose it with the reason, keep the item blocking, and mark it `no (accepted risk)` only after the user says yes. Record the agreed reason as a drafted reply on the thread, posted on confirmation like any comment.

   `addressed` means the scenario the thread described no longer happens, not that the cited line changed; a regression test added for it counts only if it would fail without the fix. Read it against the fix, or, when that is cheap, run it with the fix taken out in an isolated copy of the PR head (a scratch copy or `git worktree add --detach`, never your working tree or the PR branch, nothing committed or pushed), as in the testing-checklist bug-fix protocol. When that cannot be done safely, or the run errors or times out, say the failure was read, not observed.
4. **Scan for new findings.** Re-reading changed code surfaces fresh issues, including regressions the fix itself introduced on adjacent paths. Classify them Critical, Important, or Optional per pr-classify, including its rule that a pure nitpick is dropped. A new Critical or Important finding blocks approval unless its risk is accepted the same way; a new Optional one does not.

## Decision Gate

**Clear.** Only when nothing blocks approval: no thread and no new finding is marked `yes` in steps 3 and 4. Open Optional threads and new Optional findings do not change this; list them as non-blocking, with any new ones drafted as comments. Resolve the `addressed` threads, print the matrix, and state that the PR is ready to approve. Resolution is reversible and needs no confirmation on this clear path; any other thread stays open unless the user says otherwise. Do not approve. Approving is an outward action and needs an explicit yes first. Show the non-blocking drafts with that question: approving and posting them are separate yeses, and an approval alone posts nothing.

**Blocked.** Otherwise, when anything blocks approval: do not approve, and do not resolve the threads that are not addressed. Resolving a genuinely addressed thread here needs a separate explicit confirmation from posting comments. Output the matrix, the draft comments, and any proposed risk acceptance with its reason, then stop and wait.

Never bundle thread resolution, posting comments, and approval into one yes.

## Posting

New inline comments follow the pr-classify rules and are drafted before they are posted. Post them only after the user confirms; a confirmation covers the drafts it names, and a finding added after it is confirmed on its own. An explicit instruction earlier in the conversation to post this recheck's comments is that confirmation; do not ask for it twice. Write them as conversational English prose, without arrows, tildes, or em dashes, and run them through the humanizer skill first. Anchor each one to a `path:line`.

## Delegation

Delegate the gather, keep the judgment. Steps 1 and 2 go to a cheaper-tier subagent returning compact evidence: the unresolved threads, and what changed since the last review with `path:line`. The verification matrix with its severity, status, and blocking calls, the new-findings classification, and the decision gate stay on the main model. Resolving, posting, and approving are gated actions and are never delegated.

## Output

```markdown
## Verification matrix
| Thread (path:line) | Severity | Original point | Status | Blocks approval | Evidence (commit) |

## New findings (draft, not posted)
### Critical / Important (blocking) / Optional (non-blocking)

## Verdict
<cleared | still blocked> — <one sentence>. Next action.
```

Write `_None._` for an empty section rather than dropping the heading.
