#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
PERSONA_WIZARD="$REPO_ROOT/scripts/create-persona.sh"
TARGET_HOME="${1:-$HOME}"
WORKSPACE_PATH="${2:-}"
# Random tail: the timestamp alone collides when the installer runs twice in
# the same second, and the second run would then overwrite its own backup.
TIMESTAMP="$(date +%Y%m%d-%H%M%S)-$(printf '%04d' $((RANDOM % 10000)))"

copy_with_backup() {
  local source="$1"
  local destination="$2"

  if [ ! -e "$source" ]; then
    echo "Source not found: $source" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$destination")"

  if [ -e "$destination" ]; then
    local backup="${destination}.pre-copilot-config.${TIMESTAMP}"
    mv "$destination" "$backup"
    echo "Backed up $destination to $backup"
  fi

  cp "$source" "$destination"
  echo "Copied $destination"
}

SOURCE_HOME_CONFIG="$CONFIG_DIR/home/.copilot"
TARGET_COPILOT="$TARGET_HOME/.copilot"

# Prefer the wizard's filled instructions; fall back to the committed template
# (which still holds {{PLACEHOLDERS}}) when copilot/ is used standalone.
FILLED_COPILOT="$REPO_ROOT/persona/copilot-instructions.md"
PERSONA_FROM_WIZARD=0
if [ -f "$FILLED_COPILOT" ]; then
  copy_with_backup "$FILLED_COPILOT" "$TARGET_COPILOT/copilot-instructions.md"
  PERSONA_FROM_WIZARD=1
else
  copy_with_backup "$SOURCE_HOME_CONFIG/copilot-instructions.md" "$TARGET_COPILOT/copilot-instructions.md"
fi

# The committed template ships {{PLACEHOLDERS}}, and a half-edited wizard output
# ships them too. Copilot reads whichever landed as literal text, so count what
# is actually in the installed file rather than trusting which branch ran: a
# silent fallback used to end on a clean "Done." with nothing else said.
PERSONA_TARGET="$TARGET_COPILOT/copilot-instructions.md"
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

mkdir -p "$TARGET_COPILOT/instructions"
for source in "$SOURCE_HOME_CONFIG"/instructions/*.instructions.md; do
  copy_with_backup "$source" "$TARGET_COPILOT/instructions/$(basename "$source")"
done

if [ -n "$WORKSPACE_PATH" ]; then
  copy_with_backup "$CONFIG_DIR/workspace-template/AGENTS.md" "$WORKSPACE_PATH/AGENTS.md"
  mkdir -p "$WORKSPACE_PATH/.github/instructions" "$WORKSPACE_PATH/.github/prompts"
  copy_with_backup "$CONFIG_DIR/workspace-template/.github/copilot-instructions.md" "$WORKSPACE_PATH/.github/copilot-instructions.md"

  for source in "$CONFIG_DIR"/workspace-template/.github/instructions/*.instructions.md; do
    copy_with_backup "$source" "$WORKSPACE_PATH/.github/instructions/$(basename "$source")"
  done

  for source in "$CONFIG_DIR"/workspace-template/.github/prompts/*.prompt.md; do
    copy_with_backup "$source" "$WORKSPACE_PATH/.github/prompts/$(basename "$source")"
  done
fi

echo ""
echo "Done. No auth files, hooks, MCP config, memory files, logs, or sessions were copied."
if [ "$PERSONA_UNFILLED" -gt 0 ]; then
  if [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
    echo "Persona: INCOMPLETE. $FILLED_COPILOT still holds $PERSONA_UNFILLED unfilled {{PLACEHOLDER}} line(s), copied as-is."
  else
    echo "Persona: TEMPLATE ONLY. No $FILLED_COPILOT, so the committed template landed with $PERSONA_UNFILLED unfilled {{PLACEHOLDER}} line(s)."
  fi
  if [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
    echo "Finish filling $FILLED_COPILOT, then re-run this installer."
  elif [ -f "$PERSONA_WIZARD" ]; then
    echo "Run: bash \"$PERSONA_WIZARD\". Then re-run this installer."
  else
    echo "This standalone package has no persona wizard. Run the wizard and installer from a full repository checkout."
  fi
elif [ "$PERSONA_FROM_WIZARD" -eq 1 ]; then
  echo "Persona: installed from $FILLED_COPILOT."
else
  echo "Persona: installed from the committed template; no $FILLED_COPILOT, and nothing was left to fill."
fi

if [ -z "$WORKSPACE_PATH" ]; then
  echo "For repository-level setup, re-run with a workspace path as the second argument."
fi
