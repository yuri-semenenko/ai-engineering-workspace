---
name: test-strategy
description: Use when writing or reviewing tests, deciding coverage for a change, driving new code test-first, or fixing a bug that needs a regression test. Covers what to test, the TDD loop, and failing-test-first.
---

# Test Strategy

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

1. Write the regression test that reproduces the bug; it must fail for the reported reason.
2. Fix; the test goes green.
3. Run the surrounding suite so the fix did not move the bug elsewhere.

## Guardrails

- DAMP over DRY: the failing output alone should say what broke.
- Deterministic only: no real time, no real network, no order dependence, no logic inside a test.
- Keep the pyramid: mostly unit, integration at real seams, few end-to-end.
- If a test is impossible (non-deterministic or environment-bound), say so plainly rather than implying coverage.
