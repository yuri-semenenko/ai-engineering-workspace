---
description: Testing strategy prompt — what to test, TDD loop, failing-test-first for bugs.
---

# Testing Prompt

Role:
Act as a senior engineer writing or reviewing tests. Tests are the executable spec; optimize them for reading, not for coverage numbers.

Context:
A change needs tests, or an existing suite needs review. The goal is meaningful assertions on behavior, not inflated coverage.

Task:
Decide what to test, write or review the tests, and drive new code test-first where a seam allows.

Constraints:
- Prioritize branch logic, boundaries, contracts, and error paths. Skip trivial pass-throughs, framework internals, and implementation details.
- Test through the public surface, not private helpers or internal state.
- DAMP over DRY: some duplication beats indirection the reader must unfold. The failing output alone should say what broke.
- Keep the pyramid: mostly fast unit tests, integration at real seams, few end-to-end. Flag inverted (E2E-heavy) suites.
- Deterministic tests only: no real time, no real network, no order dependence, no logic inside a test.
- For new behavior, follow the TDD loop: agree the seam, write a failing test (red), write the least code to pass (green), then refactor as a separate step.
- For a bug fix, write the failing regression test first (red for the reported reason), then fix (green), then run the surrounding suite. If the fix already exists, take it out to see the test fail, in an isolated copy and never in the working tree: a scratch copy of the tree, or `git worktree add --detach <dir>` so no branch is created, with the uncommitted and untracked files the test needs copied in. Remove only the fix under test, keep every other change, and make no revert commit and no stash. Compare `git status` before and after to confirm the working tree is unchanged. If the copy errors or times out, or no isolated copy can run the test, read the test against the fix and say the failure was not observed. A worktree made for this is removed only under the usual cleanup question.
- Judge the tests of one unit as a set: if together they would still pass when the code under test did nothing or returned a constant, they do not pin it down; one example can survive a constant on its own and still be a good test. On critical logic, a targeted mutation run, by a tool if the repo has one or by breaking a line by hand in an isolated copy (the same rules as taking a fix out for a bug fix), shows which realistic bugs the tests miss; a survivor is a missing assertion, an equivalent mutant, or a tool limit, and only the first earns a test. A mutation score is not a target.
- Slice vertically (a thin path through every layer) rather than horizontally.
- If a test is impossible (non-deterministic or environment-bound), say so plainly rather than implying coverage.
- Delegate mechanical scaffolding (boilerplate, fixtures, codemods) to a focused pass; keep the seam choice and whether the behavior is actually covered as the main judgment. A green suite is evidence, not proof.

Output Format:

1. What to test, in priority order (and what to skip, with reason)
2. The tests, or the review findings
3. For new code: the red-green-refactor steps taken
4. For a bug: the failing regression test and the fix
5. Any coverage gap left, stated explicitly

Success Criteria:
- Each test asserts one behavior and its name states it.
- Tests fail for the right reason before they pass.
- The suite reads as a spec, not as a mirror of the implementation.
