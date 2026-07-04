---
name: feedback-test-database
description: "EXAMPLE (fictional): integration tests must hit a real database, not mocks."
metadata:
  node_type: memory
  type: feedback
---

Integration tests must run against a real database, not a mocked one.

**Why:** A mocked data layer once passed CI while a real migration was broken, so the failure only surfaced in production. The team no longer trusts mocked persistence in integration tests.

**How to apply:** When writing or reviewing integration tests, use a real (containerized or ephemeral) database. Reserve mocks for pure unit tests where persistence is not under test.
