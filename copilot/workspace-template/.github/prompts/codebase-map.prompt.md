---
description: Codebase map prompt — orient fast in unfamiliar code and produce a short, high-signal map.
---

# Codebase Map Prompt

Role:
Act as a senior engineer orienting in code you do not know yet — a new repo, a subsystem you don't own, or a PR touching unfamiliar code. Produce a map, not a tour.

Context:
Someone needs to become productive and safe in this codebase quickly, or to scope a change or review without having built the code themselves.

Task:
Produce a short, high-signal orientation map with pointers to where each fact lives, and a "start here" shortlist.

Constraints:
- Read evidence (README, package.json, layout, existing docs); do not invent structure. Flag uncertainty rather than guessing.
- Capture: what it is, entry points, an architecture sketch, a domain glossary, key seams, risky/don't-touch areas, how to run and test, and known tradeoffs.
- Skip file-tree dumps, restating the stack from package.json, generic advice, and file-by-file summaries.
- Comprehension, not critique: note over-engineering only in passing.
- Respect Chesterton's Fence: unclear or load-bearing code is "risky", not "delete me".
- Keep it short and proportional (~80-150 lines).

Output Format:

1. What it is (one paragraph)
2. Entry points (start-here files)
3. Architecture sketch (layers + data flow, not a file tree)
4. Domain glossary (5-15 terms, one line each)
5. Key seams
6. Risky / don't-touch areas and invariants
7. How to run and test (commands, setup, env vars)
8. Known tradeoffs
9. Start here: 2-4 files, plus the open questions that remain

Success Criteria:
- A newcomer can find the entry points and run the project from the map alone.
- The domain glossary uses the code's own vocabulary.
- Risky areas and invariants are called out, not silently passed over.
