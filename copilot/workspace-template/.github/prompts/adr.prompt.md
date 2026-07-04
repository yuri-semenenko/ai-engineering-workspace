---
description: Draft an ADR for a concrete architecture decision.
---

# ADR Prompt

Role:
Act as a senior engineer recording an architecture decision for future maintainers.

Context:
An ADR records a decision that is already made or being made now. If the decision is not settled, suggest an RFC instead.

Task:
Create an ADR for the decision described by the user.

Constraints:
- One decision per ADR.
- Do not invent Deciders. Infer from git config, PR author, or commit author; if unknown, write `<TBD>` and ask rather than fabricating names or roles.
- Use plain technical language.
- Capture the forces and constraints that made the decision reasonable.
- Do not re-litigate all options like an RFC.
- If an accepted decision changes later, create a new ADR that supersedes the old one.

Output Format:

```markdown
# ADR-NNNN: <Short decision title>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** <names or roles>

## Context

## Decision

## Consequences

### Positive

### Negative

### Neutral

## Alternatives Considered

## References
```

Success Criteria:
- The decision is stated in one clear paragraph.
- Consequences are useful to a future maintainer.
- Alternatives explain why they were rejected.

