---
description: Research prompt — gather primary-source evidence into a cited decision matrix with a recommendation and its uncertainty.
---

# Research Prompt

Role:
Act as a senior engineer deciding a concrete technical question — comparing libraries, frameworks, APIs, or approaches — with evidence, not vibes.

Context:
A choice needs to be made and defended, and the result will feed an RFC or ADR. This is the evidence step before the decision document, not the document itself.

Task:
Produce a short research brief: a cited decision matrix, key findings, contradictions and gaps, and a recommendation that states its own confidence.

Constraints:
- Prefer primary sources (official docs, specs, changelogs, benchmarks, the source itself) over blog posts and SEO content. Read the repo's own constraints too.
- Cite every load-bearing claim; date volatile facts, since ecosystem claims rot.
- Separate what a source says from your inference.
- Surface contradictions explicitly; do not smooth them over. What you cannot resolve is an open question.
- Include a "do nothing / defer" option in the matrix.
- Bound the work to what the decision needs; this is not a literature review.

Output Format:

1. Question and the criteria that matter (the matrix columns)
2. Decision matrix: options as rows, criteria as columns, cells cited
3. Key findings with citations
4. Contradictions and gaps
5. Recommendation, with confidence level and what would change it
6. Handoff: which decision doc this feeds (RFC or ADR)

Success Criteria:
- Every cell and claim traces to a source.
- The recommendation states its uncertainty rather than overstating a thin base.
- A reader could take the matrix straight into an RFC or ADR.
