---
name: spec
description: Write a minimal spec — goal, non-goals, acceptance criteria, open questions — before implementing a feature or change. Use when the user asks to "spec this", "напиши спеку", "what does done mean here", "acceptance criteria for X", or before starting a non-trivial implementation without a clear definition of done. Different from /rfc (explores architecture options, 10 sections) and /adr (records a decision already made) — /spec pins down what "done" means for one concrete change, in five to twenty lines. Its acceptance criteria become the input for /verify.
argument-hint: "[feature or task to spec]"
---

# Spec

Pin down what "done" means before writing code. Even a five-line spec beats none: it forces the boundary question (what are we *not* doing?) and gives `/verify` something concrete to check against. This is the lightweight entry to the Define phase — reach for `/rfc` only when there are genuinely competing architectural options to weigh.

## Rationalizations

| Rationalization | Rebuttal |
|---|---|
| "Task too simple for a spec." | Acceptance criteria apply at any scale. A simple task gets a five-line spec, not zero. |
| "The requirements are obvious from the ask." | Then writing them down costs a minute and catches the one place they weren't. |
| "We'll figure out the edge cases while coding." | Edge cases decided mid-implementation default to whatever is easiest to code, not what's right. |
| "A spec will slow us down." | Rework from a misunderstood requirement is slower than twenty lines of markdown. |

## Format

```markdown
## Goal
<1-2 sentences: the user-visible outcome, not the implementation.>

## Non-goals
<What this change deliberately does NOT do. The scope fence —
anything here appearing in the diff is scope creep.>

## Acceptance criteria
<Testable statements. Each one either passes or fails — no "works well".
- [ ] <observable behavior, ideally with concrete input → output>
- [ ] <error/edge case behavior>>

## Open questions
<Anything blocking or ambiguous. If a question changes the approach,
resolve it before coding; otherwise note the assumption and proceed.>
```

## Rules

- **Proportional depth.** Five lines for a small fix, ~20 for a feature. If it wants more than a page, the task is either too big (split it) or architectural (use `/rfc`).
- **Criteria must be falsifiable.** "Fast", "clean", "user-friendly" are not criteria. "P95 under 200ms", "keyboard-navigable" are.
- **Non-goals are load-bearing.** They are the scope-discipline contract: the implementation touches only what the spec names.
- **Surface assumptions explicitly** (per persona). An unstated assumption in a spec is a bug filed in advance.
- **Hand off to verification.** When implementation ends, walk the acceptance criteria as the `/verify` checklist — each unchecked box is unfinished work, not a footnote.

## Output

The spec in the format above, in the conversation (or written to a file if the user names a location). If open questions block the approach, ask them before proposing implementation. Otherwise end with the spec and wait — writing the spec is not permission to start coding.
