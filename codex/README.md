# Codex package

A portable seed for OpenAI Codex: always-on guardrails, on-demand references, and curated user skills. Designed to be copied to a machine on its own and installed against the files already present.

## Layout

```
AGENTS.md              always-on guardrails (loaded every session)
references/
  persona.md           MIRROR of persona/persona.template.md (do not hand-edit)
  memory-seed.example/ MIRROR of the Claude memory-seed example
  checklists/          codex-owned: security.md, performance.md
  humanizer/           codex-owned: ai-writing-patterns.md
skills/                14 hand-authored skill ports + a start onboarding entrypoint, each with agents/openai.yaml
scripts/
  install.macos-linux.sh
  install.windows.ps1
PROMPT_FOR_CODEX.md    bootstrap prompt to paste into Codex
```

## Install

```bash
scripts/install.macos-linux.sh                 # into $CODEX_HOME (default ~/.codex)
scripts/install.macos-linux.sh /custom/codex   # explicit target
```

```powershell
powershell -NoProfile -File .\scripts\install.windows.ps1
```

The installer copies `references/`, `skills/`, and `AGENTS.md` into `$CODEX_HOME`. If you generated a filled persona (`scripts/create-persona.sh`), it installs that over the template mirror; otherwise it falls back to the committed mirror so a standalone `codex/` copy still works.

## What is a mirror and what is owned here

- `references/persona.md` and `references/memory-seed.example/` are **generated mirrors** of the Claude canon. Never hand-edit them — edit the canon and run `scripts/sync-codex-references.sh` from the repo root.
- `references/checklists/`, `references/humanizer/`, and `skills/` are **owned here**. Edit them directly. The sync script validates skill structure but does not regenerate their content.

See [`../docs/architecture.md`](../docs/architecture.md).

## Delegation in Codex

Codex can run subagents with model and sandbox overrides, but this package does
not pin concrete model slugs into committed agent configs. Model names churn more
quickly than the workflow policy; keep the repo stable by choosing by tier at
runtime:

| Work | Suggested tier | Boundary |
| --- | --- | --- |
| Broad search, repo orientation, evidence gathering | Routine tier, read-only when possible | Subagent returns compact evidence; parent interprets it. |
| Mechanical edits, fixtures, codemod-style work | Routine tier | Use only for well-scoped, disjoint write sets. |
| Implementation with product or architecture judgment | Default tier | Parent keeps scope and design decisions. |
| Independent review, security judgment, architecture trade-offs | Default or escalation tier | Parent owns the final verdict. |

Use these workflows:

- `gather -> judge` for debugging, reviews, migrations, security passes, and
  test strategy.
- `explore -> implement -> review` for meaningful implementation work.
- `explore -> architect -> decide -> implement -> review` when the work is
  ambiguous, cross-cutting, or architecture-sensitive. The `decide` step is the
  parent's, never a subagent's.

Do not delegate trivial work, do not spawn agents just because the mechanism
exists, and avoid multiple agents editing overlapping files. If no tier override
has a clear reason, let the subagent inherit the current model.

## Interaction modes

Trigger a narrower workflow explicitly:

- `$start` — generate your persona from the shared templates (onboarding)
- `$architect` — architecture decision, trade-off analysis, system design
- `$rfc` — RFC in the canonical 10-section format
- `$adr` — record an accepted decision
- `$debug` / `$failure-investigation` — systematic root-cause investigation
- `$pull-request-workflow` — review a PR or produce GitHub-ready feedback
- `$humanizer` — make text sound less AI-generated
- `$prompt-engineer` — design or harden an agent prompt
- `$project-onboarding` — create or update project-level agent instructions
- `$context-brief` — compact handoff before complex implementation or review
