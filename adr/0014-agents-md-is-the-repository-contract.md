# ADR-0014: `AGENTS.md` is the repository contract, and Claude Code reaches it through `CLAUDE.md`

- **Status:** Accepted
- **Date:** 2026-08-31
- **Deciders:** Yuri Semenenko

## Context

Five layers of instruction already had a home in this kit. Persona lives in
`persona/*.template.md` and is mirrored to Codex and Gemini. Methodology is
written out as prose in `docs/principles/` and encoded into the persona canon.
Skills are the per-tool ports. Adapters are the four tool folders. Guardrails are
`settings.example.json`, the sync scripts, the pre-commit hook, and CI.

The sixth layer — how an agent works in one specific repository — was already
being assumed without ever being named. `codex/skills/project-onboarding/`
authors a project-level `AGENTS.md`, and
[ADR-0007](./0007-codebase-map-skill.md) describes that skill as "scoped to
authoring a durable `AGENTS.md`". `gemini/settings.example.json` already sets
`"context": {"fileName": ["GEMINI.md", "AGENTS.md"]}`, so Gemini reads a
repository `AGENTS.md` today. Nothing said what belongs in such a file, and this
repository had no contract of its own.

Three concrete defects followed.

First, `copilot/workspace-template/AGENTS.md` shipped persona content — "treat
the user as a senior technical peer", a default stack, the Critical / Important /
Optional review tiers — into every target repository. That is the personal layer
duplicated per project, it speaks for one individual rather than a team, and it
forks the moment the canon changes. The stack defaults were the clearest case: a
hardcoded, un-personalized copy of the `## Technical Defaults` section that
`copilot/home/.copilot/copilot-instructions.md` already renders from the persona
axes into each user's own `~/.copilot/copilot-instructions.md`.

Second, this repository shipped no contract at all. An agent working on the kit
had to rediscover the canon/mirror split, the LF/CRLF pin, the ADR append-only
rule, and which script silently overwrites the developer's own gitignored
persona.

Third, three unrelated files are named `AGENTS.md` once the root file exists, and
`CLAUDE.md` already meant two different things in this tree
(`persona/CLAUDE.template.md`, `persona/CLAUDE.md`). Without a stated audience
per file, a rule lands in the file whose *name* matched rather than the file
whose *scope* matched.

Tool behaviour was verified against primary documentation rather than memory:

- Claude Code reads `CLAUDE.md`, not `AGENTS.md`; the documented bridge is an
  `@AGENTS.md` import, and import parsing skips code spans and fenced blocks.
- Codex reads `$CODEX_HOME/AGENTS.md` first, then repository files from the root
  down, concatenated, so the closer file overrides the more global one.
- Copilot reads `AGENTS.md` as "agent instructions". This kit targets Copilot CLI
  and VS Code Copilot Chat (`copilot/PROMPT_FOR_COPILOT.md`), and both read it.
  Copilot CLI "combines their instructions" and "does not define a general
  precedence order between these files"; GitHub's cross-surface precedence list
  ranks repository-wide instructions above agent instructions but states that
  "all sets of relevant instructions are provided to Copilot", so precedence
  resolves conflicts rather than suppressing a file. Per-surface support does
  vary: GitHub.com Copilot Chat reads repository-wide instructions but not
  `AGENTS.md`.
- Gemini CLI defaults to `GEMINI.md` and takes an array at `context.fileName`.

The convention is genuinely shared. The discovery mechanism is not.

## Decision

A repository's root `AGENTS.md` is the tool-agnostic repository contract. It is
the only editable source for repository-specific agent instructions, and it is a
**router**: purpose, instruction layers, authoritative sources, verified
commands, architecture invariants, change policy, definition of done, safety
boundaries, and links onward. It links to the deeper document instead of
restating it, and it never carries persona, general methodology, or a whole
skill. Those are global and shared; copying them into a project forks them per
project.

Root `CLAUDE.md` is a pointer, not a second contract: a bare `@AGENTS.md` import
plus anything genuinely Claude-only. This repository gets one, and so does the
Copilot workspace template, which now ships `AGENTS.md` and `CLAUDE.md` as a pair
through both installers.

The template's `.github/copilot-instructions.md` becomes the Copilot delta and
nothing more: a pointer to the contract, a note on the Copilot-only `applyTo`
mechanism, and what to do on the surfaces that read it but not `AGENTS.md`.
Ownership here is decided by meaning, not by precedence. Repository facts go in
`AGENTS.md`. The stack preference goes in neither file: it is a personal default
for when a repository is silent, its owner is the persona layer, and the wizard
already renders it per-user. A hardcoded copy in a target repository is one
person's preference committed into a team's tree.

The global layer stays separate. `codex/AGENTS.md` keeps its filename because
Codex discovers `$CODEX_HOME/AGENTS.md` by that exact name. It now says that it
is the global layer, names the precedence that makes the split work, and points
at `$project-onboarding` for the repository half. The three `AGENTS.md` files are
not mirrored and no sync runs between them: only `persona.md`, the memory-seed
example, and `GEMINI.md` are canon-and-mirror pairs
([ADR-0001](./0001-single-canon-with-generated-mirrors.md)).

`project-onboarding` is the workflow that produces a contract. It stays
Codex-owned and single-sourced — no Claude, Copilot, or Gemini port — and it now
inspects read-only, separates verified commands from inferences, patches an
existing file instead of overwriting it, gets approval before writing, validates
every referenced path, and adds the `CLAUDE.md` pointer where Claude Code is in
use.

`claude-code/.claude/agents/project-agent.template.md` keeps its job and loses
the overlap. It is a Claude Code subagent definition — a dispatchable role with a
tier alias and its own agent memory — and that half has no equivalent anywhere
else in the kit. Its project-knowledge half (stack, structure, code-style rules,
quality-gate commands) is exactly what `AGENTS.md` now owns, so the template
defers there instead of asking to be filled with the same facts a second time.
It is not deprecated and not deleted: the two files answer different questions,
and [ADR-0012](./0012-tier-labels-over-pinned-model-slugs.md) cites this file as
the committed tier-alias example.

`scripts/check-repository-contract.sh` enforces the structure only: each contract
has its pointer, each pointer carries a real import line outside code spans, and
relative links across the contract surface and the ADR index resolve.

## Consequences

### Positive

- Root `AGENTS.md` loads in a Codex, Copilot, and Gemini session directly, and in
  Claude Code through the import — none of which happened before.
- The three `AGENTS.md` files have stated audiences, so a rule lands in the file
  whose scope it matches.
- A repository seeded from the Copilot template gets a team-facing contract with
  no personal collaboration style committed into it.
- The hazard that `create-persona.sh` and `check-recommended-skills.sh` overwrite
  the developer's own gitignored persona is now written down where an agent reads
  it before running either.
- The contract guard fails if a pairing or a referenced path breaks, so the
  bridge cannot rot silently.

### Negative

- Two files at every repository root, and the pointer is pure overhead for anyone
  not using Claude Code.
- A third meaning for the name `CLAUDE.md` in this tree, alongside the persona
  template and the generated persona. Root `CLAUDE.md` says so in its own body,
  but the collision is real.
- The template `AGENTS.md` is now placeholder-heavy. Copied without being filled
  in, it is worse than the generic prose it replaced, which at least read as
  finished. `project-onboarding` is the mitigation, and it is a convention rather
  than a gate.
- Nothing enforces that a target repository resolves those placeholders; that
  repository is outside this one's reach.
- Both Copilot installers name each root-level template file explicitly, so the
  new `CLAUDE.md` needed an edit in each. The `.github/` subdirectories are
  globbed and need no installer change.

### Neutral

- The contract template still lives under the Copilot adapter even though the
  contract is tool-agnostic. Copilot is the only package that ships a workspace
  payload — verified: nothing else reads or copies
  `copilot/workspace-template/AGENTS.md`, and `project-onboarding` produces a
  contract from repository evidence rather than from that file. Promoting the
  template would add a template hierarchy, a mirror pair, and a second drift
  guard to serve one consumer.
- Root `AGENTS.md` runs longer than the 80-150 lines the template and
  `project-onboarding` target. That range is for a product repository. This one's
  subject *is* agent configuration, so the layer model and the two
  filename-disambiguation lists are its highest-value routing content rather than
  padding. Trim it for duplication, not for length.
- `project-onboarding` remains Codex-only, so Claude, Copilot, and Gemini users
  author a contract by hand or with `/init`. That asymmetry is deliberate.
- The guard is bash-only and has no PowerShell port, matching
  `check-model-tiers.sh`. `scripts/test-windows.ps1` shells out to it.
- A Claude Code subagent is documented to receive "every level of the `CLAUDE.md`
  hierarchy the main conversation loads" (only the built-in `Explore` and `Plan`
  agents skip it), so `project-agent.template.md` can rely on the contract being
  present. Whether the `@AGENTS.md` **import** is re-expanded for a subagent is
  not documented either way, so the template keeps one explicit "read the root
  `AGENTS.md` first" line rather than depending on the undocumented case. That
  line is the whole mitigation; the old persona-heavy project context does not
  come back.
- Copilot ownership is decided by meaning, not precedence, because precedence
  turned out not to be an override: for both surfaces this kit targets, the
  contract and the Copilot delta are combined rather than one suppressing the
  other. The earlier draft of this record justified the split by precedence and
  was wrong.

## Alternatives Considered

- **Make `AGENTS.md` the canon and generate `CLAUDE.md` from it.** Rejected: a
  generated copy needs a mirror pair and a drift guard, and the platform already
  provides an import that is one line and cannot drift.
- **Symlink `CLAUDE.md` to `AGENTS.md`.** Rejected: on Windows a symlink needs
  Administrator or Developer Mode, and this kit is developed on Windows —
  [ADR-0002](./0002-commit-mirrors-instead-of-generating-at-install.md) and the
  Claude installer's Copy mode already exist for that reason.
- **Put the contract only in `CLAUDE.md` and drop `AGENTS.md`.** Rejected: Codex,
  Copilot, and Gemini read `AGENTS.md`, and being tool-agnostic is the point.
- **Rename `codex/AGENTS.md` to mark it global.** Rejected: Codex discovers
  `$CODEX_HOME/AGENTS.md` by that exact name. Documentation carries the
  distinction instead.
- **Promote the contract template to a new top-level `templates/` directory.**
  Rejected: a hierarchy, a mirror, and a drift check for one consumer, against
  the standing preference for the smallest structure that works.
- **Port `project-onboarding` to all four tools, matching the skill catalog's
  parity.** Rejected: forced adapter parity. One canonical workflow beats four
  that drift, and Claude Code ships `/init` for the same job.
- **Delete `project-agent.template.md` and fold it into `AGENTS.md`.** Rejected:
  it also defines a dispatchable Claude subagent, which no `AGENTS.md` can be.
  Narrowing it to the role and deferring the repository facts removes the
  duplication without losing the capability.
- **Validate every markdown link in the repository.** Rejected as brittle. The
  guard covers the contract surface and the ADR index only.

## References

- [ADR-0001](./0001-single-canon-with-generated-mirrors.md) — why only the
  persona and memory-seed pairs are mirrored.
- [ADR-0007](./0007-codebase-map-skill.md) — `codebase-map` orients a reader and
  can feed `project-onboarding`; it does not replace it.
- [ADR-0012](./0012-tier-labels-over-pinned-model-slugs.md) — why
  `project-agent.template.md` keeps a committed `model:` field.
- `AGENTS.md` § Instruction layers; root `CLAUDE.md`;
  `copilot/workspace-template/AGENTS.md`;
  `codex/skills/project-onboarding/SKILL.md`.
- <https://agents.md/> — the convention and its nearest-file precedence.
- <https://learn.chatgpt.com/docs/agent-configuration/agents-md> — Codex
  discovery: Codex home first, then project root down, concatenated.
- <https://code.claude.com/docs/en/memory> — "Claude Code reads `CLAUDE.md`, not
  `AGENTS.md`", the `@path` import, and code-span exclusion.
- <https://docs.github.com/en/copilot/concepts/prompting/response-customization>
  — the precedence list, and "all sets of relevant instructions are provided to
  Copilot".
- <https://docs.github.com/en/copilot/reference/custom-instructions-support> —
  per-surface support: `AGENTS.md` is read by Copilot CLI and VS Code Chat, and
  not by GitHub.com Chat.
- <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions>
  — Copilot CLI combines instruction files and defines no precedence between them.
- <https://geminicli.com/docs/cli/gemini-md/> — `context.fileName` accepts a list
  of context filenames.
