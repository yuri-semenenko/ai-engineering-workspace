# Review discipline

Review is where an assistant is most useful and most dangerous: it can surface a
real correctness bug, and it can bury it under forty style nitpicks. The canon
imposes two disciplines to keep review signal high — a classification scheme that
forces triage, and an exit criterion that forbids "seems right" as a stopping
point.

## Classify every finding by the cost of ignoring it

Every review comment lands in one of three buckets, and the bucket is decided
*before* the comment is written:

- **Critical** — correctness, security, reliability. A logic bug on the happy
  path or a documented edge case, an injection or auth bypass or secret leak, a
  race condition, data loss or an irreversible migration, a regression in
  existing coverage.
- **Important** — maintainability, scalability, readability. Coupling that will
  hurt the next change here, a missing test for non-trivial branch logic, an N+1
  or an avoidable O(n²), naming that misleads future readers, an abstraction that
  leaks across a module boundary.
- **Optional** — style and preference. Could be more functional, comment
  phrasing, consistency with a pattern used elsewhere.

Two rules keep the scheme from inflating:

- **The anti-nitpick rule.** If a finding is Optional and the cost of ignoring it
  is "none", it does not get written. This is the single most important line in
  the review canon. A review that is mostly Optional trains the author to skim
  past all of it, including the Critical items.
- **More than ~3 Criticals on a normal PR means you're over-classifying.**
  Critical is for things that must not merge, not for things you feel strongly
  about.

Findings are grouped by bucket, not by file, and every one cites `file:line`.
The review ends with a single verdict — approve, request changes, or needs
discussion — with a one-sentence rationale.

The `pr-classify` skill produces this first-pass review. `pr-recheck` does the
second pass after fixes: it re-reads the diff against the existing open threads,
marks each addressed / partial / not addressed, and only approves when everything
is genuinely clean. Both verify the PR is still open and unmerged before they
start — reviewing a merged PR is wasted work.

## The verification exit criterion

> No task ends on "seems right."

Every change closes with concrete evidence: a passing test, a clean build or
typecheck, a runtime check that exercises the actual behavior, or an explicit
reviewer sign-off. If verification was skipped or impossible, that is stated
plainly along with what remains unverified. The failure mode this exists to
prevent is the most common one in agent-assisted work: reporting done-and-checked
when only the first half happened.

The `verify` skill drives the affected flow end to end and observes behavior
rather than trusting that tests and typecheck imply correctness. It is the
runtime complement to the review skills.

## Testing posture

The canon's testing stance is conventional and deliberately so:

- **Follow the pyramid.** Many fast unit tests, fewer integration tests, a thin
  layer of end-to-end. Test behavior, not implementation detail.
- **DAMP over DRY in tests.** A test that repeats itself but reads top-to-bottom
  beats a clever helper that hides what is under test. Descriptive and obvious
  wins over compact.
- **Failing-test-first for bug fixes.** Reproduce the bug as a failing test
  before you fix it. The test that goes red then green is the proof the fix
  works and the guard against the regression returning.

The `testing-checklist` skill carries the full version — what to test versus
skip, coverage judgment for a given change, Vitest and React Testing Library
patterns. It pairs with `verify`: the checklist decides what to test, `verify`
confirms the change actually works.
