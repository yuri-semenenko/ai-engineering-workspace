---
name: codebase-map
description: Use when orienting in an unfamiliar repo or subsystem, reviewing code you don't own, or preparing to work safely in a codebase you don't know yet. Produces a short, high-signal map: what it is, entry points, architecture, domain glossary, key seams, risky areas, and how to run and test — evidence over guesses.
---

# Codebase Map

Build a fast, honest orientation to code you don't know yet, so you can work in it safely. Reconnaissance for comprehension: what the code is, where it starts, how it flows, and what not to touch. A map, not a tour — pointers over prose, evidence over guesses.

## What The Map Captures

- What it is: one paragraph of purpose and domain, from the README and the code, not marketing.
- Entry points: where execution starts — server/main, routes, CLI, cron/queue workers, build entry. The "start here" files.
- Architecture sketch: the few layers or modules that matter and how data flows between them. Not a file tree.
- Domain glossary: the 5-15 recurring domain nouns and verbs, one line each — the ubiquitous language.
- Key seams: the stable interfaces where behavior is substituted or extended (see module-design).
- Risky / don't-touch: load-bearing, security-sensitive, or fragile code, and invariants not to regress. Mark it, do not fix it.
- How to run and test: build/dev/test/single-test commands, local setup, env vars — from repo evidence, not guesses.
- Known tradeoffs: existing TRADEOFF annotations, TODOs of record, documented debt.

## Guardrails

- Read evidence; do not invent structure. Flag uncertainty rather than guessing.
- Comprehension, not critique: this is not an over-engineering audit.
- Respect Chesterton's Fence: unclear or load-bearing code is "risky", not "delete me".
- Keep it short and proportional (~80-150 lines). A map longer than the territory is useless.
- Distinct from project-onboarding (which writes a durable AGENTS.md for the agent; this orients a reader first and can feed it) and failure-investigation (which drives a known failure).
