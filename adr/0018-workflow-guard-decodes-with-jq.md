# ADR-0018: The Workflow guard decodes its event with jq and asks when it cannot read the script

- **Status:** Accepted
- **Date:** 2026-10-31
- **Deciders:** Yuri Semenenko

## Context

[ADR-0016](./0016-subagent-default-tier-and-workflow-guard.md) made
`hooks/workflow-model-guard.sh` dependency-free: it scanned the raw `PreToolUse`
event as text, cut `scriptPath` out with `sed`, and turned every backslash into a
`/`. That is not JSON decoding, and it failed in ways that let the guard check a
script other than the one about to run:

- A `scriptPath` that arrives with `\uXXXX` escapes, which is valid JSON for any
  non-ASCII name, came out as a path to nothing. The guard then counted the raw
  event instead, which holds the inline `script`. When that inline text was stale
  and tiered, an untiered `agent()` call in the file passed without a prompt.
- Every other unreadable `scriptPath` fell back the same way: the message said so,
  but the count still came from text that was not going to run.
- An escaped quote cut the path short, and a literal backslash in a Linux path
  was rewritten.
- The path went into the reply through a `printf` template. The reply stayed valid
  JSON only because the steps above had already stripped quotes and backslashes.

Decoding JSON correctly in shell without a parser means writing one: string
boundaries, every escape, surrogate pairs. `jq` is already the parser every other
hook and the statusline use, the installers warn when it is missing, and the
prompt hook tells the session once that the guardrails are off without it.

## Decision

1. **The guard decodes `tool_input.scriptPath` and `tool_input.script` with
   `jq`.** `scriptPath` still takes precedence. Values reach `jq` on stdin, never
   as arguments, because Git for Windows rewrites a path-like argument before a
   native `jq.exe` sees it. The reply is built by `jq` too, so a path inside the
   reason is encoded rather than pasted.
2. **When the guard cannot see the script that will run, it asks and says why.**
   That covers `jq` missing or failing to run (fixed-text replies), an event it
   cannot parse, and a `scriptPath` that is not a readable regular file. It never
   checks the inline `script` in place of an unreadable `scriptPath`.
3. **The check stays a count and stays an `ask`.** Three narrow corrections: a
   name that only ends in `agent`, such as `subagent(`, is not a call; a call
   nested directly inside another counts twice; and a tier counts under a quoted
   key (`"model":`, `'model':`) as well as a bare one. Line breaks count as
   whitespace, so `agent` and its parenthesis on separate lines are still a
   call. The guard does not pair calls with fields, and its messages do not
   claim that it does.
4. **One fixture file, both platforms.** `scripts/test-workflow-model-guard.sh`
   runs the real hook in the Linux CI job, and the Windows suite runs the same
   file under Git for Windows' bash as a required check.

This supersedes the "dependency-free" clause of ADR-0016 decision 2. The rest of
ADR-0016 stands.

## Consequences

### Positive

- The guard counts the file that runs, whatever characters its path holds and
  however the event encodes them.
- When the guard is handed a script but cannot read it, or cannot run `jq` at
  all, the approval prompt says so instead of looking like a pass.
- The fixtures exercise the hook against native `jq.exe` and Windows paths, the
  combination that used to reach users untested.

### Negative

- The guard needs `jq`. Without it, every `Workflow` call prompts until `jq` is
  installed. A machine without `jq` already has every other guardrail off and
  gets the setup notice, so the prompt adds friction but no new failure.
- The count keeps its limits. A `model:` outside any call (prompt text, a schema
  property) or one whose value is not a tier (`model: undefined`) can cover for a
  call that has none; a call made through a reference (`items.map(agent)`, an
  alias) is not seen; a shorthand `{ model }` is not counted and reads as
  missing; a commented-out call counts as a call.
- A named workflow (`name` only) carries no script in the event and passes
  unchecked, as it did before.
- A relative `scriptPath` resolves against the hook's working directory, not the
  event's `cwd`. A missing file there asks; a different file with the same
  relative path there would be checked instead.

### Neutral

- `docs/hardening.md` now says the Workflow guard is the one hook that prompts
  instead of degrading to a no-op when `jq` is missing.

## Alternatives Considered

- **Keep scanning text and decode `\uXXXX` in `sed` or `awk`.** Rejected: that is
  a hand-written JSON parser, and the defect is text-matching JSON, not one escape.
- **A Node or Python parser, or a JavaScript AST to pair each call with its
  field.** Rejected: a new runtime for one hook, and no evidence yet that the
  count's false negatives cost more than a prompt.
- **Fall back to the text scan when `jq` is missing.** Rejected: that scan is the
  behaviour that produced the bypass, and a degraded check that looks like a check
  is worse than a prompt that says it did not run.
- **A silent no-op without `jq`, like the other hooks.** Rejected: it passes every
  script unchecked, which is the outcome ADR-0016 exists to prevent.
- **Deny when the script cannot be read.** Rejected for the reason ADR-0016 gives:
  the guard is a heuristic, and a false positive should cost one keypress.

## References

- [ADR-0016](./0016-subagent-default-tier-and-workflow-guard.md).
- `claude-code/.claude/hooks/workflow-model-guard.sh`;
  `scripts/test-workflow-model-guard.sh`; `scripts/test-windows.ps1` check
  `workflow-model-guard`; `.github/workflows/ci.yml`.
