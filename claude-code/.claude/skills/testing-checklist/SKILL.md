---
name: testing-checklist
description: Testing checklist — test pyramid, what to test vs skip, DAMP over DRY, the TDD red-green-refactor loop for new code, failing-test-first for bug fixes, Vitest / React Testing Library patterns. Use when writing or reviewing tests, deciding test coverage for a change, driving new code test-first, fixing a bug (regression test), or when the user asks "what should I test here", "покрой тестами", "review the tests". Pairs with /verify (runtime verification) and the persona's Verification Exit Criterion. Sibling of /web-security-checklist and /web-performance-checklist.
---

# Testing Checklist

A pragmatic checklist for writing and reviewing tests. Read the relevant section for the change at hand rather than the whole file. Tests are the executable spec — optimize them for reading, not for coverage numbers.

## Rationalizations (read first)

| Rationalization | Rebuttal |
|---|---|
| "I'll add tests later." | Later is the load-bearing word — it rarely arrives. The test is part of the change, not a follow-up. |
| "Tests pass, ship it." | Passing tests are evidence, not proof. They only cover what they assert — check what they *don't* cover. |
| "This code is too simple to break." | Simple code with branch logic breaks at the boundaries. Test the boundaries, skip the trivial middle. |
| "Coverage is at N%, we're good." | Coverage measures execution, not assertion. A test with no meaningful assert inflates N and catches nothing. |
| "The bug is fixed, no test needed." | A fix without a regression test is a bug on a return ticket. Red first, then green. |
| "I'll write the code first, then add tests." | Test-after validates the code you happened to write, not the behavior you wanted. Red first keeps the test honest. |
| "I'll DRY up these tests with helpers." | Test code is spec, not production code. DAMP wins: some duplication beats indirection the reader must unfold. |

## What to test (in priority order)

- [ ] **Branch logic** — every non-trivial `if`/`switch`/early-return path, especially error paths.
- [ ] **Boundaries** — empty input, one item, max size, null/undefined, zero, negative, off-by-one edges.
- [ ] **Contracts** — what callers rely on: return shapes, thrown error types, emitted events, side effects.
- [ ] **Error handling** — the failure path is production code too; assert what happens when the dependency fails.
- [ ] **Regressions** — every fixed bug gets a test that fails without the fix (write it first, watch it fail).

## What NOT to test

- [ ] Implementation details — private helpers, internal state, call order that a refactor may change. Test through the public surface.
- [ ] The framework — React rendering, ORM query building, library internals. Assume they work; test *your* logic.
- [ ] Trivial pass-throughs — getters, re-exports, config objects with no logic.
- [ ] Exact copies of the implementation — a test that mirrors the code's algorithm proves nothing; assert on known input → expected output instead.

## Shape of the suite

- [ ] Pyramid roughly holds: mostly fast unit tests, some integration at real seams (API route + DB, component + store), few end-to-end. Inverted pyramids (E2E-heavy) are slow and flaky — flag them.
- [ ] Integration tests sit at *real* seams — if everything meaningful is mocked, it's a unit test with extra steps and false confidence.
- [ ] Each test asserts one behavior; the name states it (`rejects expired token`, not `test auth 2`).
- [ ] Deterministic: no real time (`vi.useFakeTimers`), no real network, no shared mutable state between tests, no order dependence.
- [ ] No logic in tests — a `for`/`if` inside a test is a test that can be wrong. Table-driven cases (`it.each`) are fine; computation of the expected value is not.

## Test quality (DAMP over DRY)

- [ ] The failing output alone tells you what broke — descriptive name, explicit expected value, no dig into helpers to understand the setup.
- [ ] Setup visible at the test site: prefer inline literals or a plainly-named builder over layers of `beforeEach` mutation.
- [ ] Assert on values, not on "did not throw".
- [ ] Mocks are visible in the test that uses them; a mock configured three files away is a trap for the next reader.

## Stack specifics (Vitest / React Testing Library)

- [ ] Query by role/label/text (`getByRole('button', { name: /save/i })`) — testid only when no accessible query exists (that gap is often an a11y bug worth fixing instead).
- [ ] `userEvent` over `fireEvent` — it simulates real interaction sequences (focus, keydown, click).
- [ ] Async UI: `await findBy…` / `waitFor` with a real assertion inside — never sleep-and-hope.
- [ ] Assert what the user sees/experiences, not component internals (`state`, props of children, hook return values).
- [ ] MSW (or fetch-mock at the boundary) for network — don't mock your own data-fetching wrapper; mock the wire.

## TDD loop (new behavior)

For new code, not just bug fixes — let the test drive the design, red before green.

1. **Agree the seam first.** Decide where the test attaches — a public function, an API route, a component's rendered output — and confirm it before writing the test. Testing below an agreed seam couples the suite to internals; testing above it asserts nothing of yours.
2. **Red.** Write one failing test for the next thin slice of behavior. Run it, watch it fail for the intended reason.
3. **Green.** Write the least code that makes it pass. No more.
4. **Refactor — outside the loop.** Clean up with the test green as the safety net. Refactoring is its own step, never folded into red or green.

Slice **vertically** — a tracer bullet, one thin path through every layer, demoable — not horizontally (a whole layer at once, testable only much later). One slice at a time.

## Bug-fix protocol

1. Write the test that reproduces the bug. Run it — it must fail for the *reported* reason.
2. Fix. Run it — green.
3. Run the surrounding suite — the fix didn't move the bug next door.

If step 1 is impossible (non-deterministic, environment-bound), say so explicitly per the Verification Exit Criterion — never imply tested-and-covered when it isn't.

## Delegation

Delegate the scaffolding, keep the coverage judgment. Hand mechanical generation to a cheaper-tier subagent — test boilerplate, fixtures, obvious table-driven cases, a codemod across many test files — returning ready-to-review tests. Keep on the main model the parts that need judgment: choosing the seam, deciding what is worth testing, and confirming the behavior is actually covered. A green suite is evidence, not proof the acceptance criteria are met.
