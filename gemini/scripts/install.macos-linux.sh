#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # .../gemini
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
PERSONA_WIZARD="$REPO_ROOT/scripts/create-persona.sh"
GEMINI_HOME="${1:-${GEMINI_HOME:-$HOME/.gemini}}"
SOURCE_CONTEXT="$CONFIG_DIR/references/GEMINI.md"
SOURCE_COMMANDS="$CONFIG_DIR/commands"
SOURCE_SETTINGS="$CONFIG_DIR/settings.example.json"
TARGET_CONTEXT="$GEMINI_HOME/GEMINI.md"
TARGET_COMMANDS="$GEMINI_HOME/commands"
TARGET_SETTINGS="$GEMINI_HOME/settings.json"

if [ ! -f "$SOURCE_CONTEXT" ]; then
  echo "Source context not found: $SOURCE_CONTEXT" >&2
  echo "Run scripts/sync-codex-references.sh from the repo root to generate it." >&2
  exit 1
fi
if [ ! -d "$SOURCE_COMMANDS" ]; then
  echo "Source commands not found: $SOURCE_COMMANDS" >&2
  exit 1
fi
if [ ! -f "$SOURCE_SETTINGS" ]; then
  echo "Source settings not found: $SOURCE_SETTINGS" >&2
  exit 1
fi

mkdir -p "$GEMINI_HOME"

# Context file: prefer the user's filled condensed persona (scripts/create-persona.sh)
# over the committed template mirror. Falls back to the mirror when gemini/ is
# copied standalone without the persona/ dir. GEMINI.md is re-sent on every
# prompt, so the condensed persona is the right source (not the full one).
PERSONA_SOURCE="$REPO_ROOT/persona/CLAUDE.md"
PERSONA_FROM_WIZARD=0
if [ -e "$TARGET_CONTEXT" ] && [ ! -f "$TARGET_CONTEXT" ]; then
  echo "Persona target is not a regular file: $TARGET_CONTEXT" >&2
  exit 1
fi
if [ -f "$PERSONA_SOURCE" ]; then
  cp "$PERSONA_SOURCE" "$TARGET_CONTEXT"
  PERSONA_FROM_WIZARD=1
else
  cp "$SOURCE_CONTEXT" "$TARGET_CONTEXT"
fi

# The committed mirror ships {{PLACEHOLDERS}}, and a half-edited CLAUDE.md ships
# them too. GEMINI.md is re-sent on every prompt, so either one costs tokens on
# every turn to say nothing. Count what actually landed rather than trusting
# which branch ran: a silent fallback used to end on a clean "installed" summary.
if [ ! -f "$TARGET_CONTEXT" ]; then
  echo "Persona target is not a regular file: $TARGET_CONTEXT" >&2
  exit 1
fi
if PERSONA_UNFILLED="$(grep -c '{{' "$TARGET_CONTEXT")"; then
  :
else
  grep_status=$?
  if [ "$grep_status" -eq 1 ]; then
    PERSONA_UNFILLED=0
  else
    echo "Could not inspect persona target: $TARGET_CONTEXT" >&2
    exit "$grep_status"
  fi
fi

mkdir -p "$TARGET_COMMANDS"
cp "$SOURCE_COMMANDS"/*.toml "$TARGET_COMMANDS/"

# Seed settings only on first install; never clobber a user's existing config.
if [ -f "$TARGET_SETTINGS" ]; then
  echo "Left existing settings untouched: $TARGET_SETTINGS"
else
  cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
  echo "Seeded settings: $TARGET_SETTINGS"
fi

echo "Gemini CLI context, commands, and settings installed."
if [ "$PERSONA_UNFILLED" -gt 0 ]; then
  if [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
    echo "Persona: INCOMPLETE. $PERSONA_SOURCE still holds $PERSONA_UNFILLED unfilled {{PLACEHOLDER}} line(s), copied as-is."
  else
    echo "Persona: TEMPLATE ONLY. No $PERSONA_SOURCE, so the committed mirror landed with $PERSONA_UNFILLED unfilled {{PLACEHOLDER}} line(s)."
  fi
  if [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
    echo "Finish filling $PERSONA_SOURCE, then re-run this installer."
  elif [ -f "$PERSONA_WIZARD" ]; then
    echo "Run: bash \"$PERSONA_WIZARD\". Then re-run this installer."
  else
    echo "This standalone package has no persona wizard. Run the wizard and installer from a full repository checkout."
  fi
elif [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
  echo "Persona: installed from $PERSONA_SOURCE."
else
  echo "Persona: installed from the committed mirror; no $PERSONA_SOURCE, and nothing was left to fill."
fi
echo "Context target: $TARGET_CONTEXT (GEMINI.md, always-on persona)"
echo "Commands target: $TARGET_COMMANDS ($(ls -1 "$TARGET_COMMANDS"/*.toml 2>/dev/null | wc -l | tr -d ' ') process commands)"
echo "Settings target: $TARGET_SETTINGS (tool allowlist + guardrail hooks + sandbox)"
echo "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
