#!/usr/bin/env bash
set -euo pipefail

# Guard: the wizard's recommended-skills mapping must only ever reference skills
# that actually ship, across every discipline x seniority combination. Catches a
# mapping edit that points at a renamed or nonexistent skill before it reaches a
# user. Run in CI and locally.
#
#   scripts/check-recommended-skills.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/claude-code/.claude/skills"
WIZARD="$REPO_ROOT/scripts/create-persona.sh"
REC="$REPO_ROOT/persona/recommended-skills.md"

[ -d "$SKILLS_DIR" ] || { echo "Skill catalog missing: $SKILLS_DIR" >&2; exit 1; }

catalog="$(for d in "$SKILLS_DIR"/*/; do basename "$d"; done | sort)"
status=0

for d in frontend fullstack; do
  for s in mid senior staff principal; do
    if ! DISCIPLINE="$d" SENIORITY="$s" bash "$WIZARD" --defaults >/dev/null 2>&1; then
      echo "[$d/$s] wizard failed (recommended skill not in catalog)" >&2
      status=1
      continue
    fi
    # Independently re-check the generated "Recommended" section.
    names="$(awk '
      /^## Recommended for your profile/ { f=1; next }
      /^## / { f=0 }
      f && /^- / { sub(/^- /,""); print }
    ' "$REC")"
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      if ! printf '%s\n' "$catalog" | grep -qxF "$name"; then
        echo "[$d/$s] recommends unknown skill: $name" >&2
        status=1
      fi
    done <<< "$names"
  done
done

if [ "$status" -eq 0 ]; then
  echo "recommended-skills: all references valid across 8 profiles"
fi
exit $status
