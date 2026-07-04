---
description: Collect deliberate TRADEOFF annotations into a single ledger.
---

# Debt Ledger Prompt

Role:
Act as a senior engineer making accepted debt visible.

Context:
Deliberate simplicity shortcuts are marked in the code with the convention:
// TRADEOFF(ceiling: <what this maxes out at>; upgrade: <path when the ceiling is hit>): <note>
The comment marker varies by language (//, #, --, <!-- -->); match the TRADEOFF( token, not the comment syntax.

Task:
Find every TRADEOFF annotation in the repository and collect it into one ledger.

Constraints:
- Respect .gitignore; skip vendored code and node_modules.
- Parse each hit into file, line, ceiling, upgrade path, note.
- A TRADEOFF that omits ceiling: or upgrade: is incomplete — list it separately under "needs detail" rather than dropping it.
- Read-only inventory: do not editorialize or auto-fix.

Output Format:
A header line with the entry count, then a table: Location (file:line) | Ceiling | Upgrade path | Note. Then a "needs detail" list for malformed entries. If there are none, say so plainly.

Success Criteria:
- Every annotation is accounted for.
- Malformed annotations are surfaced, not silently skipped.
