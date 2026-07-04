---
name: context-brief
description: Use when preparing a compact handoff, task brief, implementation context, or review packet before a complex change, PR review, debugging session, or agent delegation.
---

# Context Brief

Create a bounded brief that lets another pass work from evidence instead of chat history.

## Process

1. State the goal in one or two sentences.
2. Capture constraints: scope, non-goals, deadlines, risky areas, and user preferences that affect execution.
3. List relevant files, commands, tickets, PRs, docs, and external references with why each matters.
4. Summarize observed facts separately from assumptions.
5. Identify open questions that block safe implementation or review.
6. Recommend the next action: implement, investigate, review, ask the user, or stop.

## Output

Use this shape unless the user asks for another format:

```markdown
## Goal
<what needs to happen>

## Constraints
- <scope, non-goals, verification, timing, ownership>

## Evidence
- `<path or command>` - <why it matters>

## Facts
- <verified fact>

## Assumptions
- <assumption and why it is acceptable or risky>

## Open Questions
- <question or "None">

## Recommended Next Step
<one concrete next action>
```

Keep the brief compact. Do not paste large file contents, transcripts, or full diffs. Link to local files and quote only the lines needed to make the handoff actionable.
