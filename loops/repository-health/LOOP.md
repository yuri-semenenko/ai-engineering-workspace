# Repository Health loop

## Identity

- **Identifier:** `repository-health`
- **Name:** Repository Health
- **Version:** `1.0.0`
- **Status:** Experimental reference loop
- **Autonomy level:** `L1 — Report Only`

## Purpose

Produce a periodic, evidence-based engineering-health report for one repository
without modifying it.

**Non-goals:** update dependencies, edit documentation, regenerate mirrors,
repair validation failures, open issues, create pull requests, or change CI
configuration.

**Success criteria:** the report exposes validated signals, gaps, and prioritized
maintenance actions without inventing an arbitrary health score.

## Scope

Inspect the supplied repository, its existing validation and test evidence,
methodology canon, adapters, instructions, and security-sensitive configuration.
Respect protected paths and repository instructions. Limit broader code inspection
to areas required to substantiate a reported signal.

## Inputs

- **Required:** repository context and access to its tracked files.
- **Optional:** prior loop state, recent commit range, and known maintenance areas.

If the repository context, required commands, or required access is unavailable,
record the gap and stop the relevant assessment rather than inferring a result.

## Skill composition

1. [codebase-map](../../claude-code/.claude/skills/codebase-map/SKILL.md) maps
   relevant structure, entry points, constraints, and risky areas.
2. [complexity-audit](../../claude-code/.claude/skills/complexity-audit/SKILL.md)
   identifies evidence-based complexity signals.
3. [debt-ledger](../../claude-code/.claude/skills/debt-ledger/SKILL.md) gathers
   intentional trade-offs and known debt.
4. [testing-checklist](../../claude-code/.claude/skills/testing-checklist/SKILL.md)
   assesses available testing and CI evidence.
5. [security-pass](../../claude-code/.claude/skills/security-pass/SKILL.md) scopes
   a read-only inspection of sensitive configuration and hardening signals.

Run existing workspace validation where available. Inspect canon-to-adapter drift,
broken skill references, validation status, stale or inconsistent generated
mirrors, and missing or outdated project instructions. Pass evidence forward, not
assumptions or remediation plans.

## State

Read and update the consuming project's compact repository-health state. Its
schema is [state.example.md](state.example.md); the report schema is
[output.md](output.md). The consuming project owns state, prunes resolved entries,
and preserves human overrides.

## Verification

Treat a health signal as confirmed only when a repository file, command output,
CI result, or direct inspection supports it. A check that cannot run is missing
evidence, not a healthy result. Keep observed facts separate from recommendations.

## Output

Produce the stable report defined in [output.md](output.md). Prefer transparent
statuses and evidence over a numeric or badge-style health score.

## Limits

Inspect at most 200 files outside generated or vendor directories and run each
available validation command once. Retry a transient command failure once. Stop
when missing access, time, or evidence would make further conclusions unreliable.

## Human handoff

Hand off when instructions conflict, protected paths are implicated, a security or
reliability risk needs product context, validation evidence is unavailable, or a
maintenance action requires a decision about scope or priority.

## Autonomy

**Permitted:** inspect, analyze, classify, run read-only checks, update local
loop state, and produce a report.

### Prohibited write and outbound actions

This L1 loop must not edit product code or documentation, update dependencies,
regenerate mirrors, repair validation failures, change CI configuration, create
commits, push branches, create or update pull requests, post comments, change
issues, or merge anything.
