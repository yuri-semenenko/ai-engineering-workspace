# Engineering documents

Three of the skills produce written artifacts — `rfc`, `adr`, `spec`. They look
similar from a distance and are constantly confused. They answer different
questions at different moments, and using the wrong one wastes effort or freezes
a decision that isn't made yet.

## When to use which

| | Question it answers | State of the decision | Length |
| --- | --- | --- | --- |
| **Spec** | What does "done" mean for this one change? | Not a decision — a definition of scope | 5-20 lines |
| **RFC** | Which approach should we take, and why? | Open. Options still on the table | Multi-section |
| **ADR** | Why did we choose what we chose? | Closed. Decision already made | One page |

The natural sequence when a change is non-trivial: a **spec** pins down what done
means, an **RFC** explores how to get there if the approach is contested, and an
**ADR** records the choice once it's settled. Small changes need only the spec.
Obvious approaches skip the RFC. Not every decision earns an ADR — only the ones
a future reader will question.

## Spec — define done before building

A spec is the smallest useful planning artifact: **goal, non-goals, acceptance
criteria, open questions.** It exists to stop implementation from starting
without a definition of done. Its acceptance criteria become the input to
verification — you cannot verify a change whose success was never stated.

Reach for it before any non-trivial implementation. If you can't write the
acceptance criteria, you don't yet understand the task well enough to build it.

## RFC — explore options, commit to none yet

An RFC is for a decision that is still open and worth arguing in writing. The
canon fixes a ten-section format so nothing important gets skipped:

1. Problem Statement
2. Context
3. Constraints
4. Assumptions
5. Options
6. Trade-offs
7. Recommendation
8. Risks
9. Migration Strategy
10. Open Questions

The rules that keep an RFC honest:

- **Always surface 2-4 realistic options**, including the status quo / do-nothing
  option when that's honest. A single option presented as "the" answer is a
  decision smuggled in as a document.
- **Trade-offs are concrete** — dev cost, operational complexity, blast radius if
  it fails — in a table, not marketing prose.
- **The recommendation justifies itself against the other options**, not in
  isolation.
- **Risks are not trade-offs.** A trade-off is what you knowingly give up. A risk
  is what could go wrong despite choosing correctly.

See [`examples/rfc-sample.md`](../../examples/rfc-sample.md) for the format
applied to a real decision.

## ADR — record the decision for the reader six months out

An ADR captures a decision *already made*, for the teammate who will later ask
"why is it built this way?" It is not exploratory. If options are still being
weighed, that's an RFC, not an ADR.

The default structure: **Context** (the forces at play, past tense),
**Decision** (the choice, present tense, one paragraph), **Consequences**
(positive, negative, neutral, future tense), **Alternatives Considered** (one or
two sentences each, why rejected), **References**.

Two rules matter most:

- **One decision per ADR.** Two decisions are two ADRs.
- **Immutable after acceptance.** When a decision changes, write a new ADR that
  supersedes the old one. Never silently edit a settled decision — the point of
  the record is that it reflects what was true and known at the time.

This repository dogfoods the format: see [`adr/`](../../adr/) for the decisions
behind the kit's own architecture, and [`examples/adr-sample.md`](../../examples/adr-sample.md)
for a standalone example.

## The frame underneath all three

Every one of these documents is an application of the same decision-making frame
the canon uses everywhere:

**Problem → Context → Constraints → Options → Trade-offs → Recommendation →
Risks → Next Steps.**

An RFC is that frame written out in full. An ADR is its conclusion, preserved. A
spec is its front half, before options even matter. Learn the frame and the
documents stop being three formats to memorize and become three depths of the
same habit.
