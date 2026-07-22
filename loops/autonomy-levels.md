# Loop autonomy levels

Autonomy is a declaration of permitted behavior, not a claim that a runtime
exists. A loop must state its level and obey that level even when a tool could
technically perform more actions.

## L0 — Documented

The workflow is described but is not expected to execute as a repeatable
operational loop.

## L1 — Report Only

An L1 loop may inspect, analyze, classify, run read-only checks, update its local
state, produce a report, and recommend an action.

It may not edit product code, create commits, push branches, create or update
pull requests, post comments, change issues, modify dependencies, or merge
anything.

## L2 — Assisted Action

L2 is documented conceptually only. Small, bounded changes may be prepared, but a
human approval gate is required before any outbound or persistent action.

## L3 — Unattended

L3 is documented conceptually only and is intentionally unsupported by this
repository. It requires independent verification, strict budgets, observability,
allowlists, kill switches, and operational ownership.

> This PR implements only L0 and L1 contracts. L2 and L3 are architectural
> placeholders, not supported execution modes.
