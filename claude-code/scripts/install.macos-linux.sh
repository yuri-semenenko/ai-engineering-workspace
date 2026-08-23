#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"          # .../claude-code
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"
PERSONA_DIR="$REPO_ROOT/persona"
TARGET_DIR="$HOME/.claude"

mkdir -p "$HOME"

# --- 1. Persona: generate the user's own files on first install ---------------
# create-persona.sh prompts when stdin is a TTY and accepts defaults otherwise.
if [ ! -f "$PERSONA_DIR/CLAUDE.md" ]; then
  echo "No persona found yet. Running the persona wizard..."
  bash "$REPO_ROOT/scripts/create-persona.sh"
fi

# --- 2. Symlink the .claude tree (skills, agents, hooks, statusline) ----------
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
  if [ -L "$TARGET_DIR" ] && [ "$(readlink "$TARGET_DIR")" = "$CONFIG_DIR/.claude" ]; then
    echo "Claude config symlink already points to this repository."
  else
    backup="$HOME/.claude.backup.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET_DIR" "$backup"
    ln -s "$CONFIG_DIR/.claude" "$TARGET_DIR"
    echo "Moved previous Claude config to $backup."
  fi
else
  ln -s "$CONFIG_DIR/.claude" "$TARGET_DIR"
fi

# --- 3. Provision user-specific files (gitignored, live inside the symlink) ---
# CLAUDE.md is read from ~/.claude/CLAUDE.md; the full persona.md sits at ~/.
cp "$PERSONA_DIR/CLAUDE.md" "$CONFIG_DIR/.claude/CLAUDE.md"
[ -f "$PERSONA_DIR/persona.md" ] && cp "$PERSONA_DIR/persona.md" "$HOME/persona.md"

# settings.json is user-owned; seed it from the example only if absent.
if [ ! -f "$CONFIG_DIR/.claude/settings.json" ]; then
  cp "$CONFIG_DIR/.claude/settings.example.json" "$CONFIG_DIR/.claude/settings.json"
  echo "Seeded settings.json from settings.example.json (edit freely; it is gitignored)."
fi

echo "Claude config installed."
echo "Claude config target: $TARGET_DIR"
echo "Codex references are provisioned separately by codex/scripts/install.macos-linux.sh."

# The hooks and statusline read their input with jq. Say so at install time: a
# missing dependency turns the guardrails into no-ops rather than into an error.
if ! command -v jq >/dev/null 2>&1; then
  echo "WARNING: jq is not on PATH. The hooks and statusline parse their input with jq, so until it is installed the branch guard, secret scan, and protected-path guard do nothing at all." >&2
fi
