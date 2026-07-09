---
description: Migration plan prompt — sequence a risky migration into safe, reversible slices that keep user-visible behavior stable.
---

# Migration Plan Prompt

Role:
Act as a senior engineer planning a risky migration or refactor — a framework upgrade, design-system swap, API version migration, or legacy-to-modern replacement.

Context:
The decision to migrate has been made (an RFC or equivalent). What is needed now is the executable plan: how to get there safely and reversibly without changing user-visible behavior.

Task:
Produce a migration plan that sequences the work into small, independently shippable, reversible slices.

Constraints:
- Behavior-preserving by default. Keep new behavior or features as a separate change, after the migration.
- Every slice must be independently shippable and reversible; no step that can only be undone by a second migration.
- Capture the invariant (user-visible behavior that must not change) as characterization tests or golden output before touching anything.
- Feature flags are temporary: name the removal trigger and date when you add one.
- Prefer incremental over big-bang; if a big-bang cutover is unavoidable, say why and how you rehearse it.

Output Format:

1. The invariant, and how it is captured (characterization tests / golden output)
2. Current to target, and the seam you migrate across
3. Migration shape and why: strangler / adapter / expand-contract / branch-by-abstraction
4. Ordered slices, each with its before/after verification, flag, and rollback criteria
5. Rollout and rollback plan, ending with flag and dead-code cleanup
6. The highest-risk or least-reversible step, and its mitigation

Success Criteria:
- The system is releasable and reversible after every slice.
- User-visible behavior is provably unchanged at each step.
- Every feature flag has a named removal trigger.
