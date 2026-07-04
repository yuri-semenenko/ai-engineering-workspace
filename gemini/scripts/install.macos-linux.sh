#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # .../gemini
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
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
if [ -f "$REPO_ROOT/persona/CLAUDE.md" ]; then
  cp "$REPO_ROOT/persona/CLAUDE.md" "$TARGET_CONTEXT"
  echo "Installed filled persona from persona/CLAUDE.md."
else
  cp "$SOURCE_CONTEXT" "$TARGET_CONTEXT"
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
echo "Context target: $TARGET_CONTEXT (GEMINI.md, always-on persona)"
echo "Commands target: $TARGET_COMMANDS ($(ls -1 "$TARGET_COMMANDS"/*.toml 2>/dev/null | wc -l | tr -d ' ') process commands)"
echo "Settings target: $TARGET_SETTINGS (tool allowlist + guardrail hooks + sandbox)"
echo "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
