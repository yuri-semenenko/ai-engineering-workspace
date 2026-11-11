#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/.." && pwd)"
bash "$script_dir/check-delivery-links.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/scripts"
cp "$script_dir/check-delivery-links.sh" "$tmp/scripts/"
for p in claude-code/.claude/settings.example.json claude-code/.claude/hooks/model-reminder.sh claude-code/.claude/hooks/workflow-model-guard.sh claude-code/.claude/statusline.sh claude-code/.claude/skills/pr-recheck/SKILL.md claude-code/.claude/skills/pr-review/SKILL.md codex/skills/pr-recheck/SKILL.md codex/skills/pr-review/SKILL.md gemini/commands/pr-recheck.toml gemini/commands/pr-review.toml; do
  mkdir -p "$tmp/$(dirname "$p")"
  cp "$root/$p" "$tmp/$p"
done
bash "$tmp/scripts/check-delivery-links.sh" >/dev/null
mv "$tmp/claude-code/.claude/hooks/model-reminder.sh" "$tmp/claude-code/.claude/hooks/model-reminder.saved"
if out=$(bash "$tmp/scripts/check-delivery-links.sh" 2>&1); then echo 'missing hook was accepted' >&2; exit 1; fi
[[ "$out" == *'references missing claude-code/.claude/hooks/model-reminder.sh'* ]] || { echo "$out" >&2; exit 1; }
mv "$tmp/claude-code/.claude/hooks/model-reminder.saved" "$tmp/claude-code/.claude/hooks/model-reminder.sh"
mv "$tmp/codex/skills/pr-review/SKILL.md" "$tmp/codex/skills/pr-review/saved.md"
if out=$(bash "$tmp/scripts/check-delivery-links.sh" 2>&1); then echo 'missing skill was accepted' >&2; exit 1; fi
[[ "$out" == *'references missing codex/skills/pr-review/SKILL.md'* ]] || { echo "$out" >&2; exit 1; }
mv "$tmp/codex/skills/pr-review/saved.md" "$tmp/codex/skills/pr-review/SKILL.md"
sed 's/pr-review/missing-review/g' "$tmp/codex/skills/pr-recheck/SKILL.md" > "$tmp/codex/skills/pr-recheck/changed.md"
mv "$tmp/codex/skills/pr-recheck/changed.md" "$tmp/codex/skills/pr-recheck/SKILL.md"
if out=$(bash "$tmp/scripts/check-delivery-links.sh" 2>&1); then echo 'missing reference was accepted' >&2; exit 1; fi
[[ "$out" == *'codex/skills/pr-recheck/SKILL.md does not reference pr-review'* ]] || { echo "$out" >&2; exit 1; }
sed 's/missing-review/pr-review-missing/g' "$tmp/codex/skills/pr-recheck/SKILL.md" > "$tmp/codex/skills/pr-recheck/changed.md"
mv "$tmp/codex/skills/pr-recheck/changed.md" "$tmp/codex/skills/pr-recheck/SKILL.md"
if out=$(bash "$tmp/scripts/check-delivery-links.sh" 2>&1); then echo 'extended skill name was accepted' >&2; exit 1; fi
[[ "$out" == *'codex/skills/pr-recheck/SKILL.md does not reference pr-review'* ]] || { echo "$out" >&2; exit 1; }
echo 'delivery-links fixtures: missing hook, skill and reference rejected'
