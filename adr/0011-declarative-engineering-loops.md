# ADR-0011: Introduce declarative engineering loops as a separate orchestration layer

- **Status:** Accepted
- **Date:** 2026-07-22
- **Deciders:** Yuri Semenenko

## Context

Skills encode reusable engineering procedures, but the workspace lacks a canonical
way to compose them into repeatable, stateful workflows. Consumers consequently
have no shared contract for a workflow's goal, state, output, verification,
limits, human handoff, or autonomy boundary.

## Decision

Add loops as a distinct canonical layer:

```text
methodology canon
+ identity
+ skills
+ tool adapters
+ loops
+ validation
```

Loops compose skills and define state, output, limits, verification, and
autonomy. They remain tool-agnostic Markdown contracts. This first increment
provides only two L1 report-only reference loops: PR Review and Repository Health.

## Key boundaries

- A loop is not a skill.
- A loop is not an agent persona.
- A loop is not a scheduler.
- A loop is not a runtime.
- Loops are canonical and tool-agnostic.
- This change supports only report-only workflows.
- Tool adapters may be added later only after the canonical model proves useful.

## Consequences

### Positive

- Repeatable workflows gain stable outputs and explicit limits.
- Durable consuming-project state becomes visible and bounded.
- Verification and human handoff rules are part of the workflow contract.
- The layer offers a safer path toward future automation without claiming it now.

### Negative

- The repository gains another architectural concept and validation burden.
- Skills and loops can be confused without clear boundaries.
- The concept risks premature automation if L2 or L3 becomes implementation work
  before the L1 examples prove useful.

### Neutral

- Runtime state remains outside the methodology canon and is normally gitignored.
- Existing skills remain the source of engineering procedure; loops only compose
  them.

## Alternatives Considered

- **Model loops as ordinary skills.** Rejected: skills describe a reusable
  procedure; loops coordinate several skills plus durable state and stable output.
- **Copy the complete `loop-engineering` ecosystem.** Rejected: it would import a
  larger architecture than this methodology-first repository has validated.
- **Build a scheduler or runtime immediately.** Rejected: it adds operational
  behavior before the declarative contract has proven useful.
- **Begin with auto-fix workflows.** Rejected: report-only workflows establish
  verification and handoff boundaries without persistent or outbound actions.
- **Create loop implementations separately for each AI tool.** Rejected: per-tool
  ports would widen the diff before the canonical model is stable.

## References

- [Loop contract](../loops/contract.md)
- [Autonomy levels](../loops/autonomy-levels.md)
- ADR-0001 — single canon with generated mirrors
- ADR-0006 — process skills, not codegen orchestration
