---
name: pr-recheck
description: Second-pass re-review of a PR that already has review comments. Re-reads the diff and new commits against the existing open threads, marks each as addressed / partial / not addressed, resolves the addressed ones, and then either approves (only when everything is clean) or drafts new inline comments. Use when the user asks to "re-review", "recheck the PR", "перепроверь PR после фиксов", or do a follow-up pass. Different from pr-classify, which is the first-pass review.
---

# PR recheck

Follow-up pass on a PR that has already been reviewed once. Assumes a prior round
of inline comments exists and the author has pushed fixes since.

## Preconditions
Same as pr-classify: run `gh auth status`; require a PR number/URL or a checked-out
branch with an open PR; verify open state via `gh pr view <id> --json state,mergedAt`.
If merged or closed, surface that and stop.

## Steps

1. **Load prior threads.** Fetch open review threads via GraphQL — REST does not
   expose thread resolution state:
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$num:Int!){
     repository(owner:$owner,name:$repo){ pullRequest(number:$num){
       reviewThreads(first:100){ nodes{ id isResolved
         comments(first:20){ nodes{ path line body author{login} } } } } } } }' \
     -f owner=OWNER -f repo=REPO -F num=N
   ```
   Keep only threads with `isResolved: false`.
2. **Load new work.** Diff and commits since the previous review (`gh pr diff <id>`
   plus the commit log). Read the new code fully, cross-referencing touched files.
3. **Build the verification matrix.** For each open thread, classify one of:
   `addressed` / `partial` / `not addressed` / `wont-fix (author replied)`, each
   with the file:line and the commit that addresses it. Output as a table.
4. **Scan for new findings.** Re-reading the changed code may surface fresh issues.
   Classify them Critical / Important / Optional per pr-classify rules — the
   anti-nitpick gate applies (drop Optional whose cost of ignoring is "none").

## Decision gate

**Clean path.** If AND only if every prior open thread is `addressed`
AND there are zero new findings of any tier:
- Resolve each addressed thread via
  `gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -f id=THREAD_ID`
  (resolution is reversible — no confirmation needed).
- Print the matrix and the line `all clear — N threads resolved; ready to approve`.
- **Do NOT auto-approve.** Approving a PR is an outward action; per the persona's
  git policy ("always ask permission before … opening PRs"), state that the PR is
  clean and wait for an explicit yes before running `gh pr review <id> --approve`.

**Blocked path — draft, then confirm.** If any thread is `partial` / `not addressed`
/ `wont-fix`, or any new finding exists:
- Do NOT approve. Do NOT resolve `partial` / `not addressed` threads.
- Resolving any genuinely-addressed threads in this path still requires explicit
  confirmation, and is a separate yes from posting new comments.
- Output the verification matrix and the new draft comments, then stop and wait.

## Posting & resolving (blocked path only)
- New inline comments: same rules as pr-classify "Posting inline comments" — draft
  first, confirm, conversational English plain prose, no →/~/em-dash, run through
  the `humanizer` skill before posting. Anchor each to file:line via the gh review API.
- Thread resolution and any approve are separate confirmations. Never bundle
  "resolve + approve" into a single yes here.

## Output format
```
## Verification matrix
| Thread (file:line) | Original point | Status | Evidence (commit) |

## New findings   (draft, not posted)
### Critical / Important / Optional

## Verdict
<approved automatically | still blocked> — <one sentence>. Next action.
```
If a section is empty, write `_None._` rather than dropping the heading.
