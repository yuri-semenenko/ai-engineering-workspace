#!/usr/bin/env bash
set -euo pipefail

# Single source of truth for shared references, plus a structural guard for
# the owned-here Codex skills.
#
# Canon lives in persona/ and claude-code/. codex/references/{persona.md,
# memory-seed.example} are GENERATED MIRRORS of that canon, committed so codex/
# stays standalone-portable (the folder is copied alone to a target machine and
# its own installer runs against the files already present).
#
# codex/skills/ is NOT a mirror: those skills are owned here (hand-authored
# Codex ports, no canon to generate them from). They cannot be auto-synced, so
# this script instead validates their structure: every skill has SKILL.md +
# agents/openai.yaml and a frontmatter name matching its directory.
#
# Do not hand-edit the codex reference mirror. Edit the canon, then run this script.
#
#   scripts/sync-codex-references.sh           # regenerate the mirror + validate skills
#   scripts/sync-codex-references.sh --check    # fail if mirror drifted or skills broke (CI/hook)
#
# PowerShell equivalent for native Windows shells:
#   scripts/sync-codex-references.ps1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CANON_PERSONA="$REPO_ROOT/persona/persona.template.md"
CANON_MEMORY="$REPO_ROOT/claude-code/.claude/memory-seed.example"
MIRROR_PERSONA="$REPO_ROOT/codex/references/persona.md"
MIRROR_MEMORY="$REPO_ROOT/codex/references/memory-seed.example"
SKILLS_DIR="$REPO_ROOT/codex/skills"

# Validate the owned-here Codex skills. Returns nonzero and prints each problem
# to stderr. There is no auto-fix: skills have no canon to regenerate from.
validate_skills() {
  local status=0
  local entry name skill_md agent_yaml fm_name

  if [ ! -d "$SKILLS_DIR" ]; then
    echo "SKILLS: directory missing: $SKILLS_DIR" >&2
    return 1
  fi

  for entry in "$SKILLS_DIR"/*; do
    [ -e "$entry" ] || continue
    if [ ! -d "$entry" ]; then
      echo "SKILLS: stray file at skills root: ${entry#"$REPO_ROOT"/}" >&2
      status=1
      continue
    fi

    name="$(basename "$entry")"
    skill_md="$entry/SKILL.md"
    agent_yaml="$entry/agents/openai.yaml"

    if [ ! -f "$skill_md" ]; then
      echo "SKILLS: $name missing SKILL.md" >&2
      status=1
    fi
    if [ ! -f "$agent_yaml" ]; then
      echo "SKILLS: $name missing agents/openai.yaml" >&2
      status=1
    fi

    if [ -f "$skill_md" ]; then
      fm_name="$(awk '
        NR==1 && $0 !~ /^---[[:space:]]*$/ { exit }
        /^---[[:space:]]*$/ { c++; if (c==2) exit; next }
        c>=1 && /^name:/ { sub(/^name:[[:space:]]*/,""); gsub(/[[:space:]]+$/,""); print; exit }
      ' "$skill_md")"
      if [ -z "$fm_name" ]; then
        echo "SKILLS: $name SKILL.md has no frontmatter name:" >&2
        status=1
      elif [ "$fm_name" != "$name" ]; then
        echo "SKILLS: $name frontmatter name ('$fm_name') != directory name" >&2
        status=1
      fi
    fi
  done

  return "$status"
}

if [ "${1:-}" = "--check" ]; then
  mirror_status=0
  skills_status=0
  if ! diff -q "$CANON_PERSONA" "$MIRROR_PERSONA" >/dev/null 2>&1; then
    echo "DRIFT: codex/references/persona.md differs from canon" >&2
    mirror_status=1
  fi
  if ! diff -rq "$CANON_MEMORY" "$MIRROR_MEMORY" >/dev/null 2>&1; then
    echo "DRIFT: codex/references/memory-seed.example differs from canon" >&2
    mirror_status=1
  fi
  if ! validate_skills; then
    echo "Fix the skill structure above (no auto-fix: skills are owned-here canon)." >&2
    skills_status=1
  fi
  if [ "$mirror_status" -ne 0 ]; then
    echo "Run: scripts/sync-codex-references.sh && git add codex/references" >&2
  fi
  exit $((mirror_status | skills_status))
elif [ -n "${1:-}" ]; then
  echo "Unknown argument: $1" >&2
  echo "Usage: sync-codex-references.sh [--check]" >&2
  exit 2
fi

# Fail before the destructive rm if the canon is missing, so a bad checkout
# can't leave the mirror empty.
if [ ! -f "$CANON_PERSONA" ]; then
  echo "Canon persona missing: $CANON_PERSONA" >&2
  exit 1
fi
if [ ! -d "$CANON_MEMORY" ]; then
  echo "Canon memory-seed missing: $CANON_MEMORY" >&2
  exit 1
fi

cp "$CANON_PERSONA" "$MIRROR_PERSONA"
rm -rf "$MIRROR_MEMORY"
mkdir -p "$MIRROR_MEMORY"
cp -R "$CANON_MEMORY/." "$MIRROR_MEMORY/"

echo "Synced codex/references from canon (persona/ + claude-code/)."

# Skills are owned-here and cannot be regenerated; surface broken structure now.
if ! validate_skills; then
  echo "Skill structure invalid (owned-here canon, no auto-fix). Fix the files above." >&2
  exit 1
fi
echo "Validated codex/skills structure."
