# Adding a tool

This kit is tool-agnostic on purpose: the canon is the product, an assistant is a
replaceable consumer of it. This guide is the proof and the procedure. It walks
through how Gemini CLI was added as the fourth tool, so you can add the fifth
without reverse-engineering the pattern.

The honest headline: **adding a tool is a mapping exercise, not a rewrite.** The
canon (`persona/`, `claude-code/`) does not change. You map four layers onto the
new tool's configuration surface, decide which parts are generated mirrors and
which are hand-authored ports, and wire the result into the drift guard and CI.

## The four layers to map

Every supported tool is the same four things pointed at a different config surface:

| Layer | What it is | Generated or owned? |
| --- | --- | --- |
| **Persona** | The methodology canon the assistant reads every session | **Generated mirror** of the canon |
| **Skills / commands** | The process workflows (RFC, ADR, review, …) | **Hand-authored port** (no canon to generate from) |
| **Permissions** | What the assistant may do unattended | Hand-authored, translated from the Claude model |
| **Hooks / guardrails** | Write- and command-time safety | Hand-authored, translated |

The persona is a *mirror* because there is one canonical wording to copy. The
other three are *ports* because each tool expresses them differently enough that
a byte-copy is impossible — the same split the Codex package already uses.

## Procedure

### 1. Recon the tool's config surface (do not assume)

Before writing anything, verify against the tool's current docs — not your memory
of them — the answers to five questions:

1. **Persistent context.** What file does it read every session, and where? Is it
   always-on or loaded on demand? (Gemini: `~/.gemini/GEMINI.md`, hierarchical,
   re-sent every prompt.)
2. **Reusable commands.** How are custom commands/prompts defined? (Gemini: TOML
   in `~/.gemini/commands/`, a `prompt` + `description` field, subdirs namespace.)
3. **Permissions.** Allowlist, denylist, approval modes? How granular? (Gemini:
   `settings.json` `tools.allowed` by command *prefix*, plus `tools.exclude`.)
4. **Hooks.** Is there a lifecycle-events mechanism, and can a pre-tool hook
   block or ask? (Gemini: yes — `BeforeTool`/`AfterTool`, shell + JSON stdin,
   `decision:"deny"` only, no interactive "ask".)
5. **Sandbox / isolation.** Any bonus safety layer to lean on? (Gemini: Docker /
   Podman / Seatbelt sandbox.)

Write the findings down. They decide the whole mapping, and the gaps you find are
the honest limits of the port.

### 2. Map each layer, and record where it strains

Map the four layers onto the recon. Expect friction — record it rather than
paper over it. From the Gemini port:

- **Persona → context file.** If the context is always-on (re-sent every prompt),
  mirror the *condensed* canon (`persona/CLAUDE.template.md`), not the full one.
  If it is on-demand (like Codex references), mirror the full persona.
- **Skills → commands.** Inline the skill body into the command's prompt so the
  tool folder stays standalone-portable. Keep the methodology verbatim; adapt
  only tool-specific references.
- **Permissions.** Translate the allow/deny lists. Gemini's allowlist is
  prefix-based (`run_shell_command(git)`), coarser than Claude's per-pattern
  model, and has no declarative denylist — so the Claude denylist had to move
  into a hook (below). That is a real limit of the tool, not a flaw in the port.
- **Hooks.** Translate the six guardrail hooks. Two things shifted for Gemini:
  its pre-tool hook can only `deny` (no "ask"), so three confirm-guards hardened
  to outright deny; and its always-on context made the post-compaction re-assert
  hook unnecessary — the persona is never summarized away. One tool's limitation
  can be another tool's non-problem.

### 3. Create the tool package

Mirror the existing packages:

```
<tool>/
  references/<context-file>   # generated mirror of the canon
  commands/ (or skills/)      # hand-authored ports
  settings.example.json       # permissions + hooks + sandbox
  scripts/install.macos-linux.sh   # + install.windows.ps1 for parity
```

The installer copies the mirror and ports into the tool's home, seeds settings
only on first run (never clobber a user's config), and prefers the user's filled
persona (`persona/CLAUDE.md` or `persona/persona.md`) over the committed template.

Whether that copy backs up what it replaces follows the tool's ownership model
rather than one blanket rule. `$CODEX_HOME` and `~/.gemini` are documented as
belonging to the tool's configuration payload, so the Codex and Gemini installers
overwrite the mirror and the ports in place: there is no user-authored content
there to lose. `~/.claude` and `~/.copilot` also hold files the user wrote, so
those installers move an existing file aside to a timestamped `.pre-*-config.*`
name before writing. Settings are the exception everywhere, seeded only when
absent.

### 4. Wire the mirror into the drift guard

A committed mirror that isn't drift-guarded silently rots — see
[ADR-0001](../../adr/0001-single-canon-with-generated-mirrors.md). Add the new
canon→mirror pair and a structure validator for the ports to
`scripts/sync-codex-references.{sh,ps1}` (both, for Windows parity). The
`--check` mode then fails CI and the pre-commit hook when the mirror drifts.

> The sync script is still named `sync-codex-references` from when Codex was the
> only consumer. Adding Gemini made that name a mild misnomer; it carries a
> `TRADEOFF` annotation to rename it to `sync-references` when a fourth consumer
> lands. Adding a *fifth* tool is a good moment to do that rename.

### 5. Add a CI smoke test

Copy the pattern of the existing installer smoke tests in
`.github/workflows/ci.yml`: install into a scratch home, assert the expected
files landed, and grep the installed persona for leftover `{{placeholders}}`.

### 6. Update the docs

The tool matrix in the README, and this guide's case-study notes if the new tool
surfaced a mapping you had not seen before.

## What the Gemini port proved

The abstraction held. The canon did not change; no other tool's package changed.
The only shared-infrastructure edit was generalizing the sync script to a third
target, which was mechanical. The genuine limits were all in *Gemini's* surface
(coarse permissions, deny-only hooks), not in the kit's design — which is exactly
what a tool-agnostic architecture should look like when you stress it: the tool
bends, the methodology doesn't.

## Checklist

- [ ] Recon: five questions answered against current docs
- [ ] Persona mirrored (condensed vs full chosen by always-on vs on-demand)
- [ ] Skills ported, methodology preserved verbatim
- [ ] Permissions translated; denylist gaps handled (hook if needed)
- [ ] Hooks translated; timing/semantic gaps recorded
- [ ] Installer (macOS/Linux + Windows) seeds without clobbering; backup behavior matches the tool's ownership model
- [ ] Mirror wired into the drift guard (`.sh` + `.ps1`)
- [ ] CI smoke test added
- [ ] README tool matrix updated
