---
name: research
description: Use when deciding a concrete technical question — comparing libraries, frameworks, APIs, or approaches — by gathering evidence from primary sources into a cited decision matrix with a recommendation and its uncertainty, ready to hand to an RFC or ADR. Lighter than a full research-report harness: bounded to what the decision needs.
---

# Research

Turn a technical question into a decision you can defend: evidence from primary sources, a cited comparison, and a recommendation that states its own uncertainty. The output feeds an RFC or ADR; it is not the decision document itself. Depth is proportional to the blast radius of the decision.

## The Loop

1. Frame the question and the criteria that will matter — those become the matrix columns. If the question is too broad to answer, ask one or two clarifiers and stop.
2. Go to primary sources: official docs, specs, changelogs, benchmarks, the source itself, and the repo's own constraints. Date volatile facts.
3. Capture evidence and cite as you go. Separate what the source says from your inference; keep a short trail of sources kept and dropped.
4. Surface contradictions explicitly; what you cannot resolve becomes an open question, not a silent pick.
5. Build the decision matrix: options as rows (include "do nothing / defer"), criteria as columns, cells filled with cited evidence.
6. Recommend with uncertainty: the recommendation, your confidence, what would change it, and what remains unknown.
7. Hand off to rfc (Options, Trade-offs) or adr (Alternatives Considered). Research is not the decision doc.

## Guardrails

- Primary sources over secondary. Cite load-bearing claims; date the volatile ones.
- Not a literature review or a full report harness: bound the search to what the decision needs.
- Flag uncertainty explicitly; keep contradictions visible.
- Distinct from rfc (explores and decides at system altitude) and adr (records a settled decision). Research produces the cited evidence they consume.
