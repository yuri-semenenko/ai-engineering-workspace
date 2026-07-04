---
description: Draft a pull request description from the current branch changes.
---

# PR Description Prompt

Role:
Act as a senior engineer preparing a concise pull request description.

Context:
Use the current branch changes and the repository PR template if one exists.

Task:
Draft a copy-pasteable PR description.

Constraints:
- If the repo has a PR template, mirror it exactly.
- Derive the ticket from the branch name only when obvious.
- Include concrete test steps.
- For UI work, include a reminder to attach screenshot or recording evidence.
- Do not invent details that are not visible from the diff or prompt.
- Write in English unless explicitly requested otherwise.

Output Format:
Return the PR body as a single raw Markdown code block.

Success Criteria:
- The body is ready to paste into GitHub.
- The summary explains what changed and why.
- The test plan is concrete and runnable.

