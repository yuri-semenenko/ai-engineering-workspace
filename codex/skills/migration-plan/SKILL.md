---
name: migration-plan
description: Use when planning a risky migration or refactor — framework upgrades, design-system swaps, API version migrations, legacy-to-modern replacement — into a safe, incremental, reversible sequence that keeps user-visible behavior stable. Produces the invariant, a seam, a migration shape, verified slices, and a rollout plus rollback plan.
---

# Migration Plan

Sequence a migration so the system stays releasable and reversible at every step, and user-visible behavior does not change. A migration is not a redesign: behavior-preserving by default, new features kept out of it. Prefer many small reversible steps over one big cutover.

## The Loop

1. Pin the invariant: the user-visible behavior that must not change. Capture it as characterization tests or golden output before touching anything.
2. Map current to target and name the seam you will migrate across (see module-design). If there is no clean seam, creating one is the first slice.
3. Choose the migration shape and justify it: strangler, adapter / compatibility layer, expand-contract, or branch-by-abstraction. Pick per blast radius.
4. Slice it: vertical, independently shippable steps, each small, each leaving the system releasable, each behind a flag if user-facing. No big-bang cutover.
5. Gate each slice with before/after verification against the invariant. A slice that cannot be verified is not ready.
6. Plan rollout and rollback: feature flag with a removal trigger and date, staged or canary rollout, explicit rollback criteria per slice. Removing the flag and the dead old path is the final slice.
7. Sequence by dependency and risk; call out the highest-risk or least-reversible step and how you de-risk it.

## Guardrails

- Behavior-preserving by default. Keep new behavior or features as a separate change, after the migration.
- Every slice independently shippable and reversible. No step undone only by a second migration.
- Feature flags are temporary: name the removal trigger and date, and mark it with TRADEOFF so the cleanup is tracked.
- Consumes an RFC decision; do not re-litigate whether to migrate. Distinct from rfc (decides whether and what) and module-design (shapes the target interface).
- Delegate the read-only inventory and characterization (call sites, seam, current behavior) to a cheaper-tier subagent; keep the invariant, migration shape, sequencing, and rollback criteria on the main model.
