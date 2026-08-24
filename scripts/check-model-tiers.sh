#!/usr/bin/env bash
set -euo pipefail

# ADR-0012 guard: every committed model field names a TIER ALIAS, never a
# version slug. One script, both CI jobs — the Linux `verify` job runs it
# directly and the Windows suite shells out to it, because the previous
# arrangement (a grep in ci.yml plus a hand-written PowerShell port of the same
# grep) had already drifted: both only ever matched YAML.
#
# Fields are found per format rather than by one line pattern:
#   *.md            frontmatter only  -> `model: <tier>`
#   *.yml *.yaml    any depth         -> `model: <tier>`
#   *.json          real parse (jq)   -> any "model" key, at any depth
#   *.toml          any table         -> `model = "<tier>"`
#
# Markdown prose is deliberately out of scope: a `model:` line in a fenced
# example is documentation, not committed config. Only frontmatter configures
# anything.
#
# TRADEOFF(ceiling: JSON is really parsed, but YAML and TOML are scanned
#   line-wise, so a model field nested under a block scalar or written in TOML's
#   inline-table form is missed; upgrade: python3 tomllib for TOML and a YAML
#   parser dependency for YAML, once a committed config needs either shape):
#   the kit's own configs are flat, and adding a YAML dependency to buy coverage
#   for a shape nothing here uses is the trade this repo argues against.
#
#   scripts/check-model-tiers.sh        # exits 1 and lists every offender
#
# PowerShell callers: invoke through bash (the Windows suite already does this
# for the hooks). There is deliberately no .ps1 port — a second copy is what
# broke this guard the first time.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Tier aliases from ADR-0012, plus `inherit`, which names "take the session's
# model" rather than a tier.
ALLOWED_RE='^(opus|sonnet|haiku|inherit)$'

bad=0

report() {
  printf '%s:%s: model field is %s, not a tier alias\n' "$1" "$2" "${3:-<empty>}" >&2
  bad=1
}

check_value() {
  local file="$1" line="$2" value="$3"
  # Strip surrounding quotes and inline comments the scanners leave behind.
  value="${value%%#*}"
  value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
  [ -n "$value" ] || { report "$file" "$line" ''; return; }
  printf '%s' "$value" | grep -Eq "$ALLOWED_RE" || report "$file" "$line" "$value"
}

# --- markdown: frontmatter only ---------------------------------------------
scan_frontmatter() {
  local file="$1"
  # awk prints "<line>\t<value>" for a model key inside the leading --- block.
  while IFS=$'\t' read -r line value; do
    [ -n "$line" ] || continue
    check_value "$file" "$line" "$value"
  done < <(awk '
    NR == 1 && $0 !~ /^---[[:space:]]*$/ { exit }
    /^---[[:space:]]*$/ { fence++; if (fence == 2) exit; next }
    fence == 1 && /^[[:space:]]*model[[:space:]]*:/ {
      value = $0
      sub(/^[[:space:]]*model[[:space:]]*:[[:space:]]*/, "", value)
      print NR "\t" value
    }
  ' "$file")
}

# --- yaml: any depth --------------------------------------------------------
scan_yaml() {
  local file="$1"
  while IFS=$'\t' read -r line value; do
    [ -n "$line" ] || continue
    check_value "$file" "$line" "$value"
  done < <(awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*-?[[:space:]]*model[[:space:]]*:/ {
      value = $0
      sub(/^[[:space:]]*-?[[:space:]]*model[[:space:]]*:[[:space:]]*/, "", value)
      print NR "\t" value
    }
  ' "$file")
}

# --- toml: any table --------------------------------------------------------
scan_toml() {
  local file="$1"
  while IFS=$'\t' read -r line value; do
    [ -n "$line" ] || continue
    check_value "$file" "$line" "$value"
  done < <(awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*model[[:space:]]*=/ {
      value = $0
      sub(/^[[:space:]]*model[[:space:]]*=[[:space:]]*/, "", value)
      print NR "\t" value
    }
  ' "$file")
}

# --- json: real parse -------------------------------------------------------
scan_json() {
  local file="$1" values
  if ! command -v jq >/dev/null 2>&1; then
    echo "check-model-tiers: jq is required to parse $file" >&2
    bad=1
    return
  fi
  # Keys only: a "model" string appearing inside a hook command is a value and
  # configures nothing. Capture jq's status before iterating: a process
  # substitution would let a parse failure disappear behind the while loop's
  # successful exit status.
  if ! values="$(jq -r '
    .. | objects | to_entries[] | select(.key == "model") |
    if (.value | type) == "string" then .value
    else error("model field must be a string")
    end
  ' "$file")"; then
    echo "check-model-tiers: failed to parse or validate $file" >&2
    bad=1
    return
  fi
  while IFS= read -r value; do
    [ -n "$value" ] || continue
    check_value "$file" '?' "$value"
  done <<< "$values"
}

while IFS= read -r file; do
  [ -f "$file" ] || continue
  case "$file" in
    *.md)          scan_frontmatter "$file" ;;
    *.yml|*.yaml)  scan_yaml "$file" ;;
    *.toml)        scan_toml "$file" ;;
    *.json)        scan_json "$file" ;;
  esac
done < <(git ls-files)

if [ "$bad" -ne 0 ]; then
  echo "A committed model field must name a tier alias (opus/sonnet/haiku/inherit)," >&2
  echo "not a version slug. See adr/0012-tier-labels-over-pinned-model-slugs.md." >&2
  exit 1
fi

echo "Model fields name tier aliases (md frontmatter, yaml, toml, json)."
