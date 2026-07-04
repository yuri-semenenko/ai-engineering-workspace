---
name: rfc
description: Draft an architecture RFC using the user's canonical 10-section format (Problem → Context → Constraints → Assumptions → Options → Trade-offs → Recommendation → Risks → Migration Strategy → Open Questions). Use when the user asks for an "RFC", "design doc", "architectural proposal", or "RFC по <теме>". Optimized for the user's Codex persona.
---

# RFC

Produce an architecture RFC in the user's canonical format. The user is a Staff Engineer biased toward simplicity, FP, modular monoliths, and pragmatic DDD — challenge over-engineering inside the doc itself, do not defer it to review.

## Steps

1. **Clarify scope before writing.** If the input is vague ("RFC for caching"), ask 1-3 targeted questions: what problem prompted it, what's the current state, what's the deadline / urgency. Do not invent context.
2. **Read the repo** if relevant — `package.json`, top-level structure, existing ADRs/RFCs (`docs/rfc/`, `docs/adr/`, `.docs/`) to mirror naming and tone.
3. **Draft all 10 sections.** Do not skip any. If a section is genuinely empty, write `N/A — <one-line reason>` rather than removing it.
4. **Surface 2-3 realistic options.** Never present a single recommendation as "the" answer. Include a "do nothing / defer" option when honest.
5. **Trade-offs must be concrete.** Cost in dev hours, operational complexity, blast radius if it fails. No marketing prose.
6. **Recommendation must justify itself against the other options**, not in isolation.
7. **Risks ≠ trade-offs.** Risks are what could go wrong despite the right choice (regression, scope creep, dependency change, hiring gap).

## Required sections (in order)

1. **Problem Statement** — one paragraph, no jargon. What hurts today.
2. **Context** — current architecture, team, constraints from history. Link to relevant code/docs.
3. **Constraints** — hard limits (compliance, deadline, headcount, infra).
4. **Assumptions** — explicit, refutable. Each one should be a sentence someone could disagree with.
5. **Options** — 2-4 alternatives. Include status quo.
6. **Trade-offs** — table preferred: option × (dev cost, ops cost, time-to-value, reversibility, risk).
7. **Recommendation** — chosen option + why it beats each alternative.
8. **Risks** — what we accept by choosing this. Include mitigations only where they're real.
9. **Migration Strategy** — phased plan if non-trivial. Define rollback criteria.
10. **Open Questions** — things this RFC explicitly does not answer.

## Output

Single markdown document. Use H2 (`##`) for each of the 10 sections. Tables for trade-offs. No emoji. No "this comprehensive proposal aims to leverage" prose — concise, structured, direct.
