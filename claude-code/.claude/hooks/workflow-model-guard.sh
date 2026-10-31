#!/usr/bin/env bash
# PreToolUse hook for Workflow.
#
# A Workflow script's agent() calls resolve their model in the order
# per-call > agent frontmatter > CLAUDE_CODE_SUBAGENT_MODEL > the session's
# model, so a call that omits `model` silently takes a default instead of
# naming a tier. The persona's Delegation rules require the tier per call, and
# the omission is invisible in the permission dialog, which shows only
# meta.description. Permission rules cannot see inside the script argument, so
# this has to be a hook (ADR-0016).
#
# The event is JSON and is decoded with jq, like the kit's other hooks
# (ADR-0018). Matching the raw event as text misread a scriptPath that arrived
# with \uXXXX escapes and then checked a script that was not going to run. When
# the guard cannot see the script that will run (no jq, an event it cannot
# parse, a scriptPath it cannot read) it asks and says why instead of passing.
#
# This is an `ask`, never a deny: the count is a heuristic, and a false
# positive should cost one keypress rather than deadlock a script against a
# regex it cannot satisfy.

set -u

payload=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  # Fixed text, because nothing here can encode a dynamic string without jq.
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"The Workflow tier guard did not check this script: jq is not on PATH, so it cannot read the event. Install jq (winget install jqlang.jq on Windows, brew install jq on macOS, the distro package on Linux) and restart the session. Until then, confirm that every agent() call names a model before approving."}}'
  exit 0
fi

# Values reach jq on stdin, never as arguments: Git for Windows rewrites a
# path-like argument before a native jq.exe sees it. `-j` prints a field without
# a trailing newline, which native jq on Windows would otherwise end with CR.
# A jq that is on PATH but fails to run (blocked, a broken shim) must still
# produce a prompt, so its failure falls back to fixed text.
ask() {
  printf '%s' "$1" |
    jq -Rsc '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: .}}' 2>/dev/null ||
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"The Workflow tier guard did not check this script: jq is on PATH but failed to run. Confirm that every agent() call names a model before approving."}}'
  exit 0
}

if ! printf '%s' "$payload" | jq -e '.tool_input | type == "object"' >/dev/null 2>&1; then
  ask "The Workflow tier guard could not parse this event, so it did not check the script. Confirm that every agent() call names a model before approving."
fi

script_path=$(printf '%s' "$payload" | jq -j '.tool_input.scriptPath // empty | strings')

# `scriptPath` takes precedence over `script`, and editing the persisted script
# is how a workflow is iterated, so the file is what runs. A path the guard
# cannot read is reported rather than swapped for the inline text, which is
# stale whenever the file was edited after the first run.
if [ -n "$script_path" ]; then
  if [ ! -f "$script_path" ] || ! script=$(cat -- "$script_path" 2>/dev/null); then
    ask "The Workflow tier guard cannot read scriptPath $script_path, so it did not check the script that will run. The inline script was not checked in its place: scriptPath takes precedence, and the inline text may be stale. Fix the path, or confirm that every agent() call in the file names a model before approving."
  fi
  source_note="scriptPath $script_path"
else
  # A named workflow carries no script in the event, so there is nothing to
  # count and it passes unchecked.
  script=$(printf '%s' "$payload" | jq -j '.tool_input.script // empty | strings')
  source_note='inline script'
fi

# The script is matched as one line, so a line break between `agent` and its
# parenthesis, or between `model` and its colon, is whitespace like any other.
count_matches() {
  printf '%s' "$script" | tr '\r\n' '  ' | grep -Eo "$1" | grep -c . || true
}

# The two sides are counted, not paired call by call. A `model:` outside any
# call (prompt text, a schema property, a value that is not a tier) can cover
# for a call that has none, a call made through a reference (`map(agent)`, an
# alias) is not seen, and a commented-out call still counts. The guard catches
# the common omission; it does not prove that every call names a tier.
#
# `agent (` is valid JavaScript too, so whitespace before the parenthesis still
# counts as a call. A longer name such as `subagent(` is subtracted rather than
# excluded by matching the character before `agent`: that character would be
# consumed, and a call nested directly inside another (`agent(agent(`) would
# lose its count. A tier counts under a bare or a quoted key: model:, "model":,
# 'model':.
word='[[:alnum:]_$]'
key_quote="[\"']"
call='agent[[:space:]]*\('
field="${key_quote}?model${key_quote}?[[:space:]]*:"
agent_calls=$(( $(count_matches "$call") - $(count_matches "$word$call") ))
model_fields=$(( $(count_matches "$field") - $(count_matches "$word$field") ))

if [ "${agent_calls:-0}" -gt "${model_fields:-0}" ]; then
  missing=$((agent_calls - model_fields))
  ask "$missing agent() call(s) of $agent_calls carry no model field ($source_note). Those take a default instead of naming a tier, which the persona Delegation rules forbid. Reject and label each call gather / proofread / decide, then set model from the label. If the count is a false positive from a nested call or a string literal, say so rather than editing the script to appease the check."
fi

exit 0
