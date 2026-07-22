# PR Review loop

## Identity

- **Identifier:** `pr-review`
- **Name:** PR Review
- **Version:** `1.0.0`
- **Status:** Experimental reference loop
- **Autonomy level:** `L1 — Report Only`

## Purpose

Inspect one pull request and produce an evidence-based engineering review report.

**Non-goals:** modify code, submit a GitHub review, post comments, approve or
reject a pull request, re-run CI, create commits, or merge a pull request.

**Success criteria:** the report distinguishes confirmed findings from unverified
concerns, records the evidence inspected, and names the next human action.

## Scope

Inspect the supplied open pull request, its changed files, relevant surrounding
code, and already-available CI and review evidence. Respect protected paths and
repository instructions. Do not inspect unrelated repository areas unless needed
to verify a changed invariant.

## Inputs

- **Required:** repository context and a pull request identifier or URL.
- **Optional:** prior loop state, known risk areas, and a requested review focus.

If the pull request is unavailable, closed, ambiguous, or lacks readable diff
context, stop and report the missing input rather than guessing.

## Skill composition

1. [codebase-map](../../claude-code/.claude/skills/codebase-map/SKILL.md) maps
   affected architecture, invariants, and risky areas.
2. [pr-classify](../../claude-code/.claude/skills/pr-classify/SKILL.md) classifies
   candidate findings using the existing Critical, Important, and Optional model.
3. [testing-checklist](../../claude-code/.claude/skills/testing-checklist/SKILL.md)
   evaluates testing evidence and important untested behavior.
4. [security-pass](../../claude-code/.claude/skills/security-pass/SKILL.md) scopes
   a read-only security assessment when the changed surface is sensitive.
5. [pr-recheck](../../claude-code/.claude/skills/pr-recheck/SKILL.md) compares the
   current evidence with prior review state when a follow-up run is requested.

Pass the changed surface and evidence forward, not unverified conclusions. Keep
classification and the final report separate from gathering work.

## State

Read and update the consuming project's compact PR-specific state. Its schema is
[state.example.md](state.example.md); the report schema is [output.md](output.md).
The consuming project owns state, resolves and prunes obsolete entries, and keeps
human overrides unchanged.

## Verification

Report a finding as confirmed only when code, configuration, test, CI, or other
direct evidence supports it. Analysis without sufficient evidence is an
unverified concern. Failed or unavailable checks are missing evidence, not a
passing result.

## Output

Produce the stable report defined in [output.md](output.md). Reuse
`pr-classify` severity and show evidence and recommended action for every
confirmed finding.

## Limits

Inspect at most 100 changed files and 100 prior review threads per run. Make no
more than one evidence-retrieval retry per unavailable source. Stop when inputs,
access, or verification evidence remain unavailable.

## Human handoff

Hand off when requirements are ambiguous, a protected path is involved, a
security or reliability risk needs product context, evidence is unavailable, or a
review, approval, comment, commit, or any other external action is requested.

## Autonomy

**Permitted:** inspect, analyze, classify, run read-only checks, update local
loop state, and produce a report.

### Prohibited write and outbound actions

This L1 loop must not edit product code or documentation, create commits, push
branches, create or update pull requests, post comments, change issues, modify
dependencies, re-run CI, approve or reject a pull request, or merge anything.
