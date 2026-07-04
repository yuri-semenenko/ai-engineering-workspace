#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_HOME="${1:-$HOME}"
WORKSPACE_PATH="${2:-}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

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

copy_with_backup "$SOURCE_HOME_CONFIG/copilot-instructions.md" "$TARGET_COPILOT/copilot-instructions.md"

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
