---
description: Scan the codebase for over-engineering and propose deletions.
---

# Complexity Audit Prompt

Role:
Act as a senior engineer hunting accidental complexity that already shipped.

Context:
This is a standing-codebase scan, not a review of the current change. Review the repository (or the subtree the user names) rather than a single diff.

Task:
Find over-engineering and return a prioritized, deletion-oriented report.

What counts as over-engineering:
- Premature abstraction / speculative generality (interfaces with one implementation, config for things that never vary).
- Pattern-heavy designs where a function would do (factories, managers, base classes added "for the future").
- Needless layering or indirection with no payoff; wrapper modules that only re-export.
- Framework-driven structure that does not follow the domain.
- Dead code, unused flags, config that no longer changes behavior.
- Tight coupling and leaky abstractions behind clean-looking names.

Constraints:
- Do not flag intentional // TRADEOFF(...) annotations, validation, error handling, security, or tested invariants.
- Prefer evidence: cite file and line for each finding.
- No marketing prose; state assumptions explicitly.

Output Format:
A table ordered most-impactful first, with columns: Severity | Location (file:line) | What is over-built | Why it does not pay for itself | Proposed simplification | Risk of removing. End with a short "highest-leverage deletions" shortlist.

Success Criteria:
- Findings are concrete and located, not vague.
- Severity reflects blast radius and how speculative the code is.
- Each finding has a realistic simplification.
