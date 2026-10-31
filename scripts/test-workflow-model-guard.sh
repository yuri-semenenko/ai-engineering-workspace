#!/usr/bin/env bash
set -euo pipefail

# Regression cases for claude-code/.claude/hooks/workflow-model-guard.sh.
#
# Each case pipes a Workflow PreToolUse event into the real hook and checks the
# decision it prints. CI runs this file on Linux, and scripts/test-windows.ps1
# runs the same file under Git for Windows' bash against native jq.exe, so one
# set of fixtures covers both platforms.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../claude-code/.claude/hooks/workflow-model-guard.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "test-workflow-model-guard: jq is required; runtime test unavailable" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'chmod -R u+rwx "$work" 2>/dev/null; rm -rf "$work"' EXIT
failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'ok - %s\n' "$1"
}

# JSON-encodes a string. The value goes through stdin rather than --arg, so Git
# for Windows never rewrites a path-like value on its way to jq.exe; extra
# options (-a for \uXXXX escapes) pass through. Raw CR is dropped because
# native jq on Windows ends its output with CRLF, and an encoded string never
# contains one.
json_string() {
  local value="$1"
  shift
  printf '%s' "$value" | jq -Rs "$@" . | tr -d '\r'
}

inline_event() {
  printf '{"hook_event_name":"PreToolUse","tool_name":"Workflow","tool_input":{"script":%s}}' \
    "$(json_string "$1")"
}

# path_event PATH INLINE [json_string option...]
path_event() {
  local path="$1" inline="$2"
  shift 2
  printf '{"hook_event_name":"PreToolUse","tool_name":"Workflow","tool_input":{"scriptPath":%s,"script":%s}}' \
    "$(json_string "$path" "$@")" "$(json_string "$inline")"
}

run_hook() {
  printf '%s' "$1" | "$BASH" "$HOOK"
}

expect_silent() {
  local name="$1" event="$2" out
  if ! out="$(run_hook "$event")"; then
    fail "$name: the hook exited non-zero"
    return
  fi
  if [ -n "$out" ]; then
    fail "$name: expected no decision, got: $out"
    return
  fi
  pass "$name"
}

# expect_ask NAME EVENT EXPECTED [FORBIDDEN]: the output must be one valid ask
# decision whose reason contains EXPECTED and, if given, not FORBIDDEN.
expect_ask() {
  local name="$1" event="$2" expected="$3" forbidden="${4-}" out reason
  if ! out="$(run_hook "$event")"; then
    fail "$name: the hook exited non-zero"
    return
  fi
  if ! printf '%s' "$out" |
    jq -e '.hookSpecificOutput | .hookEventName == "PreToolUse" and .permissionDecision == "ask"' \
      >/dev/null 2>&1; then
    fail "$name: expected one valid ask decision, got: $out"
    return
  fi
  reason="$(printf '%s' "$out" | jq -j '.hookSpecificOutput.permissionDecisionReason')"
  case "$reason" in
    *"$expected"*) ;;
    *) fail "$name: the reason does not contain '$expected': $reason"; return ;;
  esac
  if [ -n "$forbidden" ]; then
    case "$reason" in
      *"$forbidden"*) fail "$name: the reason should not contain '$forbidden': $reason"; return ;;
    esac
  fi
  pass "$name"
}

# Fixture scripts. UNTIERED has one call of two without a model; TIERED has none
# missing. Both put a space before one parenthesis, which is still a call.
UNTIERED=$'agent("gather", {label: "scan"})\nagent ("judge", {model: "opus"})'
TIERED=$'agent("gather", {model: "sonnet"})\nagent ("judge", {model: "opus"})'

# --- inline script ------------------------------------------------------------

expect_ask 'inline: a call without a model' \
  "$(inline_event 'agent("a", {model: "sonnet"}); agent("b", {label: "x"})')" \
  '1 agent() call(s) of 2 carry no model field (inline script)'

expect_silent 'inline: every call names a model' \
  "$(inline_event 'agent("a", {model: "sonnet"}); agent("b", {model: "haiku"})')"

expect_ask 'inline: a space before the parenthesis is still a call' \
  "$(inline_event 'agent ("a", {model: "sonnet"}); agent ("b", {label: "x"})')" \
  '1 agent() call(s) of 2'

expect_ask 'inline: a line break before the parenthesis is still a call' \
  "$(inline_event $'agent\n("a", {label: "x"}); agent("b", {model: "sonnet"})')" \
  '1 agent() call(s) of 2'

expect_ask 'inline: a call nested directly inside another counts twice' \
  "$(inline_event 'agent(agent("a", {model: "opus"}), {label: "x"})')" \
  '1 agent() call(s) of 2'

expect_silent 'inline: quoted model keys count' \
  "$(inline_event $'agent("a", {"model": "sonnet"}); agent("b", {\'model\': "haiku"})')"

expect_silent 'inline: a longer name ending in agent is not a call' \
  "$(inline_event 'subagent("x"); agent("a", {model: "sonnet"})')"

expect_silent 'event: a named workflow carries no script to check' \
  '{"hook_event_name":"PreToolUse","tool_name":"Workflow","tool_input":{"name":"review-changes"}}'

expect_ask 'event: malformed JSON asks instead of passing' \
  '{"tool_input": {"script": "agent(1)"' \
  'could not parse this event'

# --- scriptPath ---------------------------------------------------------------

plain="$work/flow.js"
printf '%s\n' "$UNTIERED" > "$plain"
expect_ask 'scriptPath: the file is checked, not the stale inline script' \
  "$(path_event "$plain" "$TIERED")" \
  "1 agent() call(s) of 2 carry no model field (scriptPath $plain)"

tiered_file="$work/tiered.js"
printf '%s\n' "$TIERED" > "$tiered_file"
expect_silent 'scriptPath: an untiered inline script is ignored when the file is tiered' \
  "$(path_event "$tiered_file" 'agent("stale")')"

spaced="$work/dir with spaces/flow script.js"
mkdir -p "${spaced%/*}"
printf '%s\n' "$UNTIERED" > "$spaced"
expect_ask 'scriptPath: a path with spaces' \
  "$(path_event "$spaced" "$TIERED")" \
  "(scriptPath $spaced)"

unicode="$work/сценарий/поток.js"
mkdir -p "${unicode%/*}"
printf '%s\n' "$UNTIERED" > "$unicode"
expect_ask 'scriptPath: a Unicode path as raw UTF-8' \
  "$(path_event "$unicode" "$TIERED")" \
  "(scriptPath $unicode)"

# Guard the fixture itself: the path must arrive escaped, not as raw UTF-8.
escaped_event="$(path_event "$unicode" "$TIERED" -a)"
if [[ $escaped_event != *u0441* || $escaped_event == *сценарий* ]]; then
  fail "fixture: the path is not \\u-escaped in the event: $escaped_event"
fi
expect_ask 'scriptPath: a Unicode path as \uXXXX escapes' \
  "$escaped_event" \
  "(scriptPath $unicode)"

# Claude Code on Windows sends a native path. Git for Windows' bash reads it as
# is, so only the platform that has one runs this case.
if command -v cygpath >/dev/null 2>&1; then
  native="$(cygpath -w "$unicode")"
  expect_ask 'scriptPath in Windows form' \
    "$(path_event "$native" "$TIERED" -a)" \
    "(scriptPath $native)"
fi

# A missing file asks, names the path exactly as sent, and never falls back to
# counting the inline script. The quote and backslash also prove the reason is
# JSON-encoded rather than pasted into the output.
missing="$work/missing \"quoted\" back\\slash.js"
expect_ask 'scriptPath: a missing file asks without scanning the inline script' \
  "$(path_event "$missing" 'agent("stale")')" \
  "cannot read scriptPath $missing" \
  'carry no model field'

expect_ask 'scriptPath: a directory asks' \
  "$(path_event "$work" "$TIERED")" \
  "cannot read scriptPath $work"

locked="$work/locked.js"
printf '%s\n' "$TIERED" > "$locked"
chmod 000 "$locked"
if [ -r "$locked" ]; then
  # Root, and Windows ACLs, read through mode 000, so the case cannot fail here.
  printf 'skip - scriptPath: an unreadable file (mode 000 does not revoke read here)\n'
else
  expect_ask 'scriptPath: an unreadable file asks' \
    "$(path_event "$locked" "$TIERED")" \
    "cannot read scriptPath $locked"
fi

# --- no jq --------------------------------------------------------------------

# The hook's own PATH holds only cat, so jq is absent whatever the host has.
stub="$work/no-jq-bin"
mkdir -p "$stub"
printf '#!%s\nexec %q "$@"\n' "$BASH" "$(command -v cat)" > "$stub/cat"
chmod +x "$stub/cat"
out="$(inline_event 'agent("a")' | PATH="$stub" "$BASH" "$HOOK")" || true
if printf '%s' "$out" |
  jq -e '.hookSpecificOutput.permissionDecision == "ask" and (.hookSpecificOutput.permissionDecisionReason | contains("jq is not on PATH"))' \
    >/dev/null 2>&1; then
  pass 'no jq: the guard asks and names the missing dependency'
else
  fail "no jq: expected an ask naming jq, got: $out"
fi

# A jq that is found but fails to run must still produce a prompt rather than
# an empty reply, which Claude Code reads as allow.
broken="$work/broken-jq-bin"
mkdir -p "$broken"
printf '#!%s\nexit 127\n' "$BASH" > "$broken/jq"
chmod +x "$broken/jq"
out="$(inline_event 'agent("a")' | PATH="$broken:$PATH" "$BASH" "$HOOK" 2>/dev/null)" || true
if printf '%s' "$out" |
  jq -e '.hookSpecificOutput.permissionDecision == "ask" and (.hookSpecificOutput.permissionDecisionReason | contains("failed to run"))' \
    >/dev/null 2>&1; then
  pass 'broken jq: the guard still asks'
else
  fail "broken jq: expected an ask, got: $out"
fi

if [ "$failures" -ne 0 ]; then
  printf '%s workflow-model-guard case(s) failed.\n' "$failures" >&2
  exit 1
fi
echo "workflow-model-guard regression cases pass."
