---
name: testing-checklist
description: Use when writing or reviewing tests, deciding coverage for a change, driving new code test-first, or fixing a bug that needs a regression test. Covers what to test, the TDD loop, and failing-test-first.
---

# Testing Checklist

Tests are the executable spec. Optimize them for reading and for meaningful assertions, not for coverage numbers.

## What to test

- Branch logic, boundaries, contracts, and error paths first.
- Skip trivial pass-throughs, framework internals, and implementation details.
- Test through the public surface, not private state or call order.

## TDD loop (new behavior)

1. Agree the seam where the test attaches before writing it.
2. Red: write one failing test for the next thin slice; watch it fail for the intended reason.
3. Green: write the least code that makes it pass.
4. Refactor as a separate step, with the test green as the safety net.

Slice vertically (one thin path through every layer), not horizontally. One slice at a time.

## Bug-fix protocol

1. Write the regression test that reproduces the bug; it must fail for the reported reason. If the fix already exists, take it out to see that failure, in an isolated copy and never in the working tree: a scratch copy of the tree, or `git worktree add --detach <dir>` so no branch is created, with the uncommitted and untracked files the test needs copied in. Remove only the fix under test, keep every other change, and make no revert commit and no stash. Compare `git status` before and after to confirm the working tree is unchanged. If the copy errors or times out, or no isolated copy can run the test, read the test against the fix and say the failure was not observed. A worktree made for this is removed only under the usual cleanup question.
2. Fix; the test goes green.
3. Run the surrounding suite so the fix did not move the bug elsewhere.

## Guardrails

- DAMP over DRY: the failing output alone should say what broke.
- Judge the tests of one unit as a set: if together they would still pass when the code under test did nothing or returned a constant, they do not pin it down; one example can survive a constant on its own and still be a good test. On critical logic, a targeted mutation run, by a tool if the repo has one or by breaking a line by hand in an isolated copy (the same rules as taking a fix out in the bug-fix protocol), shows which realistic bugs the tests miss; a survivor is a missing assertion, an equivalent mutant, or a tool limit, and only the first earns a test. A mutation score is not a target.
- Deterministic only: no real time, no real network, no order dependence, no logic inside a test.
- Keep the pyramid: mostly unit, integration at real seams, few end-to-end.
- If a test is impossible (non-deterministic or environment-bound), say so plainly rather than implying coverage.
- Delegate mechanical scaffolding (boilerplate, fixtures, codemods) to a cheaper-tier subagent; keep the seam choice and the "is the behavior actually covered" judgment on the main model. A green suite is evidence, not proof.
