#!/usr/bin/env bash
set -euo pipefail

# ADR-0014 guard: the repository contract surface stays wired up.
#
# Root AGENTS.md is this repository's contract. Claude Code does not read
# AGENTS.md, so a CLAUDE.md beside it must IMPORT it with an active `@AGENTS.md`
# line rather than restate the rules. The same pairing ships in the Copilot
# workspace template, which seeds another repository's contract.
#
# Three structural properties, and nothing semantic. Whether a CLAUDE.md has
# quietly grown into a second contract cannot be proved by a shell script; that
# boundary is documented in AGENTS.md and ADR-0014 instead.
#
#   1. Every contract file, its CLAUDE.md pointer, and the global Codex payload
#      exist.
#   2. Each pointer carries an ACTIVE bare `@AGENTS.md` line, and its target
#      exists. Backticked, fenced, or commented-out text does not count: Claude
#      Code's import parser skips code spans and fenced blocks, so a pointer that
#      only mentions the path is inert.
#   3. Relative links resolve, across the documents that FORM or EXPLAIN the
#      contract (listed in CONTRACT_DOCS). This is deliberately not a
#      repository-wide Markdown linter: an unrelated ADR with a stale link is not
#      a contract defect, so only adr/README.md (the index, which must resolve to
#      every record) and ADR-0014 itself are in scope.
#
# SUPPORTED MARKDOWN SUBSET, chosen to cover this repository's actual style:
#   - inline links `[text](dest)` and `[text](dest "Title")`
#   - image links `![alt](dest)`, validated exactly like a link: the `](` shape
#     is identical and a broken image path is a broken path
#   - angle-bracket destinations `[text](<dest with spaces>)`
#   - relative paths, including `../`
#   - http:, https:, mailto:, and anchor-only (`#frag`) destinations are skipped
#   - a trailing `#fragment` is stripped before the path check; the fragment
#     itself is not resolved
#   - a query string is NOT stripped: `docs/x.md?v=1` is checked as that literal
#     path and reported broken. A query on a repository-local path is a mistake,
#     and failing is the point.
# IGNORED CONSTRUCTS (parsed, not guessed at):
#   - fenced code blocks, ``` and ~~~
#   - single-backtick inline code spans
#   - HTML comments, including multi-line ones
#   - CRLF input, which is the normal worktree state for tracked Markdown here
# MALFORMED STATE fails rather than hiding content: an unclosed fence or HTML
# comment at EOF would silently swallow the rest of the document, so the parser
# stops with an actionable message instead.
# OUT OF SCOPE, and reported rather than silently skipped:
#   - a destination containing an unescaped `(` or `)`
#   - an inline link wrapped across two lines, so `](` and `)` are on different
#     lines. Legal CommonMark, absent from this repository, and reported loudly
#     rather than skipped: a silent skip is how a broken link survives a guard.
#   - reference-style links `[text][label]`, which this repository does not use
#     and which this guard does not see at all
#   - backslash-escaped `\]` or `\(`, which this repository does not use
#
# Regression coverage: scripts/test-check-repository-contract.sh
#
#   scripts/check-repository-contract.sh
#
# PowerShell callers: invoke through bash, as scripts/test-windows.ps1 already
# does for the hooks and the model-tier guard. There is deliberately no .ps1
# port — a hand-written second copy is what let the model-tier guard drift.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bad=0

fail() {
  printf 'CONTRACT: %s\n' "$1" >&2
  bad=1
}

# --- the parsed subset ------------------------------------------------------
# Emits the active content of a Markdown file: fenced blocks dropped, HTML
# comments (single- and multi-line) removed, inline code spans blanked.
active_content() {
  awk '
    # A comment can open on one line and close on a later one, so the flag has
    # to survive across records. Returns the text outside every comment.
    function strip_comments(s,   out, i) {
      out = ""
      while (length(s) > 0) {
        if (in_comment) {
          i = index(s, "-->")
          if (i == 0) return out
          s = substr(s, i + 3)
          in_comment = 0
        } else {
          i = index(s, "<!--")
          if (i == 0) return out s
          out = out substr(s, 1, i - 1)
          s = substr(s, i + 4)
          in_comment = 1
        }
      }
      return out
    }

    # A fence delimiter inside a comment is text, not a fence. A comment opener
    # inside a fence is text too: `fence { next }` skips the line before
    # strip_comments can see it, so in_comment never changes there.
    !in_comment && /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      line = strip_comments($0)
      gsub(/`[^`]*`/, "", line)
      print line
    }

    # Unclosed state would silently hide every line after it, which is how a
    # broken link survives a guard. Fail instead.
    END {
      if (in_comment) {
        printf "CONTRACT: %s ends inside an unclosed HTML comment; close it with --> so the rest of the file is parsed.\n", FILENAME > "/dev/stderr"
        exit 3
      }
      if (fence) {
        printf "CONTRACT: %s ends inside an unclosed fenced code block; close the fence so the rest of the file is parsed.\n", FILENAME > "/dev/stderr"
        exit 3
      }
    }
  ' "$1"
}

# Emits one line per inline-link destination found in active content:
#   DEST<TAB><destination>    a destination this guard resolves
#   UNSUP<TAB><raw>           a shape outside the supported subset
link_destinations() {
  active_content "$1" | awk '
    {
      s = $0
      while (match(s, /\]\(/)) {
        s = substr(s, RSTART + RLENGTH)
        close_paren = index(s, ")")
        if (close_paren == 0) {
          print "UNSUP\tlink wrapped across lines near \"" substr(s, 1, 40) "\"; keep local documentation links on one line"
          break
        }
        inner = substr(s, 1, close_paren - 1)
        s = substr(s, close_paren + 1)

        # `[text](<dest with spaces> "Title")`
        if (substr(inner, 1, 1) == "<") {
          gt = index(inner, ">")
          if (gt == 0) { print "UNSUP\tunterminated <> destination: " inner; continue }
          dest = substr(inner, 2, gt - 2)
        } else {
          # CommonMark shape is `dest` optionally followed by a title, so the
          # first whitespace-delimited token is the destination.
          split(inner, parts, /[[:space:]]+/)
          dest = parts[1]
        }

        if (dest ~ /\(/) { print "UNSUP\tparenthesis in destination: " inner; continue }
        if (length(dest) == 0) continue
        print "DEST\t" dest
      }
    }
  '
}

# --- 1. required files ------------------------------------------------------
# Every AGENTS.md the documentation claims exists, each with the audience that
# makes it distinct. Losing one silently makes the layer model a lie.
for required in AGENTS.md CLAUDE.md codex/AGENTS.md; do
  [ -f "$required" ] || fail "missing: $required"
done

# --- 2. contract/pointer pairs ---------------------------------------------
CONTRACT_PAIRS="AGENTS.md|CLAUDE.md
copilot/workspace-template/AGENTS.md|copilot/workspace-template/CLAUDE.md"

while IFS='|' read -r contract pointer; do
  [ -n "$contract" ] || continue
  if [ ! -f "$contract" ]; then
    fail "missing contract: $contract"
    continue
  fi
  if [ ! -f "$pointer" ]; then
    fail "missing pointer: $pointer (Claude Code does not read AGENTS.md)"
    continue
  fi
  # Capture, then match with a here-string rather than piping into `grep -q`.
  # `grep -q` exits on the first match, the producer takes SIGPIPE, and under
  # `set -o pipefail` the pipeline reports 141 — which read as "no import" and
  # failed a valid pointer once the file grew past a pipe buffer.
  if ! pointer_content="$(active_content "$pointer")"; then
    fail "$pointer could not be parsed (see the message above)"
    continue
  fi
  if ! grep -Eq '^[[:space:]]*@AGENTS\.md[[:space:]]*$' <<< "$pointer_content"; then
    fail "$pointer has no active bare '@AGENTS.md' import (a backticked, fenced, or commented mention is inert)"
  fi
  # No separate "does the import target exist" check: `@AGENTS.md` resolves
  # relative to the file holding it, and every pair here puts the pointer beside
  # its contract, so the target is $contract, already checked above.
done <<EOF
$CONTRACT_PAIRS
EOF

# --- 3. relative links across the contract surface -------------------------
# Documents that form or explain the contract. Not every markdown file in the
# repository, and not every ADR: see the scope note in the header.
CONTRACT_DOCS="AGENTS.md
CLAUDE.md
README.md
CONTRIBUTING.md
docs/architecture.md
docs/hardening.md
adr/README.md
adr/0014-agents-md-is-the-repository-contract.md"

check_links() {
  local doc="$1"
  local dir kind target dests
  if [ ! -f "$doc" ]; then
    fail "missing contract document: $doc"
    return
  fi
  dir="$(dirname "$doc")"
  # Command substitution, not process substitution: a parse failure inside
  # link_destinations must reach this shell rather than vanish.
  if ! dests="$(link_destinations "$doc")"; then
    fail "$doc could not be parsed (see the message above)"
    return
  fi
  # `return 0` explicitly: a bare `return` inherits the failing status of the
  # test above it, and under `set -e` that aborts the caller's loop.
  if [ -z "$dests" ]; then
    return 0
  fi
  while IFS=$'\t' read -r kind target; do
    [ -n "$kind" ] || continue
    if [ "$kind" = "UNSUP" ]; then
      fail "unsupported link syntax in $doc: $target"
      continue
    fi
    case "$target" in
      http:*|https:*|mailto:*|\#*) continue ;;
    esac
    target="${target%%#*}"
    [ -n "$target" ] || continue
    if [ ! -e "$dir/$target" ]; then
      fail "broken relative link '$target' in $doc"
    fi
  done <<< "$dests"
}

for doc in $CONTRACT_DOCS; do
  check_links "$doc"
done

if [ "$bad" -ne 0 ]; then
  echo "See adr/0014-agents-md-is-the-repository-contract.md." >&2
  exit 1
fi

echo "Repository contract intact: AGENTS.md pairs, active @AGENTS.md imports, and relative links across the contract surface."
