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
# Dependency-free on purpose, unlike the jq-based hooks: the payload is scanned
# as text rather than parsed. `agent(` and `model:` survive JSON string
# escaping unchanged, so counting them in the raw event covers an inline
# `script` as well as a `scriptPath` once the path is resolved.
#
# This is an `ask`, never a deny: the count is a heuristic, and a false
# positive should cost one keypress rather than deadlock a script against a
# regex it cannot satisfy.

set -u

payload=$(cat)
script=$payload
source_note='inline script'

# `scriptPath` takes precedence over `script`, and editing the persisted script
# is how a workflow is iterated, so a hook that reads only `script` is bypassed
# on every run after the first.
script_path=$(
  printf '%s' "$payload" |
    sed -n 's/.*"scriptPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    head -n 1
)
if [ -n "$script_path" ]; then
  # JSON escapes a Windows path's separators, so each one arrives doubled. The
  # separator is passed to tr as an octal escape because a literal backslash
  # argument warns as non-portable; repeated slashes then collapse back to one.
  script_path=$(printf '%s' "$script_path" | tr '\134' '/' | sed 's|//*|/|g')
  if [ -f "$script_path" ]; then
    script=$(cat "$script_path")
    source_note="scriptPath $script_path"
  else
    source_note="scriptPath $script_path (unreadable, scanned the raw event instead)"
  fi
fi

count_matches() {
  printf '%s' "$script" | grep -o "$1" | grep -c . || true
}

# `agent (` is valid JavaScript too, so whitespace before the parenthesis still
# counts as a call; otherwise ordinary formatting walks past the guard.
agent_calls=$(count_matches 'agent[[:space:]]*(')
model_fields=$(count_matches 'model[[:space:]]*:')

if [ "${agent_calls:-0}" -gt "${model_fields:-0}" ]; then
  missing=$((agent_calls - model_fields))
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s agent() call(s) of %s carry no model field (%s). Those take a default instead of naming a tier, which the persona Delegation rules forbid. Reject and label each call gather / proofread / decide, then set model from the label. If the count is a false positive from a nested call or a string literal, say so rather than editing the script to appease the check."}}\n' \
    "$missing" "$agent_calls" "$source_note"
fi

exit 0
