---
name: failure-investigation
description: Use when behavior is broken, tests fail, errors appear, production behavior regresses, or the user asks why something is failing, падает, сломалось, or needs root-cause analysis.
---

# Failure Investigation

Find the confirmed cause before changing code. A fix that only removes the symptom is not done.

## Process

1. Reproduce the failure with exact input, command, environment, and observed output.
2. Read the real evidence: error text, logs, stack trace, failing assertion, diff, or runtime state.
3. Isolate the smallest trigger by narrowing code path, data shape, timing, or dependency boundary.
4. Write 1-3 falsifiable hypotheses. Each must predict what evidence would disprove it.
5. Test the cheapest hypothesis first. Change one variable at a time.
6. Fix the root cause with the smallest targeted change.
7. Verify the original reproduction and add or update a regression test when the repo has a natural test location.
8. Remove temporary instrumentation before completion.

## Guardrails

- Separate observed facts from assumptions.
- Distinguish proximate cause from root cause.
- Do not swallow errors, add retries, or null-check around a logic bug unless that is the confirmed cause.
- Do not refactor while investigating unless the refactor is required to expose the cause.
- If reproduction is impossible, say what evidence is missing and label any fix as unconfirmed.

## Output

Keep the current phase visible. End with: root cause, fix, verification, and any prevention follow-up worth considering.
