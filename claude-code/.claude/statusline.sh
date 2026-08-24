#!/usr/bin/env bash
# Claude Code statusline: model · branch[*] · dir
# Receives JSON from Claude Code on stdin with fields:
#   .model.display_name, .workspace.current_dir, .workspace.cwd, .output_style.name

set -uo pipefail

input=$(cat)

# Every field below comes out of jq. Without it this would render as a bare
# separator and look like a styling bug, so name the cause instead.
if ! command -v jq >/dev/null 2>&1; then
  printf 'statusline needs jq (not on PATH)'
  exit 0
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .workspace.cwd // empty' 2>/dev/null)
style=$(printf '%s' "$input" | jq -r '.output_style.name // empty' 2>/dev/null)

dir=""
if [ -n "${cwd:-}" ]; then
  dir=$(basename "$cwd")
fi

git_part=""
if [ -n "${cwd:-}" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || true)
  dirty=""
  if ! git -C "$cwd" diff --quiet --ignore-submodules 2>/dev/null \
     || ! git -C "$cwd" diff --cached --quiet --ignore-submodules 2>/dev/null; then
    dirty="*"
  fi
  if [ -n "$branch" ]; then
    git_part=" · ${branch}${dirty}"
  fi
fi

style_part=""
if [ -n "${style:-}" ] && [ "$style" != "default" ]; then
  style_part=" · ${style}"
fi

printf '%s%s · %s%s' "$model" "$git_part" "${dir:-~}" "$style_part"
