# Engineering loops

Loops are declarative, repeatable engineering workflows. They coordinate existing
skills around one goal, durable project state, a stable report, verification, and
an explicit autonomy boundary. A loop is not a skill, an agent persona, a
scheduler, or a runtime.

This initial layer is canonical and tool-agnostic. It supplies two L1 report-only
reference loops:

- [PR Review](pr-review/LOOP.md)
- [Repository Health](repository-health/LOOP.md)

Read the shared [loop contract](contract.md) before adding a loop, then the
[autonomy levels](autonomy-levels.md). The validation guard checks the required
files, sections, supported autonomy, canonical skill references, and L1 write
prohibition.

## State belongs to the consuming project

The workspace ships only `state.example.md` files. A run's state belongs to one
consuming project, not to the methodology canon or a persona. The recommended
location is:

```text
.ai-workspace/
  loops/
    pr-review/
      state.md
    repository-health/
      state.md
```

Keep state compact and inspectable. Never put secrets, credentials, personal
profile data, or full chat transcripts in it. Prune resolved entries, preserve
human overrides, and gitignore generated state unless a team deliberately chooses
to version a shared state file.

## Adding a loop

Create one directory per stable identifier with `LOOP.md`, `output.md`, and
`state.example.md`. Use the contract headings, link the output and state schemas
from `LOOP.md`, and reference canonical Claude skills by their existing paths.
Only L0 and L1 are currently supported implementations.
