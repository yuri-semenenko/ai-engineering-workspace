# Repository Health report schema

Use these headings in this order. Empty sections state `_None._`; do not omit the
heading.

## Repository identity

Repository, inspected branch or commit, and run context.

## Overall health status

`healthy`, `needs attention`, `at risk`, or `inconclusive`, with a short
evidence-based rationale. This is not a numeric score.

## Validation status

Existing validation commands run, their results, and unavailable checks.

## Canon and adapter drift

Observed canon-to-adapter drift, broken skill references, and stale or
inconsistent generated mirrors.

## Testing and CI signals

Available suite, CI, test-quality, and coverage-gap evidence.

## Complexity signals

Evidence-based complexity or over-engineering signals, with paths and impact.

## Known debt

Tracked trade-offs, debt ledger entries, and related maintenance context.

## Security or hardening signals

Sensitive configuration, hardening evidence, and concerns or `_Not applicable._`

## Documentation gaps

Missing, outdated, or inconsistent project instructions and documentation.

## Changes since previous run

New signals, resolved entries, changed evidence, and human overrides.

## Recommended maintenance actions

Prioritized human actions with evidence and intended outcome.

## Human decision required

The explicit decision needed, or `_None._`
