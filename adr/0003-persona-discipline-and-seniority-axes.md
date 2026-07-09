# ADR-0003: Persona identity layer gains discipline and seniority axes

- **Status:** Accepted
- **Date:** 2026-07-08
- **Deciders:** Yuri Semenenko

## Context

The kit shipped one persona parameterized only by an identity header (role,
stack, tooling, output language). Everything else — the methodology canon — was
fixed and identical for everyone (see ADR-0001 and `persona/README.md`). Two
things that vary between real users were not expressible: their **discipline**
(a pure frontend engineer versus a fullstack one) and their **seniority** (a
mid-level engineer and a principal want a different interaction altitude and a
different set of skills to reach for first). They do not, however, want a
different *methodology*: simplicity, verification, and the PR-review tiers apply
the same at every level.

## Decision

Add two axes to the identity layer, filled by `scripts/create-persona.{sh,ps1}`:

- **discipline** (`frontend` | `fullstack`) — sets the background framing default
  and the generated recommended-skills list.
- **seniority** (`mid` | `senior` | `staff` | `principal`) — fills a new
  `{{SENIORITY_MODEL}}` / `{{SENIORITY_MODEL_SHORT}}` placeholder that varies the
  "Seniority Model" section (how to treat the user).

The Copilot personal instructions (`copilot/home/.copilot/copilot-instructions.md`)
also become a template — a bespoke file, **not** a persona-canon mirror — that
reuses the same identity placeholders so Copilot personalizes by seniority and
stack like the other tools. The wizard renders it to
`persona/copilot-instructions.md`; the Copilot installer prefers that filled file
and falls back to the committed template when `copilot/` is copied standalone.

The **methodology canon does not vary** with either axis. Skill recommendation is
a generated *view* (`persona/recommended-skills.md`, gitignored), not a per-profile
installation: every skill still ships to everyone; the list only picks which to
foreground. Skill names in the mapping are validated against the actual Claude
Code skill catalog, in the wizard and by `scripts/check-recommended-skills.sh`.

## Consequences

### Positive
- The persona fits non-staff, non-fullstack users without forking the canon.
- ADR-0001 is untouched: only new placeholders were added, so the canon is still
  a single file mirrored byte-for-byte to Codex and Gemini.
- `staff` + `fullstack` are verbatim the previous defaults, so the default run
  regenerates byte-identical persona files — no change for existing users.

### Negative
- Two more wizard questions.
- The seniority text blocks live in both wizard scripts (`.sh` and `.ps1`), a
  small duplication kept honest by parity, not by a generator.

### Neutral
- `persona/recommended-skills.md` is a new gitignored, per-user artifact.
- Copilot is now a wizard-filled surface. A standalone `copilot/`-only copy that
  skips the wizard installs instructions that still contain `{{PLACEHOLDERS}}` —
  the same fallback tradeoff already accepted for the Codex and Gemini mirrors;
  the documented flow runs the wizard first.

## Alternatives Considered

- **Composed canon per profile** (layered profile files + a resolver that
  deep-merges them). Rejected: it contradicts the "methodology is fixed for
  everyone" thesis, complicates the ADR-0001 mirror (the canon would no longer be
  a single file to copy), and adds a Node toolchain plus a second persona
  generator to a deliberately shell-only repo. Over-engineered for a
  two-discipline, four-seniority scope.
- **One persona file per profession.** Rejected: combinatorial file explosion and
  guaranteed drift across near-identical files — the exact problem ADR-0001 exists
  to prevent.

## References

- ADR-0001 — one canon with generated, drift-guarded mirrors.
- [`persona/README.md`](../persona/README.md) — the two persona layers.
