# PR Review report schema

Use these headings in this order. Empty sections state `_None._`; do not omit the
heading.

## PR identity

Repository, pull request identifier, source and target branches, and inspected
commit.

## Review status

`complete`, `partial`, or `blocked`, with the reason.

## Scope inspected

Changed surface, surrounding areas read, excluded paths, and evidence sources.

## Risk level

`low`, `moderate`, or `high`, with a short evidence-based rationale.

## Confirmed findings

Findings classified by the existing `pr-classify` taxonomy. Each includes
location, evidence, impact, and recommended next action.

## Unverified concerns

Questions or hypotheses that need additional evidence, clearly not presented as
findings.

## Testing assessment

Available test and CI evidence, coverage gaps, and unavailable checks.

## Security assessment

Applicable sensitive surface, evidence reviewed, and concerns or `_Not applicable._`

## Missing evidence

Unavailable diff, CI, test, access, or repository context required for confidence.

## Changes since previous run

New commit range, resolved findings, changed concerns, and human overrides.

## Recommended next action

One prioritized human action or `_No action recommended._`

## Human decision required

The explicit decision needed, or `_None._`
