---
name: prompt-engineer
description: Use when creating, rewriting, or reviewing prompts for AI agents, copilots, reusable workflows, RFC/review prompts, or ambiguous tasks that need stronger context, constraints, success criteria, and output structure.
---

# Prompt Engineer

Turn rough intent into a structured, decision-oriented prompt for an AI agent.

## Principles

- Structure prompts as goal, context, task, constraints, output format, and success criteria.
- Make assumptions and boundaries explicit.
- Use concrete examples only when they clarify behavior.
- Keep prompts token-efficient.
- Avoid generic role filler such as "You are a helpful assistant."
- Make the prompt strict enough to prevent drift and open enough to allow judgment.

## Output Structure

Generate prompts with these sections:

1. **Role** — what kind of agent should answer.
2. **Context** — what the agent must know.
3. **Task** — the concrete job.
4. **Constraints** — required behavior and forbidden behavior.
5. **Output Format** — exact response shape.
6. **Success Criteria** — how the result will be judged.
7. **Edge Cases / Anti-patterns** — common failure modes to avoid.

Mirror the user's language in the surrounding response. Generate the prompt itself in English unless the user asks otherwise.

## Quality Bar

- Drive clarity, decisions, risks, dependencies, and ownership.
- Include assumptions and explicit non-goals.
- Ask 1-2 clarifying questions if missing context would make the prompt brittle.
- Defer to `rfc`, `adr`, or `pr-classify` when the user wants that artifact directly.
