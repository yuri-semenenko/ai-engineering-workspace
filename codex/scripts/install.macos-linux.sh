#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # .../codex
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
PERSONA_WIZARD="$REPO_ROOT/scripts/create-persona.sh"
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
PERSONA_SOURCE="$REPO_ROOT/persona/persona.md"
PERSONA_FROM_WIZARD=0
if [ -f "$PERSONA_SOURCE" ]; then
  cp "$PERSONA_SOURCE" "$TARGET_REFERENCES/persona.md"
  PERSONA_FROM_WIZARD=1
fi

# The committed mirror ships {{PLACEHOLDERS}}, and a half-edited persona.md
# ships them too. Codex loads whichever landed and reads them as literal text,
# so count what is actually in the installed file rather than trusting which
# branch ran: a silent fallback used to end on a clean "installed" summary.
PERSONA_TARGET="$TARGET_REFERENCES/persona.md"
if [ ! -f "$PERSONA_TARGET" ]; then
  echo "Persona target is not a regular file: $PERSONA_TARGET" >&2
  exit 1
fi
if PERSONA_UNFILLED="$(grep -c '{{' "$PERSONA_TARGET")"; then
  :
else
  grep_status=$?
  if [ "$grep_status" -eq 1 ]; then
    PERSONA_UNFILLED=0
  else
    echo "Could not inspect persona target: $PERSONA_TARGET" >&2
    exit "$grep_status"
  fi
fi

mkdir -p "$TARGET_SKILLS"
cp -R "$CONFIG_DIR/skills/." "$TARGET_SKILLS/"

mkdir -p "$CODEX_HOME"
cp "$CONFIG_DIR/AGENTS.md" "$TARGET_AGENTS"

echo "Codex references, user skills, and AGENTS.md installed."
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
echo "References target: $TARGET_REFERENCES"
echo "Skills target: $TARGET_SKILLS"
echo "AGENTS.md target: $TARGET_AGENTS (always-on git guardrails)"
echo "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
