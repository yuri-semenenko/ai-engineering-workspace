#!/usr/bin/env bash
set -euo pipefail

# Generate your own persona.md + CLAUDE.md from the shared templates.
#
# The methodology (simplicity ladder, RFC/ADR format, PR-review tiers, git
# rules, verification criterion, ...) is fixed canon and applies to everyone.
# This wizard only asks about the identity/stack/tooling header.
#
# Output (both gitignored, they are YOUR files, not the repo's):
#   persona/persona.md   full persona
#   persona/CLAUDE.md     condensed, for ~/.claude/CLAUDE.md
#
#   scripts/create-persona.sh              interactive
#   scripts/create-persona.sh --defaults    accept every default, no prompts (CI)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERSONA_DIR="$REPO_ROOT/persona"
PERSONA_TEMPLATE="$PERSONA_DIR/persona.template.md"
CLAUDE_TEMPLATE="$PERSONA_DIR/CLAUDE.template.md"

USE_DEFAULTS=0
if [ "${1:-}" = "--defaults" ] || [ ! -t 0 ]; then
  USE_DEFAULTS=1
fi

for f in "$PERSONA_TEMPLATE" "$CLAUDE_TEMPLATE"; do
  [ -f "$f" ] || { echo "Template not found: $f" >&2; exit 1; }
done

# ask VAR "Prompt" "default"  -> sets global $VAR (env override or prompt or default)
ask() {
  local __var="$1" __prompt="$2" __default="$3" __env="${!1:-}" __reply
  if [ -n "$__env" ]; then
    printf -v "$__var" '%s' "$__env"; return
  fi
  if [ "$USE_DEFAULTS" -eq 1 ]; then
    printf -v "$__var" '%s' "$__default"; return
  fi
  read -r -p "$__prompt [$__default]: " __reply || __reply=""
  printf -v "$__var" '%s' "${__reply:-$__default}"
}

echo "Creating your persona. Press Enter to accept each default."
echo

ask ROLE              "Role / title"                       "Staff Engineer and Senior Individual Contributor"
ask BACKGROUND        "Background (fragment: 'my background is ...')" "primarily frontend engineering, but my current scope is full-stack architecture, technical leadership, system design, and engineering decision-making"
ask PRIMARY_LANGUAGES "Primary languages"                  "TypeScript, JavaScript"
ask FRONTEND_STACK    "Frontend stack"                     "React, Next.js"
ask BACKEND_STACK     "Backend stack"                      "Node.js (TypeScript)"
ask DATABASE          "Database"                           "PostgreSQL"
ask TESTING_STACK     "Testing stack"                      "Vitest, React Testing Library"
ask INFRA             "Infrastructure"                     "Vercel"
ask PACKAGE_MANAGER   "Package manager"                    "npm"
ask REPO_LAYOUT       "Repo layout"                        "Monorepo"
ask ISSUE_TRACKER     "Issue tracker"                      "Jira"
ask OUTPUT_LANGUAGE   "Output language for PR/review text" "English"

# BACKGROUND_SHORT: a standalone sentence for the condensed CLAUDE.md.
first_char="$(printf '%s' "$BACKGROUND" | cut -c1 | tr '[:lower:]' '[:upper:]')"
rest="$(printf '%s' "$BACKGROUND" | cut -c2-)"
BACKGROUND_SHORT="${first_char}${rest}."

# Replace every {{KEY}} in the template text with its value (literal, no regex).
fill() {
  local content; content="$(cat "$1")"
  local key val
  for key in ROLE BACKGROUND BACKGROUND_SHORT PRIMARY_LANGUAGES FRONTEND_STACK \
             BACKEND_STACK DATABASE TESTING_STACK INFRA PACKAGE_MANAGER \
             REPO_LAYOUT ISSUE_TRACKER OUTPUT_LANGUAGE; do
    val="${!key}"
    content="${content//\{\{$key\}\}/$val}"
  done
  # Drop the leading template HTML comment block.
  printf '%s\n' "$content" | sed '/^<!--$/,/^-->$/d'
}

fill "$PERSONA_TEMPLATE" > "$PERSONA_DIR/persona.md"
fill "$CLAUDE_TEMPLATE"  > "$PERSONA_DIR/CLAUDE.md"

echo
echo "Wrote:"
echo "  $PERSONA_DIR/persona.md"
echo "  $PERSONA_DIR/CLAUDE.md"
echo
echo "Next: run the per-tool installers. They pick up these filled files"
echo "automatically (see each tool's scripts/ and the top-level README)."
