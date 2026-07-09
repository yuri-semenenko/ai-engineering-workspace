# ADR-0004: Persona identity layer gains a workflow axis

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Yuri Semenenko

## Context

ADR-0003 added `discipline` and `seniority` to the persona identity layer while
keeping the methodology canon fixed. Two users at the same discipline and
seniority can still work in different modes: one is shipping features under
delivery pressure, another is doing design and architecture, another is mostly
reviewing, another is ramping up and optimizing for understanding. That mode
does not change their *methodology* (simplicity, verification, PR-review tiers
apply identically), but it does change which of the shipped skills they reach for
first and what user-facing guidance is most useful to surface.

## Decision

Add a third identity-layer axis, filled by `scripts/create-persona.{sh,ps1}`:

- **workflow** (`delivery-focused` | `architecture-focused` | `review-focused` |
  `learning-focused`).

Workflow influences **only the generated `persona/recommended-skills.md` view**
(gitignored, per-user): it appends an emphasis set to the recommended-skills
list, records the axis in the `Profile:` header, and adds one interaction-emphasis
line. It does **not** fill any persona template placeholder — deliberately, there
is no `{{WORKFLOW_MODEL}}`. The persona canon (`persona.template.md`,
`CLAUDE.template.md`) is untouched, so `persona.md`, `CLAUDE.md`, and the Codex
and Gemini mirrors are unchanged.

The default is `architecture-focused`, chosen so the emphasis set
(`rfc`, `adr`, `complexity-audit`) is a strict subset of what the previous
default profile (`staff` + `fullstack`) already recommended. As a result the
default run keeps `persona.md` and `CLAUDE.md` byte-identical, and even the
recommended-skills *list* is unchanged; only the `Profile:` header and the
emphasis line reflect the new axis.

Scope note: this axis foregrounds skills and gives user-facing interaction
guidance in a reference view. It does **not** inject new active behavior into the
assistant's live context, because `recommended-skills.md` is not loaded as a
persona/context file. The `recommended-skills.md` mapping is validated against the
actual Claude Code skill catalog across all
`discipline x seniority x workflow` = 32 combinations, in the wizard and by
`scripts/check-recommended-skills.sh`.

## Consequences

### Positive
- Same-role users in different modes get a relevant skills shortlist without any
  change to the shared methodology.
- The canon and its mirrors are untouched, so ADR-0001's single-file-mirror model
  and its drift guard are unaffected; no mirror regeneration is required.
- The default profile stays byte-identical on `persona.md` / `CLAUDE.md`.

### Negative
- One more wizard question.
- The workflow emphasis text and skill mapping live in both wizard scripts
  (`.sh` and `.ps1`), kept honest by parity rather than a generator — the same
  small duplication ADR-0003 already accepted.

### Neutral
- `recommended-skills.md`'s `Profile:` line now carries three axes and a
  workflow-emphasis line. It is a gitignored, per-user artifact, not a committed
  golden, so this is a content change to a generated view, not to the canon.

## Alternatives Considered

- **Add a `{{WORKFLOW_MODEL}}` / `{{WORKFLOW_MODEL_SHORT}}` placeholder** to the
  persona templates (parallel to `{{SENIORITY_MODEL}}`). Rejected for this scope:
  it would add a visible section to the canon for every user, force the default to
  render empty to preserve golden output, require regenerating the Codex and
  Gemini mirrors, and risk overlapping with the seniority interaction block. The
  recommended-skills view already delivers the three things the axis promises
  (skill foregrounding, interaction emphasis, user-facing guidance) at a far
  smaller surface.
- **Per-workflow profile files + a resolver.** Rejected for the same reasons as in
  ADR-0003: it contradicts the fixed-canon thesis and adds a toolchain to a
  shell-only repo. Over-engineered for a four-value axis.

### What would trigger reconsidering a profile resolver

Revisit the composed-canon / resolver decision only if several of these hold at
once: the identity layer grows past a handful of axes so the wizard `case`
branches become unmanageable; workflow (or a future axis) must alter the *active*
persona/context files rather than a reference view; the number of generated
outputs multiplies to the point where per-axis text can no longer be maintained
by parity across two scripts; or a genuine need appears to layer and deep-merge
methodology fragments per profile. Until then, the shell wizard plus the
32-combination guard remain the simplest thing that works.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- ADR-0003 — discipline and seniority axes with a fixed canon.
- [`persona/README.md`](../persona/README.md) — the two persona layers.
