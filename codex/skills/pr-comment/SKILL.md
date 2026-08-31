---
name: pr-comment
description: Use when drafting a pull-request description or the body for `gh pr create`. Fills the repository's own PR template and returns it as a copy-pasteable raw markdown block.
---

# PR Comment

Generate the body for a pull request from the current branch's changes. Write it in English unless the user explicitly asks otherwise.

## Steps

1. Read the repository's PR template if present (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, or under `.github/PULL_REQUEST_TEMPLATE/`). Mirror its sections exactly; do not invent a Summary or Test plan layout when the repository ships its own template.
2. Inspect the change: `git diff --stat HEAD` plus the actual diff. Derive the ticket key from the branch name when it encodes one.
3. Fill each section concisely: what changed and why, the ticket link (write `N/A` if none), and concrete runnable test steps. For UI work, add a placeholder line for a screenshot or recording.

## Output

Print the finished body as a single raw markdown fenced block so it can be pasted verbatim into GitHub, never as rendered prose. Use a four-backtick fence if the body itself contains triple-backtick fences. Any caveat, such as an assumed ticket domain, goes on one line after the block and outside the fence.

Never append an AI-attribution footer to the PR body. The body ends at the template's own last section.
