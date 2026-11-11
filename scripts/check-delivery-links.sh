#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
settings="$root/claude-code/.claude/settings.example.json"
command -v jq >/dev/null 2>&1 || { echo 'delivery-links: jq is required; settings were not checked' >&2; exit 1; }
commands=$(jq -esr '
  if length != 1 then error("one JSON value is required") else .[0] end |
  if (.hooks | type) != "object" then error("hooks must be an object")
  elif any(.hooks[]; type != "array") then error("hook events must be arrays")
  elif any(.hooks[][]; type != "object" or (.hooks | type) != "array") then error("hook groups must contain arrays")
  elif any(.hooks[][].hooks[]; type != "object") then error("hooks must be objects")
  else
    [.hooks[][]?.hooks[]?.command | select(type == "string")] as $hooks |
    .statusLine.command as $status |
    if ($status | type) != "string" or ($status | startswith("bash ~/.claude/") | not)
       or (any($hooks[]; startswith("bash ~/.claude/")) | not) then
      error("local hook and status line are required")
    elif ([$hooks[], $status] | any(.[]; test("[\\r\\n]"))) then
      error("multiline commands are unsupported")
    else $hooks[], $status end
  end' "$settings") || {
  echo "delivery-links: cannot parse commands in $settings" >&2; exit 1;
}
[ -n "$commands" ] || { echo "delivery-links: no commands in $settings" >&2; exit 1; }
bad=0
while IFS= read -r command; do
  command=${command%$'\r'}
  case "$command" in
    'bash ~/.claude/'*)
      relative=${command#'bash ~/.claude/'}
      if [[ "$relative" != statusline.sh && ! "$relative" =~ ^hooks/[A-Za-z0-9._-]+\.sh$ ]] || [[ "$relative" == *'..'* ]]; then
        echo "delivery-links: unsupported command in $settings: $command" >&2; bad=1; continue
      fi
      if [ ! -f "$root/claude-code/.claude/$relative" ]; then
        echo "delivery-links: $settings references missing claude-code/.claude/$relative" >&2; bad=1
      fi
      ;;
  esac
done <<< "$commands"

check_pair() {
  local source="$1" target="$2" name="$3"
  if [ ! -f "$root/$source" ] || ! LC_ALL=C grep -Eq "(^|[^A-Za-z0-9_-])${name}([^A-Za-z0-9_-]|$)" "$root/$source"; then
    echo "delivery-links: $source does not reference $name" >&2; bad=1
  fi
  if [ ! -f "$root/$target" ]; then
    echo "delivery-links: $source references missing $target" >&2; bad=1
  fi
}
check_pair claude-code/.claude/skills/pr-recheck/SKILL.md claude-code/.claude/skills/pr-review/SKILL.md pr-review
check_pair codex/skills/pr-recheck/SKILL.md codex/skills/pr-review/SKILL.md pr-review
check_pair codex/skills/pr-review/SKILL.md codex/skills/pr-recheck/SKILL.md pr-recheck
check_pair gemini/commands/pr-recheck.toml gemini/commands/pr-review.toml pr-review
if [ "$bad" -ne 0 ]; then exit 1; fi
echo 'delivery-links: checked Claude commands and declared review links'
