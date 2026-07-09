#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$Defaults
)

$ErrorActionPreference = 'Stop'

# Generate your own persona.md + CLAUDE.md from the shared templates.
# Only the identity header is asked; the methodology is fixed canon. Three axes
# shape the output beyond text substitution:
#   - seniority  -> the "Seniority Model" section
#   - discipline -> background framing + the recommended-skills list
#   - workflow   -> which skills recommended-skills.md foregrounds + its emphasis
#                   line (generated view only; no template placeholder)
#
#   powershell -NoProfile -File .\scripts\create-persona.ps1            # interactive
#   powershell -NoProfile -File .\scripts\create-persona.ps1 -Defaults   # accept all defaults

$RepoRoot        = Split-Path -Parent $PSScriptRoot
$PersonaDir      = Join-Path $RepoRoot 'persona'
$PersonaTemplate = Join-Path $PersonaDir 'persona.template.md'
$ClaudeTemplate  = Join-Path $PersonaDir 'CLAUDE.template.md'
$SkillsDir       = [IO.Path]::Combine($RepoRoot, 'claude-code', '.claude', 'skills')

foreach ($f in @($PersonaTemplate, $ClaudeTemplate)) {
  if (-not (Test-Path $f)) { Write-Error "Template not found: $f"; exit 1 }
}

function Ask([string]$Prompt, [string]$Default) {
  if ($Defaults) { return $Default }
  $reply = Read-Host "$Prompt [$Default]"
  if ([string]::IsNullOrWhiteSpace($reply)) { return $Default }
  return $reply
}

Write-Host "Creating your persona. Press Enter to accept each default.`n"

# --- Axes that shape the persona beyond plain substitution -------------------
$Discipline = (Ask 'Discipline (frontend/fullstack)' 'fullstack').ToLower()
$Seniority  = (Ask 'Seniority (mid/senior/staff/principal)' 'staff').ToLower()
$Workflow   = (Ask 'Workflow (delivery-focused/architecture-focused/review-focused/learning-focused)' 'architecture-focused').ToLower()

if ($Discipline -notin @('frontend', 'fullstack')) {
  Write-Error "Unknown discipline: '$Discipline' (expected frontend|fullstack)"; exit 1
}
if ($Seniority -notin @('mid', 'senior', 'staff', 'principal')) {
  Write-Error "Unknown seniority: '$Seniority' (expected mid|senior|staff|principal)"; exit 1
}
if ($Workflow -notin @('delivery-focused', 'architecture-focused', 'review-focused', 'learning-focused')) {
  Write-Error "Unknown workflow: '$Workflow' (expected delivery-focused|architecture-focused|review-focused|learning-focused)"; exit 1
}

# Defaults that depend on the chosen axes (staff/fullstack reproduce the
# previous hardcoded defaults, so the default run is unchanged).
$RoleDefault = switch ($Seniority) {
  'mid'       { 'Mid-level Software Engineer' }
  'senior'    { 'Senior Software Engineer' }
  'staff'     { 'Staff Engineer and Senior Individual Contributor' }
  'principal' { 'Principal Engineer' }
}
$BackgroundDefault = switch ($Discipline) {
  'frontend'  { 'frontend engineering with strong ownership of UI architecture, performance, accessibility, and maintainable product delivery' }
  'fullstack' { 'primarily frontend engineering, but my current scope is full-stack architecture, technical leadership, system design, and engineering decision-making' }
}

# The "staff" variants are verbatim the previous fixed text, so staff+fullstack
# regenerates identical persona files.
$SeniorityModelFull = switch ($Seniority) {
  'mid' { @'
Treat me as a mid-level engineer growing toward senior.

Explain non-obvious concepts, trade-offs, and the reasoning behind a recommendation as you go, rather than assuming I already know it.

Favor guided, tactical, code-level help. Confirm with me before large or architectural changes.

Assume working knowledge of:

- The core language and framework I work in
- Everyday testing and debugging
- Reading and reviewing typical application code

Do not assume deep distributed-systems, architecture, or operations experience.

Focus on correctness, readable code, tests, and building durable habits.
'@ }
  'senior' { @'
Treat me as a senior technical peer.

Do not explain basic engineering concepts unless explicitly requested.

Assume familiarity with:

- Frontend and backend architecture
- Databases
- CI/CD
- Cloud platforms
- Performance engineering

Focus on feature ownership, sound trade-offs, and decision quality rather than introductory explanations.
'@ }
  'staff' { @'
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
'@ }
  'principal' { @'
Treat me as a principal-level peer operating at organizational and strategic altitude.

Do not explain fundamentals or walk through implementation unless I ask. Assume deep architecture, systems, and operations experience.

Center the conversation on:

- Technical strategy and direction
- Cross-team and organizational trade-offs
- Long-term system evolution
- Decision quality and leverage

Optimize for leverage and clarity of direction over hands-on code.
'@ }
}

$SeniorityModelShort = switch ($Seniority) {
  'mid'       { 'Treat as a mid-level engineer growing toward senior. Explain non-obvious concepts and trade-offs as you go. Favor guided, tactical, code-level help; confirm before large or architectural changes. Assume working knowledge of the core stack, not deep distributed-systems or architecture experience. Focus on correctness, tests, and good habits.' }
  'senior'    { 'Treat as a senior technical peer. Do not explain basic engineering concepts unless asked. Assume familiarity with frontend/backend architecture, databases, CI/CD, cloud, performance. Focus on feature ownership and **decision quality**, not introductions.' }
  'staff'     { 'Treat as a senior technical peer. Do not explain basic engineering concepts unless asked. Assume familiarity with software/frontend/backend architecture, distributed systems, databases, CI/CD, cloud, observability, performance. Focus on **decision quality**, not introductions.' }
  'principal' { 'Treat as a principal-level peer at org and strategy altitude: technical strategy, cross-team trade-offs, long-term system evolution, decision quality. Assume deep architecture experience; skip fundamentals and implementation hand-holding unless asked. Optimize for leverage over hands-on code.' }
}

$vals = [ordered]@{
  ROLE              = Ask 'Role / title' $RoleDefault
  BACKGROUND        = Ask "Background (fragment: 'my background is ...')" $BackgroundDefault
  PRIMARY_LANGUAGES = Ask 'Primary languages' 'TypeScript, JavaScript'
  FRONTEND_STACK    = Ask 'Frontend stack' 'React, Next.js'
  BACKEND_STACK     = Ask 'Backend stack' 'Node.js (TypeScript)'
  DATABASE          = Ask 'Database' 'PostgreSQL'
  TESTING_STACK     = Ask 'Testing stack' 'Vitest, React Testing Library'
  INFRA             = Ask 'Infrastructure' 'Vercel'
  PACKAGE_MANAGER   = Ask 'Package manager' 'npm'
  REPO_LAYOUT       = Ask 'Repo layout' 'Monorepo'
  ISSUE_TRACKER     = Ask 'Issue tracker' 'Jira'
  OUTPUT_LANGUAGE   = Ask 'Output language for PR/review text' 'English'
}

$bg = $vals['BACKGROUND']
$vals['BACKGROUND_SHORT']       = ($bg.Substring(0,1).ToUpper() + $bg.Substring(1) + '.')
$vals['SENIORITY_MODEL']        = $SeniorityModelFull
$vals['SENIORITY_MODEL_SHORT']  = $SeniorityModelShort

function Fill([string]$TemplatePath) {
  $content = Get-Content -Raw -LiteralPath $TemplatePath
  foreach ($k in $vals.Keys) {
    $content = $content.Replace('{{' + $k + '}}', $vals[$k])
  }
  # Drop the leading template HTML comment block.
  $content = [regex]::Replace($content, '(?ms)^<!--.*?-->\r?\n', '')
  return $content
}

$personaOut = Join-Path $PersonaDir 'persona.md'
$claudeOut  = Join-Path $PersonaDir 'CLAUDE.md'
Set-Content -LiteralPath $personaOut -Value (Fill $PersonaTemplate) -NoNewline
Set-Content -LiteralPath $claudeOut  -Value (Fill $ClaudeTemplate)  -NoNewline

# Copilot personal instructions: a separate template that reuses the same
# identity placeholders (bespoke structure, not a persona-canon mirror).
$copilotTemplate = [IO.Path]::Combine($RepoRoot, 'copilot', 'home', '.copilot', 'copilot-instructions.md')
$copilotOut = Join-Path $PersonaDir 'copilot-instructions.md'
if (Test-Path $copilotTemplate) {
  Set-Content -LiteralPath $copilotOut -Value (Fill $copilotTemplate) -NoNewline
}

# --- Recommended skills: a generated view, not an install --------------------
# Every skill ships to every profile; this only picks which to foreground.
# Names are validated against the actual Claude Code skill catalog.
$recommendedOut = Join-Path $PersonaDir 'recommended-skills.md'
if (Test-Path $SkillsDir) {
  $rec = @('spec', 'debug', 'commit', 'testing-checklist', 'pr-classify', 'humanizer')
  switch ($Discipline) {
    'frontend'  { $rec += @('web-performance-checklist', 'web-security-checklist', 'lazy') }
    'fullstack' { $rec += @('web-performance-checklist', 'web-security-checklist', 'lazy', 'security-pass') }
  }
  switch ($Seniority) {
    'mid'       { $rec += @('lazy') }
    'senior'    { $rec += @('adr', 'pr-comment', 'pr-recheck') }
    'staff'     { $rec += @('rfc', 'adr', 'module-design', 'complexity-audit', 'debt-ledger', 'security-pass') }
    'principal' { $rec += @('rfc', 'adr', 'module-design', 'complexity-audit', 'debt-ledger') }
  }
  # Workflow foregrounds an emphasis set. The default 'architecture-focused' adds
  # only skills already recommended for staff+fullstack, so the default profile's
  # list stays unchanged; the axis just surfaces in the header + emphasis line.
  switch ($Workflow) {
    'delivery-focused'     { $rec += @('spec', 'lazy', 'commit', 'pr-comment') }
    'architecture-focused' { $rec += @('rfc', 'adr', 'module-design', 'complexity-audit') }
    'review-focused'       { $rec += @('pr-classify', 'pr-recheck', 'pr-comment') }
    'learning-focused'     { $rec += @('debug', 'testing-checklist', 'spec', 'lazy') }
  }
  $emphasis = switch ($Workflow) {
    'delivery-focused'     { 'ship-oriented skills: specs, the laziest-solution ladder, small commits, and PR descriptions.' }
    'architecture-focused' { 'design-first skills: RFCs, ADRs, module design, and whole-tree complexity checks.' }
    'review-focused'       { 'review skills: tiered PR classification, second-pass re-review, and PR descriptions.' }
    'learning-focused'     { 'understanding-first skills: reproduce-then-fix debugging, specs, and test coverage.' }
  }

  $recSorted = $rec | Sort-Object -Unique
  $catalog   = Get-ChildItem -Directory -LiteralPath $SkillsDir | Select-Object -ExpandProperty Name | Sort-Object
  foreach ($s in $recSorted) {
    if ($catalog -notcontains $s) {
      Write-Error "create-persona: recommended skill '$s' is not a shipped skill in $SkillsDir"; exit 1
    }
  }
  $also = $catalog | Where-Object { $recSorted -notcontains $_ }

  $lines = @()
  $lines += '# Recommended skills'
  $lines += ''
  $lines += "Profile: discipline=$Discipline, seniority=$Seniority, workflow=$Workflow."
  $lines += ''
  $lines += "Workflow ($Workflow) foregrounds $emphasis"
  $lines += ''
  $lines += 'All skills ship with the kit. This list is which to reach for first; see the'
  $lines += 'skill catalog in the top-level README for what each one enforces.'
  $lines += ''
  $lines += '## Recommended for your profile'
  $lines += ''
  $lines += ($recSorted | ForEach-Object { "- $_" })
  $lines += ''
  $lines += '## Also in the catalog'
  $lines += ''
  if ($also) { $lines += ($also | ForEach-Object { "- $_" }) } else { $lines += '(none)' }
  Set-Content -LiteralPath $recommendedOut -Value ($lines -join "`n")
}

Write-Host "`nWrote:"
Write-Host "  $personaOut"
Write-Host "  $claudeOut"
if (Test-Path $copilotOut) { Write-Host "  $copilotOut" }
if (Test-Path $recommendedOut) { Write-Host "  $recommendedOut" }
Write-Host "`nNext: run the per-tool installers (see the top-level README)."
