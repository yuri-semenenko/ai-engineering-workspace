#!/usr/bin/env bash
set -euo pipefail

# Validate the canonical Markdown loop contracts. This deliberately uses only
# portable shell tools: the loop model stays readable prose, with no parser or
# package dependency added solely for validation.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "--root" ] && [ -n "${2:-}" ] && [ -z "${3:-}" ]; then
  REPO_ROOT="$(cd "$2" && pwd)"
elif [ -n "${1:-}" ]; then
  echo "Usage: scripts/validate-loops.sh [--root <repository-root>]" >&2
  exit 2
fi

LOOPS_ROOT="$REPO_ROOT/loops"
SKILLS_ROOT="$REPO_ROOT/claude-code/.claude/skills"
REQUIRED_SECTIONS=(
  "## Identity"
  "## Purpose"
  "## Scope"
  "## Inputs"
  "## Skill composition"
  "## State"
  "## Verification"
  "## Output"
  "## Limits"
  "## Human handoff"
  "## Autonomy"
)

status=0
declare -A identifiers=()

fail() {
  echo "LOOPS: $*" >&2
  status=1
}

[ -d "$LOOPS_ROOT" ] || { echo "LOOPS: directory missing: $LOOPS_ROOT" >&2; exit 1; }
[ -d "$SKILLS_ROOT" ] || { echo "LOOPS: canonical skills directory missing: $SKILLS_ROOT" >&2; exit 1; }

loop_count=0
for loop_dir in "$LOOPS_ROOT"/*; do
  [ -e "$loop_dir" ] || continue
  if [ ! -d "$loop_dir" ]; then
    continue
  fi

  loop_count=$((loop_count + 1))
  name="$(basename "$loop_dir")"
  loop_md="$loop_dir/LOOP.md"

  for required_file in LOOP.md output.md state.example.md; do
    [ -f "$loop_dir/$required_file" ] || fail "$name missing $required_file"
  done
  [ -f "$loop_md" ] || continue

  for section in "${REQUIRED_SECTIONS[@]}"; do
    grep -Fqx "$section" "$loop_md" || fail "$name missing required section: $section"
  done

  identifier="$(sed -n 's/^- \*\*Identifier:\*\* `\([^`]*\)`$/\1/p' "$loop_md" | head -n 1)"
  if [ -z "$identifier" ]; then
    fail "$name has no stable Identifier"
  elif [ "$identifier" != "$name" ]; then
    fail "$name Identifier ('$identifier') does not match directory name"
  elif [ -n "${identifiers[$identifier]+x}" ]; then
    fail "duplicate Identifier: $identifier"
  else
    identifiers[$identifier]=1
  fi

  autonomy="$(sed -n 's/^- \*\*Autonomy level:\*\* `\([^`]*\)`$/\1/p' "$loop_md" | head -n 1)"
  case "$autonomy" in
    L0\ —\ Documented|L1\ —\ Report\ Only) ;;
    *) fail "$name declares unsupported autonomy level: ${autonomy:-missing}" ;;
  esac

  grep -Fq '[output.md](output.md)' "$loop_md" || fail "$name does not link output.md"
  grep -Fq '[state.example.md](state.example.md)' "$loop_md" || fail "$name does not link state.example.md"

  skill_refs="$(grep -oE 'skills/[a-z0-9-]+/SKILL\.md' "$loop_md" | sort -u || true)"
  if [ -z "$skill_refs" ]; then
    fail "$name references no canonical skills"
  else
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      skill_name="$(basename "$(dirname "$ref")")"
      [ -f "$SKILLS_ROOT/$skill_name/SKILL.md" ] || fail "$name references unknown skill: $skill_name"
    done <<< "$skill_refs"
  fi

  if [ "$autonomy" = "L1 — Report Only" ]; then
    grep -Fqx '### Prohibited write and outbound actions' "$loop_md" || fail "$name L1 loop lacks write-action prohibition heading"
    grep -Fqi 'must not' "$loop_md" || fail "$name L1 loop does not explicitly prohibit write actions"
  fi
done

[ "$loop_count" -gt 0 ] || fail "no loop directories found"

if [ "$status" -eq 0 ]; then
  echo "loops: $loop_count canonical loop contracts valid"
fi
exit "$status"
