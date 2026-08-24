#!/usr/bin/env bash
# UserPromptSubmit hook.
# Detects heavy-thinking slash commands (RFC / ADR) and reminds the model to
# confirm the session is on your top reasoning tier before running them.
# Output goes to stdout as additional context (cheap: ~30 tokens, only on
# trigger). The setup notice below is the other trigger, and fires once per
# session rather than on every prompt.

set -euo pipefail

input=$(cat)

# jq is how every hook in settings.example.json reads its stdin. Without it they
# all quietly succeed at doing nothing, secret scan and branch guard included.
# This hook's stdout is injected as context, so it is the one place that can say
# so where the user will see it.
if ! command -v jq >/dev/null 2>&1; then
  # This fires on every prompt, and the notice is worth a few hundred tokens
  # once, not once a turn. sed pulls the session id out because the missing
  # dependency is jq itself; the marker is an empty file in the temp directory,
  # which the OS clears on its own schedule.
  session=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  marker="${TMPDIR:-/tmp}/claude-kit-jq-notice.${session:-unknown}"
  if [ -e "$marker" ]; then
    exit 0
  fi
  # Subshell: an unwritable temp directory makes the redirection itself fail, and
  # bash reports that on its own stderr, where 2>/dev/null on the command would
  # not catch it. Failing to write the marker only costs a repeated notice.
  ( : > "$marker" ) 2>/dev/null || true
  cat <<'EOF'
[setup] jq is not on PATH, so this kit's guardrail hooks (branch guard, secret scan, protected-path guard) and the statusline cannot read their input and are doing nothing. Tell the user: install jq (`winget install jqlang.jq` on Windows, `brew install jq` on macOS, the distro package on Linux), then restart the session.
EOF
  exit 0
fi

prompt=$(printf '%s' "$input" | jq -r '.prompt // ""' 2>/dev/null || echo "")

if echo "$prompt" | grep -qiE '^/(rfc|adr)\b'; then
  cat <<'EOF'
[model-reminder hook] This is a heavy-reasoning command (RFC/ADR). If the current session model is not your top reasoning tier, briefly remind the user to switch (e.g. `/model`) before running it. Do not repeat this reminder if it already fired in this session.
EOF
fi

exit 0
