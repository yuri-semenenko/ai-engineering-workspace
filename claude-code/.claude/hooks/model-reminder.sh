#!/usr/bin/env bash
# UserPromptSubmit hook.
# Detects heavy-thinking slash commands (RFC / ADR) and reminds the model to
# confirm the session is on your top reasoning tier before running them.
# Output goes to stdout as additional context (cheap: ~30 tokens, only on trigger).

set -euo pipefail

# jq is how every hook in settings.example.json reads its stdin. Without it they
# all quietly succeed at doing nothing, secret scan and branch guard included.
# This hook's stdout is injected as context, so it is the one place that can say
# so where the user will see it.
if ! command -v jq >/dev/null 2>&1; then
  cat <<'EOF'
[setup] jq is not on PATH, so this kit's guardrail hooks (branch guard, secret scan, protected-path guard) and the statusline cannot read their input and are doing nothing. Tell the user once: install jq (`winget install jqlang.jq` on Windows, `brew install jq` on macOS, the distro package on Linux), then restart the session. Do not repeat this notice.
EOF
  exit 0
fi

prompt=$(jq -r '.prompt // ""' 2>/dev/null || echo "")

if echo "$prompt" | grep -qiE '^/(rfc|adr)\b'; then
  cat <<'EOF'
[model-reminder hook] This is a heavy-reasoning command (RFC/ADR). If the current session model is not your top reasoning tier, briefly remind the user to switch (e.g. `/model`) before running it. Do not repeat this reminder if it already fired in this session.
EOF
fi

exit 0
