#!/usr/bin/env bash
set -euo pipefail

# Regression coverage for the ADR-0014 repository-contract guard. Structured
# like scripts/test-check-model-tiers.sh: run the production check against the
# real checkout first, then drive fixtures in an isolated temporary tree.
#
# The guard's value is entirely in what it REJECTS, so every case asserts both
# the exit status and a stable fragment of the message. A case that fails for the
# wrong reason is a failure.
#
#   scripts/test-check-repository-contract.sh
#
# PowerShell callers: invoke through bash. There is no .ps1 port, by the same
# argument as check-model-tiers.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/check-repository-contract.sh"

# Validate the actual checkout before any fixture, so CI callers get the real
# signal even if every fixture below were to pass vacuously.
bash "$GUARD"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
cases=0

# A minimal tree that satisfies every property the guard checks — a synthetic
# contract surface rather than a copy of the repository, so a case costs one
# directory copy. Built once; each case gets a pristine copy and mutates exactly
# one thing, so no case can leak state into the next.
BASELINE="$tmp_dir/.baseline"

build_baseline() {
  local root="$1"
  mkdir -p "$root/scripts" "$root/codex" "$root/docs" "$root/adr" \
           "$root/copilot/workspace-template"
  cp "$GUARD" "$root/scripts/check-repository-contract.sh"

  cat > "$root/AGENTS.md" <<'MD'
# AGENTS.md

Contract. See [the architecture doc](docs/architecture.md) and
[ADR-0014](adr/0014-agents-md-is-the-repository-contract.md).
MD

  cat > "$root/CLAUDE.md" <<'MD'
# CLAUDE.md

Adapter for `AGENTS.md`.

@AGENTS.md
MD

  printf '# global codex payload\n' > "$root/codex/AGENTS.md"
  printf '# README\n' > "$root/README.md"
  printf '# CONTRIBUTING\n' > "$root/CONTRIBUTING.md"
  printf '# architecture\n' > "$root/docs/architecture.md"
  printf '# hardening\n' > "$root/docs/hardening.md"
  printf '# ADR index\n\n- [0014](./0014-agents-md-is-the-repository-contract.md)\n' \
    > "$root/adr/README.md"
  printf '# ADR-0014\n' > "$root/adr/0014-agents-md-is-the-repository-contract.md"

  printf '# AGENTS.md\n\nTemplate contract.\n' \
    > "$root/copilot/workspace-template/AGENTS.md"
  printf '# CLAUDE.md\n\nTemplate adapter.\n\n@AGENTS.md\n' \
    > "$root/copilot/workspace-template/CLAUDE.md"
}

build_baseline "$BASELINE"

make_fixture() {
  local root="$1"
  mkdir -p "$root"
  cp -R "$BASELINE/." "$root/"
}

# run_case <name> <expected-exit> <expected-message-fragment|-> <mutator...>
# The mutator receives the fixture root as $1.
run_case() {
  local name="$1" expected_status="$2" expected_fragment="$3"
  shift 3
  local root="$tmp_dir/$name" output status

  cases=$((cases + 1))
  make_fixture "$root"
  "$@" "$root"

  set +e
  output="$(bash "$root/scripts/check-repository-contract.sh" 2>&1)"
  status=$?
  set -e

  if [ "$status" -ne "$expected_status" ]; then
    printf 'FAIL: %s expected exit %s, got %s\n%s\n' \
      "$name" "$expected_status" "$status" "$output" >&2
    failures=$((failures + 1))
    return
  fi
  if [ "$expected_fragment" != "-" ]; then
    case "$output" in
      *"$expected_fragment"*) ;;
      *)
        printf 'FAIL: %s exited %s as expected but did not report "%s"\n%s\n' \
          "$name" "$status" "$expected_fragment" "$output" >&2
        failures=$((failures + 1))
        return
        ;;
    esac
  fi
  # Every case owns its tree; drop it so a later case cannot read it.
  rm -rf "$root"
}

noop() { :; }

# --- 1. the untouched fixture passes ---------------------------------------
run_case baseline 0 'Repository contract intact' noop

# --- 2. a required contract file is missing --------------------------------
run_case missing-root-agents 1 'missing: AGENTS.md' \
  bash -c 'rm "$1/AGENTS.md"' --
run_case missing-codex-payload 1 'missing: codex/AGENTS.md' \
  bash -c 'rm "$1/codex/AGENTS.md"' --
run_case missing-root-pointer 1 'missing pointer: CLAUDE.md' \
  bash -c 'rm "$1/CLAUDE.md"' --

# --- 3. the import is absent, or present but inert -------------------------
run_case import-absent 1 "no active bare '@AGENTS.md' import" \
  bash -c 'printf "# CLAUDE.md\n\nNo import here.\n" > "$1/CLAUDE.md"' --
run_case import-backticked 1 "no active bare '@AGENTS.md' import" \
  bash -c 'printf "# CLAUDE.md\n\nSee \`@AGENTS.md\`.\n" > "$1/CLAUDE.md"' --
run_case import-fenced 1 "no active bare '@AGENTS.md' import" \
  bash -c 'printf "# CLAUDE.md\n\n\`\`\`\n@AGENTS.md\n\`\`\`\n" > "$1/CLAUDE.md"' --
run_case import-commented 1 "no active bare '@AGENTS.md' import" \
  bash -c 'printf "# CLAUDE.md\n\n<!--\n@AGENTS.md\n-->\n" > "$1/CLAUDE.md"' --
# The import target is the pair's own contract file, so a missing target is
# reported as a missing contract. This case pins that coverage down.
run_case import-target-missing 1 'missing contract: copilot/workspace-template/AGENTS.md' \
  bash -c 'rm "$1/copilot/workspace-template/AGENTS.md"' --

# A large pointer used to fail: `active_content | grep -q` let grep exit on the
# first match, the producer took SIGPIPE, and `set -o pipefail` reported 141,
# which read as "no import". Anything past a pipe buffer reproduces it.
run_case import-in-large-pointer 0 'Repository contract intact' \
  bash -c 'awk "BEGIN{for(i=0;i<5000;i++) print \"filler line \" i \" with enough text to exceed a pipe buffer\"}" >> "$1/CLAUDE.md"' --

# --- 3b. malformed parser state fails instead of hiding the remainder -------
run_case unclosed-html-comment 1 'ends inside an unclosed HTML comment' \
  bash -c 'printf "\n<!--\nnote\n[hidden](nope.md)\n" >> "$1/AGENTS.md"' --
run_case unclosed-fence 1 'ends inside an unclosed fenced code block' \
  bash -c 'printf "\n\`\`\`\n[hidden](nope.md)\n" >> "$1/AGENTS.md"' --
# A fence marker inside a comment must not toggle fence state, and a comment
# opener inside a fence must not open a comment. Either confusion would leave
# the file "unclosed" and now fails loudly, so a pass proves both.
run_case fence-marker-inside-comment 0 'Repository contract intact' \
  bash -c 'printf "\n<!--\n\`\`\`\n-->\n[arch](docs/architecture.md)\n" >> "$1/AGENTS.md"' --
run_case comment-marker-inside-fence 0 'Repository contract intact' \
  bash -c 'printf "\n\`\`\`\n<!--\n\`\`\`\n[arch](docs/architecture.md)\n" >> "$1/AGENTS.md"' --

# --- 3c. CRLF is the normal worktree state for tracked Markdown here -------
run_case crlf-input-valid 0 'Repository contract intact' \
  bash -c 'printf "# CLAUDE.md\r\n\r\nAdapter.\r\n\r\n@AGENTS.md\r\n" > "$1/CLAUDE.md"; printf "# AGENTS.md\r\n\r\n[arch](docs/architecture.md)\r\n" > "$1/AGENTS.md"' --
run_case crlf-input-broken-link 1 "broken relative link 'docs/nope.md'" \
  bash -c 'printf "# AGENTS.md\r\n\r\n[nope](docs/nope.md)\r\n" > "$1/AGENTS.md"' --

# --- 4. a real broken local link fails -------------------------------------
run_case broken-link 1 "broken relative link 'docs/gone.md'" \
  bash -c 'printf "\n- [gone](docs/gone.md)\n" >> "$1/AGENTS.md"' --
run_case broken-link-in-adr-index 1 "broken relative link './0099-nope.md'" \
  bash -c 'printf "\n- [0099](./0099-nope.md)\n" >> "$1/adr/README.md"' --

# --- 5/6. broken links inside code spans and fences are not links ----------
run_case broken-link-inline-code 0 'Repository contract intact' \
  bash -c 'printf "\nThe index row shape is \`- [Title](file.md)\`.\n" >> "$1/AGENTS.md"' --
run_case broken-link-fenced 0 'Repository contract intact' \
  bash -c 'printf "\n\`\`\`markdown\n- [Title](does-not-exist.md)\n\`\`\`\n" >> "$1/AGENTS.md"' --
run_case broken-link-tilde-fenced 0 'Repository contract intact' \
  bash -c 'printf "\n~~~\n[Title](does-not-exist.md)\n~~~\n" >> "$1/AGENTS.md"' --
run_case broken-link-html-comment 0 'Repository contract intact' \
  bash -c 'printf "\n<!-- draft: [Title](does-not-exist.md) -->\n" >> "$1/AGENTS.md"' --
# The multi-line case is the one a per-line filter gets wrong.
run_case broken-link-multiline-comment 0 'Repository contract intact' \
  bash -c 'printf "\n<!--\nDraft note.\n[Title](does-not-exist.md)\n-->\n" >> "$1/AGENTS.md"' --
# Each ignore case above needs its mirror: state has to RESET, or a fixture
# passes because the link was never seen rather than because it resolved.
run_case link-after-multiline-comment 1 "broken relative link 'after.md'" \
  bash -c 'printf "\n<!--\nnote\n-->\n[after](after.md)\n" >> "$1/AGENTS.md"' --
run_case link-after-closed-fence 1 "broken relative link 'after.md'" \
  bash -c 'printf "\n\`\`\`\n[ignored](nope.md)\n\`\`\`\n[after](after.md)\n" >> "$1/AGENTS.md"' --
run_case link-after-closed-tilde-fence 1 "broken relative link 'after.md'" \
  bash -c 'printf "\n~~~\n[ignored](nope.md)\n~~~\n[after](after.md)\n" >> "$1/AGENTS.md"' --
run_case link-after-code-span-same-line 1 "broken relative link 'after.md'" \
  bash -c 'printf "\nShape \`- [x](nope.md)\` then [after](after.md).\n" >> "$1/AGENTS.md"' --

# --- 7. external, mailto, and anchor-only destinations are skipped ---------
run_case external-and-anchor-links 0 'Repository contract intact' \
  bash -c 'printf "\n[a](https://example.com/x) [b](http://example.com) [c](mailto:x@example.com) [d](#a-heading)\n" >> "$1/AGENTS.md"' --

# --- 7b. documented destination policies ----------------------------------
# An image link is the same `](` shape, so a broken image path is a broken path.
run_case image-link-valid 0 'Repository contract intact' \
  bash -c 'printf "\n![arch](docs/architecture.md)\n" >> "$1/AGENTS.md"' --
run_case image-link-broken 1 "broken relative link 'img/missing.png'" \
  bash -c 'printf "\n![logo](img/missing.png)\n" >> "$1/AGENTS.md"' --
# A query string is not stripped: on a repository-local path it is a mistake,
# and the guard says so rather than resolving a path nobody wrote.
run_case query-string-on-local-path 1 "broken relative link 'docs/architecture.md?v=1'" \
  bash -c 'printf "\n[q](docs/architecture.md?v=1)\n" >> "$1/AGENTS.md"' --
# `../` has to resolve against the document's own directory, not the repo root.
run_case parent-relative-path-valid 0 'Repository contract intact' \
  bash -c 'printf "\n[up](../AGENTS.md)\n" >> "$1/adr/README.md"' --
run_case parent-relative-path-broken 1 "broken relative link '../nope.md'" \
  bash -c 'printf "\n[up](../nope.md)\n" >> "$1/adr/README.md"' --

# --- 8. a fragment on a local path resolves against the path ---------------
run_case fragment-on-valid-path 0 'Repository contract intact' \
  bash -c 'printf "\n[arch](docs/architecture.md#the-layers)\n" >> "$1/AGENTS.md"' --
run_case fragment-on-missing-path 1 "broken relative link 'docs/nope.md'" \
  bash -c 'printf "\n[nope](docs/nope.md#anything)\n" >> "$1/AGENTS.md"' --

# --- 9. the workspace template pair is checked too ------------------------
run_case template-pointer-missing 1 'missing pointer: copilot/workspace-template/CLAUDE.md' \
  bash -c 'rm "$1/copilot/workspace-template/CLAUDE.md"' --
run_case template-import-inert 1 "copilot/workspace-template/CLAUDE.md has no active bare" \
  bash -c 'printf "# CLAUDE.md\n\nSee \`@AGENTS.md\`.\n" > "$1/copilot/workspace-template/CLAUDE.md"' --

# --- the documented subset: titles and angle brackets are supported -------
run_case link-with-title 0 'Repository contract intact' \
  bash -c 'printf "\n[arch](docs/architecture.md \"The architecture\")\n" >> "$1/AGENTS.md"' --
run_case link-with-title-broken 1 "broken relative link 'docs/nope.md'" \
  bash -c 'printf "\n[nope](docs/nope.md \"Title\")\n" >> "$1/AGENTS.md"' --
run_case angle-bracket-destination 0 'Repository contract intact' \
  bash -c 'printf "\n[arch](<docs/architecture.md>)\n" >> "$1/AGENTS.md"' --
run_case angle-bracket-destination-broken 1 "broken relative link 'docs/nope.md'" \
  bash -c 'printf "\n[nope](<docs/nope.md>)\n" >> "$1/AGENTS.md"' --

# --- outside the subset: reported, never silently skipped ------------------
run_case unsupported-paren-in-destination 1 'unsupported link syntax' \
  bash -c 'printf "\n[x](docs/a(b).md)\n" >> "$1/AGENTS.md"' --
# A link wrapped across two lines is legal CommonMark that this subset does not
# resolve. It must be reported, never silently skipped.
# The message has to tell the author what to do, not just that it failed.
run_case unsupported-wrapped-link 1 'keep local documentation links on one line' \
  bash -c 'printf "\n[x](docs/\narchitecture.md)\n" >> "$1/AGENTS.md"' --

if [ "$failures" -ne 0 ]; then
  echo "check-repository-contract: $failures case(s) failed" >&2
  exit 1
fi

echo "check-repository-contract: production checkout plus $cases fixture cases pass."
