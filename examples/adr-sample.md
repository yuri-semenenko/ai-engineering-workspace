# ADR-0001: Use a Postgres-backed queue for outbound webhooks

> Example output of the `adr` skill. Fictional scenario. See
> [`docs/principles/documents.md`](../docs/principles/documents.md) for the format.
> This is the decision that came out of [`rfc-sample.md`](./rfc-sample.md).

- **Status:** Accepted
- **Date:** 2026-07-04
- **Deciders:** Backend team

## Context

Outbound webhooks were delivered synchronously inside the producing request:
slow subscribers raised our latency, failed ones lost the event, and we had no
retries or failure visibility. We run a Node.js modular monolith on PostgreSQL
with no message broker and no dedicated infra headcount. Peak load is modest
(~50 sends/sec). An RFC weighed the status quo, a managed cloud queue, a
Redis-backed queue, and a Postgres-backed queue.

## Decision

We will implement outbound webhook delivery as a `webhook_deliveries` table
drained by a worker using `SELECT … FOR UPDATE SKIP LOCKED`. Delivery rows are
inserted in the same transaction as the event they describe. Retries use capped
exponential backoff; after a maximum number of attempts a row is marked `failed`.

## Consequences

### Positive
- An event and its delivery record commit atomically — we cannot accept an event
  and lose its webhook.
- No new infrastructure to run, patch, or back up. Operational cost stays near
  zero, which matches our headcount.
- Trivially reversible: the mechanism is one table and one worker.

### Negative
- Adds polling query load to the primary database. Requires a backoff on empty
  and monitoring of primary load.
- Has a throughput ceiling below what a dedicated broker offers.

### Neutral
- New contributors need to know delivery is asynchronous and at-least-once, so
  subscribers must be idempotent (already documented).
- Queue depth and oldest-pending age become operational metrics we alert on.

## Alternatives Considered

- **Managed cloud queue (e.g. SQS).** Rejected for this stage: adds a managed
  service, IAM surface, and dead-letter plumbing we don't need at 50 sends/sec.
- **Redis-backed queue.** Rejected: a new stateful component to operate with no
  infra headcount, for no benefit over Postgres at our scale.
- **Status quo (synchronous).** Rejected: it is the problem — lossy, no retries,
  couples our latency to the subscriber's.

## References

- [`examples/rfc-sample.md`](./rfc-sample.md) — the RFC this decision resolves.
- PostgreSQL docs: `SELECT … FOR UPDATE … SKIP LOCKED`.

---

_Immutable once accepted. If we move to a broker later, that will be a new ADR
superseding this one, not an edit here._
