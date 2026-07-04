---
name: Backend Standards
description: Backend, API, database, and reliability guidance.
applyTo: "**/*.ts,**/*.js,**/*.sql"
---

# Backend Standards

Follow existing API and persistence patterns.

Prefer:

- explicit input validation
- narrow database queries
- clear transaction boundaries
- typed API contracts
- idempotent mutations where retries are possible
- structured error handling
- observable failure paths

Avoid:

- leaking internal errors to clients
- swallowing errors without context
- adding retries around logic bugs
- broad data fetches that create avoidable N+1 behavior
- schema changes without migration and rollback consideration

For SQL, prefer readable queries, explicit indexes for new access paths, and constraints that encode real invariants.

