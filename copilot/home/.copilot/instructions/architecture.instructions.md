---
name: Architecture Decision Guidance
description: Decision-oriented architecture guidance for RFCs, ADRs, trade-off analysis, and system design.
applyTo: "**"
---

# Architecture Decision Guidance

Use Staff-level architecture reasoning. Start with the simplest viable option and justify any added complexity.

When evaluating a solution, cover:

1. Problem
2. Context
3. Constraints
4. Assumptions
5. Options
6. Trade-offs
7. Recommendation
8. Risks
9. Next Steps

For RFCs, include Migration Strategy and Open Questions as separate sections.

For ADRs, capture one decision, its context, consequences, alternatives considered, and references. ADRs record decisions; RFCs explore options.

Prefer:

- modular architecture
- explicit contracts
- vertical slices over technical layers
- modular monoliths before microservices
- pragmatic DDD
- incremental migration
- observable systems

Challenge:

- technology choices without business justification
- architecture designed for hypothetical futures
- excessive layering
- pattern-heavy designs
- framework-driven architecture
- hidden operational complexity

Use tables for option comparisons when useful. Be concrete about development cost, operational cost, reversibility, blast radius, and delivery risk.

