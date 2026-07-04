# PR review: Webhook delivery worker

> Example output of the `pr-classify` skill. Fictional PR. See
> [`docs/principles/review-discipline.md`](../docs/principles/review-discipline.md)
> for the classification scheme. This reviews the implementation of the decision
> in [`adr-sample.md`](./adr-sample.md).
>
> The findings reference an imagined diff (file:line as it would appear on the
> PR). The point is the triage, not the code.

## Summary

The PR adds the `webhook_deliveries` table, the worker drain loop with
`SKIP LOCKED`, and exponential-backoff retries, matching ADR-0001. The shape is
right and the SKIP LOCKED query is correct. Two issues block merge: the delivery
row is written outside the event transaction (defeating the ADR's core
guarantee), and a failed HTTP call is treated as a permanent failure. Verdict
below.

## Critical

- `src/events/publish.ts:88` — the `webhook_deliveries` insert runs in its own
  transaction *after* the event transaction commits, not inside it. If the
  process dies between the two commits, the event is persisted with no delivery
  row and the webhook is lost silently. This is the exact failure ADR-0001 exists
  to prevent. Move the insert into the event's transaction (pass the same
  client/tx into the publisher).
- `src/workers/webhook.ts:64` — a non-2xx response and a thrown network error are
  both routed to the `failed` branch, which stops retrying. A 503 or a timeout is
  transient and must be retried; only a 4xx (client-permanent) or exhausted
  attempts should mark `failed`. As written, one subscriber blip permanently
  drops delivery.

## Important

- `src/workers/webhook.ts:41` — the drain loop polls with a fixed 100ms interval
  regardless of queue state, so an empty queue hammers the primary ~10x/sec per
  worker. Add the backoff-on-empty the RFC called out as the mitigation for
  polling load.
- `src/workers/webhook.ts:112` — no upper bound on attempts. `attempt_count`
  increments but nothing caps it, so a permanently-down endpoint is retried
  forever. ADR-0001 specifies a max-attempts cap; enforce it here.
- `test/webhook.test.ts` — tests cover the happy path (2xx delivers) only. The
  retry-on-transient and give-up-after-max-attempts branches are the whole point
  of this change and are untested. Per the failing-test-first rule, the retry
  behavior needs a test that would fail against the current `:64` bug.

## Optional

- `src/workers/webhook.ts:70` — `const r = await fetch(...)` reads faster as
  `response`. Minor, take it or leave it.

## Verdict

**Request changes** — the transaction boundary (`publish.ts:88`) and the
transient-vs-permanent failure handling (`webhook.ts:64`) are correctness issues
that undo the guarantees the change was built to provide.
