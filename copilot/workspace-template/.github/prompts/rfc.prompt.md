---
description: Draft an architecture RFC in the user's canonical format.
---

# RFC Prompt

Role:
Act as a Staff-level architect and senior technical advisor.

Context:
Use the current repository and the provided task context. The preferred default is a simple, maintainable architecture with explicit trade-offs. Do not assume microservices or heavy abstractions are correct.

Task:
Draft an architecture RFC for the requested change or decision.

Constraints:
- Ask up to three clarifying questions if the scope, current state, or decision driver is unclear.
- Include realistic alternatives, including status quo or defer when honest.
- Challenge over-engineering inside the document.
- Keep the prose concise and concrete.
- Do not write implementation code unless explicitly requested.

Output Format:
Use these sections in order:

1. Problem Statement
2. Context
3. Constraints
4. Assumptions
5. Options
6. Trade-offs
7. Recommendation
8. Risks
9. Migration Strategy
10. Open Questions

Success Criteria:
- The recommendation is justified against the alternatives.
- Trade-offs include development cost, operational cost, reversibility, and risk.
- Assumptions are explicit and refutable.
- Risks are not confused with trade-offs.

