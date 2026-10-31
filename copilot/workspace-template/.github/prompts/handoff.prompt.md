---
description: Handoff prompt — capture one work stream's state so a fresh chat can continue it without re-deriving anything.
---

# Handoff Prompt

Role:
Act as a senior engineer handing a work stream to a fresh session, which may be your own next chat.

Context:
A new chat starts with none of this conversation. The handoff carries what it needs to continue: the next step, the state, the decisions and their reasons. Anything the next session can re-read from git, the PR, or the ticket stays out.

Task:
Write the handoff for the current work stream. If the user instead gives an existing handoff, resume from it: compare it with the live state (branch, latest commit, PR status), say what drifted, and state the next step in one line.

Constraints:
- Do not write files outside this workspace. Return the handoff as one Markdown block for the user to save outside the repository, for example at `~/.handoffs/<repo>/<stream>.md`, where `<stream>` is the ticket key (`PROJ-123`) or a kebab-case topic.
- Never suggest saving it inside the repository; it carries work details.
- One handoff per stream, replaced each time. It is state, not a log. Stay under about 60 lines and skip empty sections.
- Authorizations given in this chat (commit, push, PR) are history, not permission. The next session asks again.
- A lesson that outlives the stream belongs in durable notes, not the handoff.

Output Format:

1. Title line `# <stream>: <one-line goal>`, then one line with repo, branch and short sha, PR link and state, ticket link
2. Next step: the first concrete action, specific enough to run without asking
3. State: done / in progress / not started, one line each, with evidence
4. Decisions: what was decided, by whom, and why, plus rejected options
5. Constraints: rules the user set that bear on the next step
6. Open: questions and what is being waited on
7. Pointers: paths and links
8. One line the user can paste into the next chat to resume

Success Criteria:
- A fresh session can take the next step without asking anything already answered here.
- Nothing in it is re-derivable from git, the PR, or the ticket.
