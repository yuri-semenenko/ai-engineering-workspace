#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-loops.sh"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

make_fixture() {
  local name="$1"
  local fixture="$tmp_root/$name"
  mkdir -p "$fixture/claude-code/.claude/skills"
  cp -R "$REPO_ROOT/loops" "$fixture/loops"
  for skill in codebase-map pr-classify testing-checklist security-pass pr-recheck complexity-audit debt-ledger; do
    mkdir -p "$fixture/claude-code/.claude/skills/$skill"
    : > "$fixture/claude-code/.claude/skills/$skill/SKILL.md"
  done
  printf '%s\n' "$fixture"
}

success="$(make_fixture success)"
bash "$VALIDATOR" --root "$success"

unsupported="$(make_fixture unsupported)"
sed -i 's/L1 — Report Only/L2 — Assisted Action/' "$unsupported/loops/pr-review/LOOP.md"
if bash "$VALIDATOR" --root "$unsupported"; then
  echo "Expected unsupported L2 fixture to fail" >&2
  exit 1
fi

no_prohibition="$(make_fixture no-prohibition)"
sed -i 's/### Prohibited write and outbound actions/### Actions/' "$no_prohibition/loops/pr-review/LOOP.md"
if bash "$VALIDATOR" --root "$no_prohibition"; then
  echo "Expected L1 fixture without write prohibition to fail" >&2
  exit 1
fi

unknown_skill="$(make_fixture unknown-skill)"
sed -i 's#skills/codebase-map/SKILL.md#skills/unknown-skill/SKILL.md#' "$unknown_skill/loops/pr-review/LOOP.md"
if bash "$VALIDATOR" --root "$unknown_skill"; then
  echo "Expected unknown skill fixture to fail" >&2
  exit 1
fi

echo "loop validation fixtures: expected pass and failures observed"
