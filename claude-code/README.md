# Claude Code package

The canon of the kit. Skills, agents, hooks, and the persona all originate here; the Codex mirror is generated from it.

## Layout

```
.claude/
  skills/               20 process skills + a /start onboarding entrypoint (see the root README catalog)
  agents/
    independent-review.md       shipped agent: independent second read, no write tools
    project-agent.template.md   how-to template for a project-specific agent
  hooks/
    model-reminder.sh    UserPromptSubmit hook
  memory-seed.example/   fictional example memories (format demo; also the sync canon)
  settings.example.json  permissions + 6 guardrail hooks + a notifier (no model pin / theme / plugins)
  statusline.sh          model · branch · dir status line
scripts/
  install.macos-linux.sh
  install.windows.ps1
```

## Install

```bash
scripts/install.macos-linux.sh
```

```powershell
powershell -NoProfile -File .\scripts\install.windows.ps1            # Copy mode (default)
powershell -NoProfile -File .\scripts\install.windows.ps1 -Mode Symlink
```

The installer:

1. Runs `scripts/create-persona.sh` if you have no persona yet (prompts, or defaults when non-interactive).
2. Symlinks `.claude` to `~/.claude` (Copy mode on Windows when symlinks are not permitted), backing up any existing config.
3. Provisions `~/.claude/CLAUDE.md`, `~/persona.md`, and `~/.claude/settings.json` (seeded from the example on first run).

`CLAUDE.md`, `persona.md`, and `settings.json` are gitignored — they are yours, not the repo's.

## Delegation

The canon states the policy in tiers and workflows
([`../docs/principles/working-with-agents.md`](../docs/principles/working-with-agents.md)).
This is how it maps onto the mechanisms Claude Code actually has.

Claude Code is the one supported tool whose config names a **tier** rather than a
version: `model: sonnet` in an agent file, and the model argument on a delegation
call, take the same vocabulary the canon uses. So for the agents this kit ships a
file for, the policy is written into config rather than only described. See
[`../adr/0012-tier-labels-over-pinned-model-slugs.md`](../adr/0012-tier-labels-over-pinned-model-slugs.md)
and [`../adr/0013-claude-review-agent.md`](../adr/0013-claude-review-agent.md).

The aliases map onto the canon's tiers like this: `haiku` and `sonnet` are the
routine tier, `opus` is the default tier. Nothing ships on the escalation tier,
because the canon treats escalation as a manual session-level switch and burst
capacity rather than something to bake into an agent file.

| Work | Mechanism | Tier | Where the tier comes from |
| --- | --- | --- | --- |
| Broad search, orientation, evidence gathering | built-in `Explore`, read-only | routine | the dispatch |
| Planning a multi-step change | built-in `Plan` | routine | the dispatch |
| Mechanical edits, fixtures, codemods | `general-purpose` | routine | the dispatch |
| Implementation inside a project's known conventions | project agent from the template, which ships `sonnet` | routine | its agent file |
| Independent read of a finished change | shipped `independent-review`, which ships `opus` | default | its agent file |
| Architecture, the verdict, the decision, hard debugging | main loop, no subagent | whatever the session is on | — |

The last column is the part that bites. The three built-ins have no agent file to
carry a `model:`, so their tier is whatever the dispatch asks for — and a
dispatch that asks for nothing inherits the session's model. Sending broad search
to `Explore` without naming a tier does not save anything; it runs your current
model with a narrower toolset. The two agents this kit ships a file for are the
ones whose tier holds on its own.

Raise a project agent's alias when that project's work carries more judgment than
its conventions cover. The shipped reviewer sits a tier above the project agent
on purpose: catching a defect is worth more than producing one cheaply.

The reviewer has no Edit or Write tool, but it does have Bash, and the allowlist
in `settings.example.json` passes a few state-changing commands through
(`git add`, `git commit -m`, `git switch`, `npm install`). Its read-only posture
is a contract in its prompt plus the denylist, not a capability boundary. If you
want it capability-enforced, drop `Bash` from its `tools` and hand it the diff in
the dispatch instead.

The canon's workflow steps are roles. They land here as:

| Role | Claude Code |
| --- | --- |
| `explore` | `Explore`, or `/codebase-map` when you want the map written down |
| `architect` | `/rfc` while options are open, `/module-design` for one interface |
| `decide` | the main loop; `/adr` records what it settles |
| `implement` | project agent |
| `review` | `independent-review`, then `/pr-classify` for the classification |
| `judge` | always the main loop |

Two mechanisms the other tools do not have:

- **Fan out in one message.** Subagents dispatched together run concurrently, so
  a four-angle gather costs one round trip rather than four.
- **Worktree isolation.** The canon forbids parallel agents over overlapping
  write sets. A worktree per agent is how you lift that limit instead of obeying
  it: separate checkouts, no shared index.

What never leaves the main loop: architecture, the review verdict, security
judgment, RFC and ADR authoring, hard debugging. A subagent finding is evidence,
not a ruling.

## Customizing

- **Agents:** copy `agents/project-agent.template.md`, rename it, fill the placeholders. One agent per project encodes that project's stack, conventions, and quality gate. `agents/independent-review.md` ships ready to use and needs no per-project values; delete it if you do not want the review step delegated.
- **Memory:** replace `memory-seed.example/` with your own memories or delete it. Note it is also the sync canon for the Codex mirror — run `scripts/sync-codex-references.sh` after editing.
- **Permissions/hooks:** edit `settings.example.json` for the shipped defaults, or your local `settings.json` for machine-specific tweaks. See [`../docs/hardening.md`](../docs/hardening.md).
