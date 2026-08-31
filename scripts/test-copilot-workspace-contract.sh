#!/usr/bin/env bash
set -euo pipefail

# The Copilot installer is the only thing that writes a repository contract into
# someone else's repository (ADR-0014), and `AGENTS.md` + `CLAUDE.md` ship as a
# pair: `AGENTS.md` alone leaves a seeded repo with nothing for Claude Code.
# A target repo's AGENTS.md may already be a team's committed file, so the
# collision behaviour matters more here than anywhere else the kit copies files.
#
# This pins the properties down for the Bash port. The PowerShell port is
# asserted by the `install-copilot-contract` check in scripts/test-windows.ps1,
# against the same list, because a shell test cannot exercise a .ps1.
#
# The installer's collision policy is the pre-existing `copy_with_backup`
# convention, unchanged by ADR-0014: an existing destination is MOVED to
# `<dest>.pre-copilot-config.<timestamp>` (gitignored) and the move is reported
# on stdout before the new file lands. Nothing is deleted and nothing is
# overwritten silently. There is deliberately no abort-on-conflict or force mode:
# adding one would be a new installer convention, and the backup already means a
# conflict cannot lose data.
#
#   scripts/test-copilot-workspace-contract.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Only the package surface the installer needs. The generated persona is
# gitignored and deliberately excluded, so a local run cannot read or overwrite
# the developer's real profile and starts from the same state as a fresh clone.
REPO="$TEST_ROOT/repo"
mkdir -p "$REPO"
cp -R "$SOURCE_ROOT/copilot" "$REPO/copilot"
INSTALLER="$REPO/copilot/scripts/install.macos-linux.sh"
TEMPLATE="$REPO/copilot/workspace-template"

failures=0
cases=0

report() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

# Every case runs under a directory with a space in it: the installers quote
# their paths, and this is where an unquoted expansion would surface.
new_workspace() {
  local name="$1"
  local ws
  ws="$TEST_ROOT/case $cases $name"
  mkdir -p "$ws"
  printf '%s' "$ws"
}

run_installer() {
  local ws="$1"
  local home out
  home="$ws/.fakehome"
  mkdir -p "$home"
  if ! out="$(bash "$INSTALLER" "$home" "$ws" 2>&1)"; then
    printf '%s\n' "$out" >&2
    return 1
  fi
  printf '%s' "$out"
}

# The pair invariant: after any run, BOTH files exist and both match the
# template. A half-delivered pair is the failure mode ADR-0014 introduced the
# risk of, so it is asserted after every case rather than in one of them.
assert_pair_intact() {
  local ws="$1" label="$2" name
  for name in AGENTS.md CLAUDE.md; do
    if [ ! -f "$ws/$name" ]; then
      report "$label: $ws/$name was not delivered"
      return
    fi
    if ! cmp -s "$TEMPLATE/$name" "$ws/$name"; then
      report "$label: $ws/$name does not match the shipped template"
      return
    fi
  done
  if ! grep -qx '@AGENTS.md' "$ws/CLAUDE.md"; then
    report "$label: delivered CLAUDE.md has no bare @AGENTS.md import"
  fi
}

# find rather than a glob: the workspace path holds a space, and `ls` on a
# non-matching glob exits nonzero, which `set -o pipefail` would turn into an
# abort instead of a count of zero.
backup_count() {
  find "$(dirname "$1")" -maxdepth 1 -name "$(basename "$1").pre-copilot-config.*" \
    | wc -l | tr -d ' '
}

# --- 1. empty target: both files are created --------------------------------
cases=$((cases + 1))
ws="$(new_workspace empty)"
out="$(run_installer "$ws")" || report "empty target: installer exited nonzero"
assert_pair_intact "$ws" 'empty target'
for name in AGENTS.md CLAUDE.md; do
  case "$out" in
    *"Copied $ws/$name"*) ;;
    *) report "empty target: installer did not report copying $name" ;;
  esac
done
case "$out" in
  *'Backed up'*) report 'empty target: installer backed something up in an empty workspace' ;;
esac

# --- 2. re-run over identical files: content-idempotent, one backup each ----
cases=$((cases + 1))
out="$(run_installer "$ws")" || report 'rerun: installer exited nonzero'
assert_pair_intact "$ws" 'rerun'
for name in AGENTS.md CLAUDE.md; do
  n="$(backup_count "$ws/$name")"
  [ "$n" = "1" ] || report "rerun: expected 1 backup of $name, found $n"
  case "$out" in
    *"Backed up $ws/$name"*) ;;
    *) report "rerun: installer did not report backing up $name" ;;
  esac
done

# --- 3/4/5. collisions: the existing file survives in a backup --------------
# One case per shape: only AGENTS.md present, only CLAUDE.md present, both
# present with different content. In every one the pair must end up intact and
# the prior content must be recoverable.
for shape in agents-only claude-only both; do
  cases=$((cases + 1))
  ws="$(new_workspace "$shape")"
  case "$shape" in
    agents-only) present='AGENTS.md' ;;
    claude-only) present='CLAUDE.md' ;;
    both)        present='AGENTS.md CLAUDE.md' ;;
  esac
  for name in $present; do
    printf '# team-authored %s\nDo not lose this line.\n' "$name" > "$ws/$name"
  done

  out="$(run_installer "$ws")" || report "$shape: installer exited nonzero"
  assert_pair_intact "$ws" "$shape"

  for name in AGENTS.md CLAUDE.md; do
    n="$(backup_count "$ws/$name")"
    case " $present " in
      *" $name "*)
        [ "$n" = "1" ] || report "$shape: expected 1 backup of $name, found $n"
        if ! grep -q 'Do not lose this line.' "$ws/$name".pre-copilot-config.* 2>/dev/null; then
          report "$shape: the pre-existing $name content is not in its backup"
        fi
        case "$out" in
          *"Backed up $ws/$name"*) ;;
          *) report "$shape: the replacement of $name was not reported" ;;
        esac
        ;;
      *)
        [ "$n" = "0" ] || report "$shape: backed up $name that did not exist"
        ;;
    esac
  done
done

# --- 6. what lands is safe to load immediately ------------------------------
# The template ships `<placeholder>` markers on purpose. Two things must hold in
# a target repo: no wizard `{{MARKER}}` leaks in, and the Commands table still
# holds placeholders rather than commands somebody invented during discovery.
cases=$((cases + 1))
ws="$(new_workspace placeholders)"
run_installer "$ws" >/dev/null || report 'placeholders: installer exited nonzero'
if grep -q '{{' "$ws/AGENTS.md" "$ws/CLAUDE.md"; then
  report 'placeholders: a wizard {{MARKER}} reached the target repository'
fi
if ! grep -q '`<command>`' "$ws/AGENTS.md"; then
  report 'placeholders: the Commands table no longer ships unresolved placeholders'
fi

if [ "$failures" -ne 0 ]; then
  echo "copilot workspace contract: $failures assertion(s) failed across $cases case(s)" >&2
  exit 1
fi

echo "Copilot workspace contract: $cases case(s) pass (pair delivery, collisions, backups, placeholders)."
