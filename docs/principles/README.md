# Principles

This is the methodology the kit exists to carry. The persona file and the skills
are how it reaches each assistant; this directory is where it is argued in prose,
so you can read, disagree with, and adapt it without opening a single config file.

## The premise

AI coding assistants change on a monthly cadence. Model families, context
windows, tool APIs, the names of the config files, which vendor your employer
approves this quarter — all of it moves. Engineering judgment does not. The way a
senior engineer decides whether an abstraction should exist, how they classify
review feedback, when they write an RFC instead of just coding, what "done" means
before they close a task — those outlast any tool.

So the kit encodes the durable layer once and treats the assistant as a
replaceable consumer of it:

> One engineering workflow. Multiple AI tools.

If a better assistant ships next quarter, you add an install target. You do not
relearn how you work.

## Engineering first, AI second

This is a methodology that happens to run inside AI assistants, not a collection
of prompts. The distinction is concrete, not cosmetic:

- A **prompt collection** optimizes a model's output for a task ("write me a
  React component that…"). It is tied to the phrasing, the model, and the moment.
- A **methodology** encodes how decisions get made ("before writing code, walk
  the simplicity ladder"; "classify every review finding by the cost of ignoring
  it"). It is tied to engineering, and it transfers to any assistant that can
  read instructions.

Everything in this repository is the second kind. The skills are named for
engineering activities — `rfc`, `adr`, `spec`, `pr-classify`, `security-pass` —
not for prompt tricks. When you read them, they should look like the checklists a
staff engineer already carries in their head, written down so an assistant
carries them too.

## The two layers

The methodology splits into a part that is shared and a part that is yours.

- **Canon** — fixed, identical for every adopter. The simplicity ladder, the
  RFC/ADR/spec formats, the review tiers, the verification exit criterion, the
  anti-pattern list, session hygiene, model-tier delegation, git conventions.
  This is the reusable value of the kit, and it is what these documents describe.
- **Identity** — yours. Role, seniority framing, primary stack, package manager,
  repository layout, output language. The only `{{PLACEHOLDERS}}` in the
  templates. The persona generator asks about this and nothing else.

Keeping the two apart is what lets one person's stack differ from another's while
the engineering discipline stays common. See [`persona/README.md`](../../persona/README.md)
for the mechanics.

## The principles

| Document | What it covers |
| --- | --- |
| [Simplicity](./simplicity.md) | The laziest-solution ladder, what you never cut, marking deliberate tradeoffs, the anti-pattern list. |
| [Review discipline](./review-discipline.md) | Classifying feedback by cost, the anti-nitpick rule, the verification exit criterion, testing posture. |
| [Engineering documents](./documents.md) | When an RFC vs an ADR vs a spec, and the decision-making frame underneath all three. |
| [Working with agents](./working-with-agents.md) | Driving an assistant like a senior peer: delegation, model tiers, session hygiene, safe autonomy. |

## How to read these

They are not aspirational. Each principle is already enforced somewhere in the
kit — by a skill, a hook, or a line in the persona canon — and each document
points at where. If a principle here has no enforcement, treat that as a gap to
close, not a suggestion to admire.
