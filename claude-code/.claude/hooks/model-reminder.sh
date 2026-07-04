#!/usr/bin/env bash
# UserPromptSubmit hook.
# Detects heavy-thinking slash commands (RFC / ADR) and reminds the model to
# confirm the session is on your top reasoning tier before running them.
# Output goes to stdout as additional context (cheap: ~30 tokens, only on trigger).

set -euo pipefail

prompt=$(jq -r '.prompt // ""' 2>/dev/null || echo "")

if echo "$prompt" | grep -qiE '^/(rfc|adr)\b'; then
  cat <<'EOF'
[model-reminder hook] This is a heavy-reasoning command (RFC/ADR). If the current session model is not your top reasoning tier, briefly remind the user to switch (e.g. `/model`) before running it. Do not repeat this reminder if it already fired in this session.
EOF
fi

exit 0
