#!/usr/bin/env bash
set -euo pipefail

# Generate your own persona.md + CLAUDE.md from the shared templates.
#
# The methodology (simplicity ladder, RFC/ADR format, PR-review tiers, git
# rules, verification criterion, ...) is fixed canon and applies to everyone.
# This wizard only asks about the identity header: discipline, seniority,
# workflow, stack, and tooling. These shape the output beyond text substitution:
#   - seniority  -> the "Seniority Model" section (how to treat you)
#   - discipline -> background framing + the recommended-skills list
#   - workflow   -> which skills recommended-skills.md foregrounds, plus a
#                   user-facing interaction-emphasis line in that view
# The methodology canon and the persona files do not change with any of them;
# workflow fills no template placeholder and touches only the generated view.
#
# Output (all gitignored, they are YOUR files, not the repo's):
#   persona/persona.md            full persona
#   persona/CLAUDE.md              condensed, for ~/.claude/CLAUDE.md
#   persona/recommended-skills.md  which shipped skills to reach for first
#
#   scripts/create-persona.sh              interactive
#   scripts/create-persona.sh --defaults    accept every default, no prompts (CI)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERSONA_DIR="$REPO_ROOT/persona"
PERSONA_TEMPLATE="$PERSONA_DIR/persona.template.md"
CLAUDE_TEMPLATE="$PERSONA_DIR/CLAUDE.template.md"
SKILLS_DIR="$REPO_ROOT/claude-code/.claude/skills"

USE_DEFAULTS=0
if [ "${1:-}" = "--defaults" ] || [ ! -t 0 ]; then
  USE_DEFAULTS=1
fi

for f in "$PERSONA_TEMPLATE" "$CLAUDE_TEMPLATE"; do
  [ -f "$f" ] || { echo "Template not found: $f" >&2; exit 1; }
done

# ask VAR "Prompt" "default"  -> sets global $VAR (env override or prompt or default)
ask() {
  local __var="$1" __prompt="$2" __default="$3" __env="${!1:-}" __reply
  if [ -n "$__env" ]; then
    printf -v "$__var" '%s' "$__env"; return
  fi
  if [ "$USE_DEFAULTS" -eq 1 ]; then
    printf -v "$__var" '%s' "$__default"; return
  fi
  read -r -p "$__prompt [$__default]: " __reply || __reply=""
  printf -v "$__var" '%s' "${__reply:-$__default}"
}

echo "Creating your persona. Press Enter to accept each default."
echo

# --- Axes that shape the persona beyond plain substitution -------------------
ask DISCIPLINE "Discipline (frontend/fullstack)"        "fullstack"
ask SENIORITY  "Seniority (mid/senior/staff/principal)" "staff"
ask WORKFLOW   "Workflow (delivery-focused/architecture-focused/review-focused/learning-focused)" "architecture-focused"

DISCIPLINE="$(printf '%s' "$DISCIPLINE" | tr '[:upper:]' '[:lower:]')"
SENIORITY="$(printf '%s' "$SENIORITY" | tr '[:upper:]' '[:lower:]')"
WORKFLOW="$(printf '%s' "$WORKFLOW" | tr '[:upper:]' '[:lower:]')"

case "$DISCIPLINE" in
  frontend|fullstack) ;;
  *) echo "Unknown discipline: '$DISCIPLINE' (expected frontend|fullstack)" >&2; exit 1;;
esac
case "$SENIORITY" in
  mid|senior|staff|principal) ;;
  *) echo "Unknown seniority: '$SENIORITY' (expected mid|senior|staff|principal)" >&2; exit 1;;
esac
case "$WORKFLOW" in
  delivery-focused|architecture-focused|review-focused|learning-focused) ;;
  *) echo "Unknown workflow: '$WORKFLOW' (expected delivery-focused|architecture-focused|review-focused|learning-focused)" >&2; exit 1;;
esac

# Defaults that depend on the chosen axes (staff/fullstack reproduce the
# previous hardcoded defaults, so the default run is unchanged).
case "$SENIORITY" in
  mid)       ROLE_DEFAULT="Mid-level Software Engineer" ;;
  senior)    ROLE_DEFAULT="Senior Software Engineer" ;;
  staff)     ROLE_DEFAULT="Staff Engineer and Senior Individual Contributor" ;;
  principal) ROLE_DEFAULT="Principal Engineer" ;;
esac
case "$DISCIPLINE" in
  frontend)  BACKGROUND_DEFAULT="frontend engineering with strong ownership of UI architecture, performance, accessibility, and maintainable product delivery" ;;
  fullstack) BACKGROUND_DEFAULT="primarily frontend engineering, but my current scope is full-stack architecture, technical leadership, system design, and engineering decision-making" ;;
esac

ask ROLE              "Role / title"                       "$ROLE_DEFAULT"
ask BACKGROUND        "Background (fragment: 'my background is ...')" "$BACKGROUND_DEFAULT"
ask PRIMARY_LANGUAGES "Primary languages"                  "TypeScript, JavaScript"
ask FRONTEND_STACK    "Frontend stack"                     "React, Next.js"
ask BACKEND_STACK     "Backend stack"                      "Node.js (TypeScript)"
ask DATABASE          "Database"                           "PostgreSQL"
ask TESTING_STACK     "Testing stack"                      "Vitest, React Testing Library"
ask INFRA             "Infrastructure"                     "Vercel"
ask PACKAGE_MANAGER   "Package manager"                    "npm"
ask REPO_LAYOUT       "Repo layout"                        "Monorepo"
ask ISSUE_TRACKER     "Issue tracker"                      "Jira"
ask OUTPUT_LANGUAGE   "Output language for PR/review text" "English"

# BACKGROUND_SHORT: a standalone sentence for the condensed CLAUDE.md.
first_char="$(printf '%s' "$BACKGROUND" | cut -c1 | tr '[:lower:]' '[:upper:]')"
rest="$(printf '%s' "$BACKGROUND" | cut -c2-)"
BACKGROUND_SHORT="${first_char}${rest}."

# --- Seniority-varied sections ----------------------------------------------
# The "staff" variants are verbatim the previous fixed text, so staff+fullstack
# regenerates byte-for-byte identical persona files.
seniority_model_full() {
  case "$SENIORITY" in
    mid) cat <<'EOF'
Treat me as a mid-level engineer growing toward senior.

Explain non-obvious concepts, trade-offs, and the reasoning behind a recommendation as you go, rather than assuming I already know it.

Favor guided, tactical, code-level help. Confirm with me before large or architectural changes.

Assume working knowledge of:

- The core language and framework I work in
- Everyday testing and debugging
- Reading and reviewing typical application code

Do not assume deep distributed-systems, architecture, or operations experience.

Focus on correctness, readable code, tests, and building durable habits.
EOF
      ;;
    senior) cat <<'EOF'
Treat me as a senior technical peer.

Do not explain basic engineering concepts unless explicitly requested.

Assume familiarity with:

- Frontend and backend architecture
- Databases
- CI/CD
- Cloud platforms
- Performance engineering

Focus on feature ownership, sound trade-offs, and decision quality rather than introductory explanations.
EOF
      ;;
    staff) cat <<'EOF'
Treat me as a senior technical peer.

Do not explain basic engineering concepts unless explicitly requested.

Assume familiarity with:

- Software architecture
- Distributed systems fundamentals
- Frontend architecture
- Backend architecture
- Databases
- CI/CD
- Cloud platforms
- Observability
- Performance engineering

Focus on decision quality rather than introductory explanations.
EOF
      ;;
    principal) cat <<'EOF'
Treat me as a principal-level peer operating at organizational and strategic altitude.

Do not explain fundamentals or walk through implementation unless I ask. Assume deep architecture, systems, and operations experience.

Center the conversation on:

- Technical strategy and direction
- Cross-team and organizational trade-offs
- Long-term system evolution
- Decision quality and leverage

Optimize for leverage and clarity of direction over hands-on code.
EOF
      ;;
  esac
}

seniority_model_short() {
  case "$SENIORITY" in
    mid)       printf '%s' "Treat as a mid-level engineer growing toward senior. Explain non-obvious concepts and trade-offs as you go. Favor guided, tactical, code-level help; confirm before large or architectural changes. Assume working knowledge of the core stack, not deep distributed-systems or architecture experience. Focus on correctness, tests, and good habits." ;;
    senior)    printf '%s' "Treat as a senior technical peer. Do not explain basic engineering concepts unless asked. Assume familiarity with frontend/backend architecture, databases, CI/CD, cloud, performance. Focus on feature ownership and **decision quality**, not introductions." ;;
    staff)     printf '%s' "Treat as a senior technical peer. Do not explain basic engineering concepts unless asked. Assume familiarity with software/frontend/backend architecture, distributed systems, databases, CI/CD, cloud, observability, performance. Focus on **decision quality**, not introductions." ;;
    principal) printf '%s' "Treat as a principal-level peer at org and strategy altitude: technical strategy, cross-team trade-offs, long-term system evolution, decision quality. Assume deep architecture experience; skip fundamentals and implementation hand-holding unless asked. Optimize for leverage over hands-on code." ;;
  esac
}

SENIORITY_MODEL="$(seniority_model_full)"
SENIORITY_MODEL_SHORT="$(seniority_model_short)"

# Replace every {{KEY}} in the template text with its value (literal, no regex).
fill() {
  local content; content="$(cat "$1")"
  local key val
  for key in ROLE BACKGROUND BACKGROUND_SHORT PRIMARY_LANGUAGES FRONTEND_STACK \
             BACKEND_STACK DATABASE TESTING_STACK INFRA PACKAGE_MANAGER \
             REPO_LAYOUT ISSUE_TRACKER OUTPUT_LANGUAGE \
             SENIORITY_MODEL SENIORITY_MODEL_SHORT; do
    val="${!key}"
    content="${content//\{\{$key\}\}/$val}"
  done
  # Drop the leading template HTML comment block.
  printf '%s\n' "$content" | sed '/^<!--$/,/^-->$/d'
}

fill "$PERSONA_TEMPLATE" > "$PERSONA_DIR/persona.md"
fill "$CLAUDE_TEMPLATE"  > "$PERSONA_DIR/CLAUDE.md"

# Copilot personal instructions: a separate template (bespoke structure, not a
# mirror of the persona canon) that reuses the same identity placeholders, so
# Copilot personalizes by seniority and stack like the other tools.
COPILOT_TEMPLATE="$REPO_ROOT/copilot/home/.copilot/copilot-instructions.md"
if [ -f "$COPILOT_TEMPLATE" ]; then
  fill "$COPILOT_TEMPLATE" > "$PERSONA_DIR/copilot-instructions.md"
fi

# --- Recommended skills: a generated view, not an install --------------------
# Every skill ships to every profile; this only picks which to foreground.
# Names are validated against the actual Claude Code skill catalog, so the
# mapping cannot drift into referencing a skill that does not exist.
write_recommended_skills() {
  local rec="spec debug commit testing-checklist pr-classify humanizer"
  case "$DISCIPLINE" in
    frontend)  rec="$rec web-performance-checklist web-security-checklist lazy" ;;
    fullstack) rec="$rec web-performance-checklist web-security-checklist lazy security-pass" ;;
  esac
  case "$SENIORITY" in
    mid)       rec="$rec lazy" ;;
    senior)    rec="$rec adr pr-comment pr-recheck" ;;
    staff)     rec="$rec rfc adr module-design complexity-audit debt-ledger security-pass" ;;
    principal) rec="$rec rfc adr module-design complexity-audit debt-ledger" ;;
  esac
  # Workflow foregrounds an emphasis set. The default 'architecture-focused' adds
  # only skills already recommended for staff+fullstack, so the default profile's
  # list stays unchanged; the axis just surfaces in the header + emphasis line.
  local emphasis
  case "$WORKFLOW" in
    delivery-focused)     rec="$rec spec lazy commit pr-comment"
                          emphasis="ship-oriented skills: specs, the laziest-solution ladder, small commits, and PR descriptions." ;;
    architecture-focused) rec="$rec rfc adr module-design complexity-audit"
                          emphasis="design-first skills: RFCs, ADRs, module design, and whole-tree complexity checks." ;;
    review-focused)       rec="$rec pr-classify pr-recheck pr-comment"
                          emphasis="review skills: tiered PR classification, second-pass re-review, and PR descriptions." ;;
    learning-focused)     rec="$rec codebase-map debug testing-checklist spec lazy"
                          emphasis="understanding-first skills: orienting in an unfamiliar codebase, reproduce-then-fix debugging, specs, and test coverage." ;;
  esac

  local rec_sorted catalog also s
  rec_sorted="$(printf '%s\n' $rec | awk 'NF' | sort -u)"
  catalog="$(for d in "$SKILLS_DIR"/*/; do basename "$d"; done | sort)"

  while IFS= read -r s; do
    [ -z "$s" ] && continue
    if ! printf '%s\n' "$catalog" | grep -qxF "$s"; then
      echo "create-persona: recommended skill '$s' is not a shipped skill in $SKILLS_DIR" >&2
      exit 1
    fi
  done <<< "$rec_sorted"

  also="$(comm -23 <(printf '%s\n' "$catalog") <(printf '%s\n' "$rec_sorted"))"

  printf '# Recommended skills\n\n'
  printf 'Profile: discipline=%s, seniority=%s, workflow=%s.\n\n' "$DISCIPLINE" "$SENIORITY" "$WORKFLOW"
  printf 'Workflow (%s) foregrounds %s\n\n' "$WORKFLOW" "$emphasis"
  printf 'All skills ship with the kit. This list is which to reach for first; see the\n'
  printf 'skill catalog in the top-level README for what each one enforces.\n\n'
  printf '## Recommended for your profile\n\n'
  printf '%s\n' "$rec_sorted" | sed 's/^/- /'
  printf '\n## Also in the catalog\n\n'
  if [ -n "$also" ]; then
    printf '%s\n' "$also" | sed 's/^/- /'
  else
    printf '(none)\n'
  fi
}

RECOMMENDED_OUT="$PERSONA_DIR/recommended-skills.md"
if [ -d "$SKILLS_DIR" ]; then
  write_recommended_skills > "$RECOMMENDED_OUT"
fi

echo
echo "Wrote:"
echo "  $PERSONA_DIR/persona.md"
echo "  $PERSONA_DIR/CLAUDE.md"
[ -f "$PERSONA_DIR/copilot-instructions.md" ] && echo "  $PERSONA_DIR/copilot-instructions.md"
[ -f "$RECOMMENDED_OUT" ] && echo "  $RECOMMENDED_OUT"
echo
echo "Next: run the per-tool installers. They pick up these filled files"
echo "automatically (see each tool's scripts/ and the top-level README)."
