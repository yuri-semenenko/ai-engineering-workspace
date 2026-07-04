#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # .../codex
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
CODEX_HOME="${1:-${CODEX_HOME:-$HOME/.codex}}"
TARGET_REFERENCES="$CODEX_HOME/references"
TARGET_SKILLS="$CODEX_HOME/skills"
TARGET_AGENTS="$CODEX_HOME/AGENTS.md"

if [ ! -d "$CONFIG_DIR/references" ]; then
  echo "Source references not found: $CONFIG_DIR/references" >&2
  exit 1
fi
if [ ! -d "$CONFIG_DIR/skills" ]; then
  echo "Source skills not found: $CONFIG_DIR/skills" >&2
  exit 1
fi
if [ ! -f "$CONFIG_DIR/AGENTS.md" ]; then
  echo "Source AGENTS.md not found: $CONFIG_DIR/AGENTS.md" >&2
  exit 1
fi

mkdir -p "$TARGET_REFERENCES"
cp -R "$CONFIG_DIR/references/." "$TARGET_REFERENCES/"

# If the user generated a filled persona (scripts/create-persona.sh), install
# that instead of the committed template mirror. Falls back to the mirror when
# codex/ is copied standalone without the persona/ dir.
if [ -f "$REPO_ROOT/persona/persona.md" ]; then
  cp "$REPO_ROOT/persona/persona.md" "$TARGET_REFERENCES/persona.md"
  echo "Installed filled persona from persona/persona.md."
fi

mkdir -p "$TARGET_SKILLS"
cp -R "$CONFIG_DIR/skills/." "$TARGET_SKILLS/"

mkdir -p "$CODEX_HOME"
cp "$CONFIG_DIR/AGENTS.md" "$TARGET_AGENTS"

echo "Codex references, user skills, and AGENTS.md installed."
echo "References target: $TARGET_REFERENCES"
echo "Skills target: $TARGET_SKILLS"
echo "AGENTS.md target: $TARGET_AGENTS (always-on git guardrails)"
echo "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
