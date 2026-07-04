# RFC: Reliable outbound webhook delivery

> Example output of the `rfc` skill. Fictional scenario. See
> [`docs/principles/documents.md`](../docs/principles/documents.md) for the format.

## Problem Statement

We deliver outbound webhooks to customer endpoints synchronously, inside the HTTP
handler that produces the event. When a subscriber is slow, our own request
latency rises with theirs; when a subscriber is down, the event is lost with no
retry. We have no delivery guarantee, no visibility into failures, and customer
support tickets asking "why didn't I get the event" that we cannot answer.

## Context

The API is a modular monolith on Node.js with a PostgreSQL primary. Events are
produced inside existing request transactions. There is no message broker in the
stack today. Traffic is ~50 webhook sends per second at peak, bursty around
customer batch operations. The team is three engineers; nobody owns
infrastructure full-time. Deploys are containerized behind a standard platform.

## Constraints

- No dedicated ops/infra headcount. New infrastructure must be near-zero to
  operate.
- Delivery must survive a process crash — an accepted event must not be lost.
- Must not extend the producing request's latency. Sending happens after commit.
- Budget for new managed services this quarter is effectively zero.

## Assumptions

- Peak throughput stays under ~200 sends/sec for the next 12 months. (Refutable:
  a large customer onboarding could break this.)
- At-least-once delivery is acceptable; subscribers are expected to be
  idempotent, and we already document that. (Refutable if a subscriber complains.)
- PostgreSQL remains the primary datastore and has headroom for a modest write
  and polling load.

## Options

1. **Status quo** — keep synchronous in-request delivery.
2. **Managed cloud queue** — push events to a hosted queue (e.g. SQS) with a
   separate worker fleet.
3. **Redis-backed queue** — introduce Redis and a job library (e.g. BullMQ), run
   a worker process.
4. **Postgres-backed queue** — a `webhook_deliveries` table drained by a worker
   using `SELECT … FOR UPDATE SKIP LOCKED`.

## Trade-offs

| Option | Dev cost | Ops cost | Time-to-value | Reversibility | Delivery guarantee |
| --- | --- | --- | --- | --- | --- |
| 1. Status quo | none | none | n/a | n/a | none (lossy) |
| 2. Managed queue | medium | medium (new service, IAM, DLQ) | weeks | medium | strong |
| 3. Redis queue | medium | high (new stateful component to run/patch/back up) | weeks | medium | strong (if Redis persists) |
| 4. Postgres queue | low-medium | near-zero (reuses primary) | days | high (drop a table) | strong (transactional with the event) |

## Recommendation

**Option 4, a Postgres-backed queue via `SKIP LOCKED`.**

Against the status quo, it fixes the actual problem: durability and retries.
Against option 2, it adds no managed service, no new IAM surface, and no
dead-letter plumbing to learn, while our throughput sits two orders of magnitude
below where a database queue struggles. Against option 3, it avoids standing up a
new stateful component that someone has to run, patch, and back up — the exact
cost we can't absorb with no infra headcount. It also gets a property the two
brokers don't hand us for free: the delivery row is written **in the same
transaction** as the event, so we can't commit an event and lose its webhook.

The pattern is well understood and boring, which for a three-person team is a
feature. If throughput or fan-out later outgrows it, options 2 and 3 remain open
— the worker interface stays the same behind either.

## Risks

- **Polling load on the primary.** A tight poll loop adds query volume to the
  main database. Mitigation: `FOR UPDATE SKIP LOCKED` with a short backoff when
  the queue is empty; monitor primary load and tune the interval.
- **Throughput ceiling reached sooner than assumed.** A single large customer
  could push us past the assumed range. Mitigation: the ceiling is a metric, not
  a surprise — alert on queue depth and oldest-pending age; the migration path to
  a broker is pre-identified.
- **Poison messages.** A permanently failing endpoint retried forever wastes
  cycles. Mitigation: max-attempts cap, then mark `failed` and stop.

## Migration Strategy

1. Add the `webhook_deliveries` table and write rows inside the existing event
   transaction, alongside the current synchronous send (dual-write, send still
   authoritative).
2. Ship the worker; have it drain the table. Compare delivered-by-worker against
   delivered-synchronously in logs for one week.
3. Cut over: remove the synchronous send, the worker is now authoritative.
4. **Rollback criterion:** if worker-delivered rate lags synchronous by more than
   1% or oldest-pending age exceeds 60s under normal load, revert step 3 and keep
   the synchronous path while we diagnose.

## Open Questions

- Retry schedule: fixed backoff or exponential with jitter? (Leaning
  exponential, capped.)
- Do we expose delivery status to customers in the dashboard now, or log-only for
  v1?
- Retention: how long do we keep `delivered` rows before archiving?
