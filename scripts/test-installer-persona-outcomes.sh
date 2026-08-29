#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Build only the package surface these tests need. Generated persona files are
# gitignored and deliberately excluded, so local runs cannot overwrite a user's
# real profile and start from the same state as a fresh clone.
REPO="$TEST_ROOT/repo"
mkdir -p "$REPO/scripts" "$REPO/persona"
cp -R "$SOURCE_ROOT/codex" "$REPO/codex"
cp -R "$SOURCE_ROOT/gemini" "$REPO/gemini"
cp -R "$SOURCE_ROOT/copilot" "$REPO/copilot"
cp "$SOURCE_ROOT/scripts/create-persona.sh" "$REPO/scripts/create-persona.sh"

expect() {
  case "$2" in
    *"$1"*) ;;
    *) echo "missing from $3 output: $1"; printf '%s\n' "$2"; exit 1 ;;
  esac
}

reject() {
  case "$2" in
    *"$1"*) echo "unexpected in $3 output: $1"; printf '%s\n' "$2"; exit 1 ;;
    *) ;;
  esac
}

expect_outcome() {
  local context="$1"
  local label="$2"
  local output="$3"
  local lines
  lines="$(printf '%s\n' "$output" | grep -c '^Persona:')"
  [ "$lines" -eq 1 ] || {
    echo "$context emitted $lines Persona outcomes"
    printf '%s\n' "$output"
    exit 1
  }
  expect "Persona: $label" "$output" "$context"
}

# No generated source: every package installs its committed template and names
# the available full-repository wizard. The reported count must match the file
# that actually landed.
codex_home="$TEST_ROOT/homes/codex-template"
out="$(bash "$REPO/codex/scripts/install.macos-linux.sh" "$codex_home")"
expect_outcome codex-template 'TEMPLATE ONLY' "$out"
count="$(grep -c '{{' "$codex_home/references/persona.md")"
expect "$count unfilled {{PLACEHOLDER}} line(s)" "$out" codex-template
expect 'Run: bash ' "$out" codex-template

gemini_home="$TEST_ROOT/homes/gemini-template"
out="$(bash "$REPO/gemini/scripts/install.macos-linux.sh" "$gemini_home")"
expect_outcome gemini-template 'TEMPLATE ONLY' "$out"
count="$(grep -c '{{' "$gemini_home/GEMINI.md")"
expect "$count unfilled {{PLACEHOLDER}} line(s)" "$out" gemini-template
expect 'Run: bash ' "$out" gemini-template

copilot_home="$TEST_ROOT/homes/copilot-template"
out="$(bash "$REPO/copilot/scripts/install.macos-linux.sh" "$copilot_home")"
expect_outcome copilot-template 'TEMPLATE ONLY' "$out"
count="$(grep -c '{{' "$copilot_home/.copilot/copilot-instructions.md")"
expect "$count unfilled {{PLACEHOLDER}} line(s)" "$out" copilot-template
expect 'Run: bash ' "$out" copilot-template
expect 'For repository-level setup' "$out" copilot-template

# Existing but half-filled sources are a separate state and require a
# source-specific remedy. Two lines make the reported count observable.
printf 'Role: {{ROLE}}\nStack: {{STACK}}\n' > "$REPO/persona/persona.md"
printf 'Role: {{ROLE}}\nStack: {{STACK}}\n' > "$REPO/persona/CLAUDE.md"
printf 'Role: {{ROLE}}\nStack: {{STACK}}\n' > "$REPO/persona/copilot-instructions.md"

out="$(bash "$REPO/codex/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/codex-incomplete")"
expect_outcome codex-incomplete INCOMPLETE "$out"
expect '2 unfilled {{PLACEHOLDER}} line(s)' "$out" codex-incomplete
expect "Finish filling $REPO/persona/persona.md" "$out" codex-incomplete

out="$(bash "$REPO/gemini/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/gemini-incomplete")"
expect_outcome gemini-incomplete INCOMPLETE "$out"
expect '2 unfilled {{PLACEHOLDER}} line(s)' "$out" gemini-incomplete
expect "Finish filling $REPO/persona/CLAUDE.md" "$out" gemini-incomplete

out="$(bash "$REPO/copilot/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/copilot-incomplete")"
expect_outcome copilot-incomplete INCOMPLETE "$out"
expect '2 unfilled {{PLACEHOLDER}} line(s)' "$out" copilot-incomplete
expect "Finish filling $REPO/persona/copilot-instructions.md" "$out" copilot-incomplete

# A complete generated source must produce the one success outcome and name the
# exact file it copied.
printf 'Role: Staff Engineer\n' > "$REPO/persona/persona.md"
printf 'Role: Staff Engineer\n' > "$REPO/persona/CLAUDE.md"
printf 'Role: Staff Engineer\n' > "$REPO/persona/copilot-instructions.md"

out="$(bash "$REPO/codex/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/codex-filled")"
expect_outcome codex-filled 'installed from' "$out"
expect "$REPO/persona/persona.md" "$out" codex-filled

out="$(bash "$REPO/gemini/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/gemini-filled")"
expect_outcome gemini-filled 'installed from' "$out"
expect "$REPO/persona/CLAUDE.md" "$out" gemini-filled

out="$(bash "$REPO/copilot/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/copilot-filled")"
expect_outcome copilot-filled 'installed from' "$out"
expect "$REPO/persona/copilot-instructions.md" "$out" copilot-filled

# Same-path/different-type must fail before cp can nest the context file and a
# content check can accidentally report success.
collision_home="$TEST_ROOT/homes/gemini-collision"
mkdir -p "$collision_home/GEMINI.md"
if out="$(bash "$REPO/gemini/scripts/install.macos-linux.sh" "$collision_home" 2>&1)"; then
  echo 'gemini accepted a directory where GEMINI.md must be a regular file'
  printf '%s\n' "$out"
  exit 1
fi
expect 'GEMINI.md' "$out" gemini-collision
expect 'not a regular file' "$out" gemini-collision

# A copied package has no repository-level wizard. Its guidance must not point
# at a command the package does not ship.
mkdir -p "$TEST_ROOT/standalone"
for package in codex gemini copilot; do
  cp -R "$REPO/$package" "$TEST_ROOT/standalone/$package"
  out="$(bash "$TEST_ROOT/standalone/$package/scripts/install.macos-linux.sh" "$TEST_ROOT/homes/$package-standalone")"
  expect_outcome "$package-standalone" 'TEMPLATE ONLY' "$out"
  expect 'standalone package has no persona wizard' "$out" "$package-standalone"
  reject 'Run: bash ' "$out" "$package-standalone"
done

echo 'Installer persona outcomes pass.'
