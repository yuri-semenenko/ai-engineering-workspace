#!/usr/bin/env bash
set -euo pipefail

# Regression coverage for the public model-tier guard. Each case runs from a
# fresh temporary Git repository so only the fixture under test is scanned.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v jq >/dev/null 2>&1; then
  echo "test-check-model-tiers: jq is required; runtime test unavailable" >&2
  exit 2
fi

# Keep the production check in the test entrypoint: CI callers validate the
# actual checkout before the isolated regression fixtures below.
bash "$SCRIPT_DIR/check-model-tiers.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_case() {
  local name="$1" json="$2" expected_status="$3"
  local repo="$tmp_dir/$name" output status

  mkdir -p "$repo/scripts" "$repo/config"
  cp "$SCRIPT_DIR/check-model-tiers.sh" "$repo/scripts/check-model-tiers.sh"
  printf '%s\n' "$json" > "$repo/config/settings.json"
  git -C "$repo" init -q
  git -C "$repo" add config/settings.json scripts/check-model-tiers.sh

  set +e
  output="$(bash "$repo/scripts/check-model-tiers.sh" 2>&1)"
  status=$?
  set -e

  if [ "$status" -ne "$expected_status" ]; then
    printf 'FAIL: %s expected exit %s, got %s\n%s\n' \
      "$name" "$expected_status" "$status" "$output" >&2
    return 1
  fi
}

run_case valid-alias '{"model":"haiku"}' 0
run_case malformed-json '{"model":"haiku"' 1
run_case object-valued-model '{"model":{"name":"haiku"}}' 1

echo "check-model-tiers regression cases pass."
