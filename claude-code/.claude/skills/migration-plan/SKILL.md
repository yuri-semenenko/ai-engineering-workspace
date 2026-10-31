---
name: migration-plan
argument-hint: "[what you're migrating from -> to]"
description: Turn a risky migration or refactor into a safe, incremental, reversible plan that keeps user-visible behavior stable — framework upgrades, design-system swaps, API version migrations, legacy replacement. Use for "plan this migration", "how do I migrate X to Y safely", "refactor plan for", "strangler plan", "migrate from A to B", "спланируй миграцию", "как безопасно перейти на".
---

# Migration Plan

Sequence a migration so the system stays releasable and reversible at every step, and user-visible behavior does not change. A migration is not a redesign: behavior-preserving by default, new features kept out of it. Prefer many small reversible steps over one big cutover. This sequences the move; shaping the target interface is `/module-design`.

## The loop

1. **Pin the invariant.** State the user-visible behavior that must not change while the migration runs. This is the safety contract; every step serves it. Capture it as characterization tests or golden output before touching anything.
2. **Map current to target, and name the seam.** Where you are, where you are going, and the boundary you will migrate across (see /module-design). If there is no clean seam yet, creating one is the first slice.
3. **Choose the migration shape and justify it.** Strangler (route work old to new incrementally), adapter / compatibility layer (new behind the interface the old callers already use), expand-contract (add the new, migrate readers, then remove the old), or branch-by-abstraction. Pick per blast radius; say why.
4. **Slice it.** Vertical, independently shippable steps. Each is small, leaves the system releasable, and sits behind a flag if it is user-facing. No big-bang cutover; if one is unavoidable, say why and how you rehearse it.
5. **Gate each slice with before/after verification.** Each slice proves the invariant holds against the characterization captured in step 1. A slice that cannot be verified is not ready.
6. **Plan rollout and rollback.** Feature flag with a removal trigger and date, staged or canary rollout, and explicit rollback criteria per slice (the signal that reverts it). For a step that writes data or external state (a backfill, a dual write, a sync job), also state what a rerun after a partial failure does: it is idempotent, it detects finished work and skips it, or it needs a named recovery procedure. Do not assume idempotency, and do not count a retry as a rollback; they are separate plans. Removing the flag and the dead old path is the final slice, not an afterthought.
7. **Sequence by dependency and risk.** Order the slices, and call out the single highest-risk or least-reversible step with how you de-risk it.

## Rules

- Behavior-preserving by default. Keep new behavior or features as a separate change, after the migration.
- Every slice independently shippable and reversible. No step that can only be undone by a second migration.
- Feature flags are temporary: name the removal trigger and date when you add one, and mark it with the `TRADEOFF(...)` convention so /debt-ledger tracks the cleanup.
- Consumes an RFC decision; do not re-litigate whether to migrate here.

## Delegation

Delegate the mapping, keep the risk judgment. Hand the read-only inventory to a cheaper-tier subagent — find every call site and usage of what you are migrating, locate the seam, capture the characterization of current behavior — returning a compact map. Keep on the main model the parts that need judgment: pinning the invariant, choosing the migration shape, sequencing the slices, and the rollback criteria. A green characterization run is evidence the behavior held, not proof the plan is safe.

## Output

A migration plan: the invariant and how it is captured, current-to-target with the seam, the chosen shape with its justification, the ordered slices (each with its verification, flag, rollback criteria, and rerun behavior where it writes state), and the rollout plus flag-cleanup sequence. End with the highest-risk step and its mitigation. English prose, no em dashes, per persona.
