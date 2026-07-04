#Requires -Version 5.1
[CmdletBinding()]
param(
  [switch]$Defaults
)

$ErrorActionPreference = 'Stop'

# Generate your own persona.md + CLAUDE.md from the shared templates.
# Only the identity/stack/tooling header is asked; the methodology is fixed canon.
#
#   powershell -NoProfile -File .\scripts\create-persona.ps1            # interactive
#   powershell -NoProfile -File .\scripts\create-persona.ps1 -Defaults   # accept all defaults

$RepoRoot        = Split-Path -Parent $PSScriptRoot
$PersonaDir      = Join-Path $RepoRoot 'persona'
$PersonaTemplate = Join-Path $PersonaDir 'persona.template.md'
$ClaudeTemplate  = Join-Path $PersonaDir 'CLAUDE.template.md'

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

$vals = [ordered]@{
  ROLE              = Ask 'Role / title' 'Staff Engineer and Senior Individual Contributor'
  BACKGROUND        = Ask "Background (fragment: 'my background is ...')" 'primarily frontend engineering, but my current scope is full-stack architecture, technical leadership, system design, and engineering decision-making'
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
$vals['BACKGROUND_SHORT'] = ($bg.Substring(0,1).ToUpper() + $bg.Substring(1) + '.')

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

Write-Host "`nWrote:"
Write-Host "  $personaOut"
Write-Host "  $claudeOut"
Write-Host "`nNext: run the per-tool installers (see the top-level README)."
