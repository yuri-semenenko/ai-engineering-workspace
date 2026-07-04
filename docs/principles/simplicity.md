# Simplicity

The strongest bias in the canon: **prefer the simplest solution that satisfies
the requirement, and do not introduce abstractions before they are needed.**
Most of what follows is machinery to keep that bias honest when an assistant —
which is happy to generate any amount of code — is doing the typing.

## The laziest solution that works

Before writing code, walk a decision ladder and stop at the first rung that
satisfies the requirement:

1. **Does this need to exist at all?** (YAGNI) The cheapest code is the code you
   don't write.
2. **Does the standard library solve it?**
3. **Does a native platform feature solve it?** A browser API, a database
   constraint, an OS tool, a framework primitive.
4. **Does an already-installed dependency solve it?** Do not add a dependency for
   a few lines.
5. **Can it be one line?**
6. **Only then, write the smallest working version.**

"Lazy" here is a discipline, not a corner-cut. Laziness avoids *unnecessary*
work. It never simplifies away validation, error handling, security,
accessibility, or an explicitly requested feature. Those are the requirement, not
the overhead.

The `lazy` skill runs this ladder *before* code is written, at intensity
`lite | full | ultra`. The `simplify` skill cleans up a diff *after* the fact.
Reach for the first when starting; the second when reviewing your own change.

## Marking deliberate tradeoffs

Sometimes the right call is to ship something simpler than ideal. When you do,
mark it inline so the debt stays visible and greppable instead of decaying into
an anonymous `TODO`:

```
// TRADEOFF(ceiling: <what this maxes out at>; upgrade: <path when the ceiling is hit>): <note>
```

Name two things: the **ceiling** (when this stops being enough) and the
**upgrade path** (what to do then). A tradeoff you can articulate is an
engineering decision. A tradeoff you can't is technical debt you'll rediscover in
production.

The `debt-ledger` skill collects every `TRADEOFF(...)` annotation across a tree
into one ledger, so accepted debt can be reviewed as a set instead of stumbled
into one file at a time.

## The anti-patterns

The canon names these explicitly so an assistant will challenge them in its own
output, not wait for review to catch them:

- Premature optimization
- Premature abstraction
- Over-engineering
- Hidden complexity
- Tight coupling
- Leaky abstractions
- Framework-driven architecture
- Accidental complexity
- Architecture astronautics

The `complexity-audit` skill scans a whole tree for the structural members of
that list — speculative generality, wrapper-only modules, indirection without
payoff, dead config and flags — and returns a deletion-oriented report. It
complements per-diff review: review asks "is this change good?"; the audit asks
"where are we already over-built?"

## Simplicity is contextual

None of this is a mandate to under-build. The canon is equally explicit that
there are no universal best practices, and that the right amount of structure
depends on team maturity, project stage, product goals, delivery pressure, and
existing constraints. An MVP optimizes for fast learning and accepts temporary
shortcuts; a long-lived system optimizes for maintainability and refuses them.
The simplicity ladder tells you where to *start*; context tells you when to climb
higher.
