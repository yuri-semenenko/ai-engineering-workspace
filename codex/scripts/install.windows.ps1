param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' })
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Split-Path -Parent $ScriptDir            # ...\codex
$RepoRoot = Split-Path -Parent $ConfigDir
$PersonaWizard = Join-Path $RepoRoot 'scripts\create-persona.ps1'
$SourceReferences = Join-Path $ConfigDir 'references'
$SourceSkills = Join-Path $ConfigDir 'skills'
$SourceAgents = Join-Path $ConfigDir 'AGENTS.md'
$TargetReferences = Join-Path $CodexHome 'references'
$TargetSkills = Join-Path $CodexHome 'skills'
$TargetAgents = Join-Path $CodexHome 'AGENTS.md'

if (-not (Test-Path -LiteralPath $SourceReferences)) {
    throw "Source references not found: $SourceReferences"
}
if (-not (Test-Path -LiteralPath $SourceSkills)) {
    throw "Source skills not found: $SourceSkills"
}
if (-not (Test-Path -LiteralPath $SourceAgents)) {
    throw "Source AGENTS.md not found: $SourceAgents"
}

New-Item -ItemType Directory -Force -Path $TargetReferences | Out-Null
Copy-Item -Path (Join-Path $SourceReferences '*') -Destination $TargetReferences -Recurse -Force

# Prefer the user's filled persona (scripts\create-persona.ps1) over the
# committed template mirror. Falls back to the mirror when codex\ is standalone.
$PersonaSource = Join-Path $RepoRoot 'persona\persona.md'
$PersonaFromWizard = Test-Path -LiteralPath $PersonaSource -PathType Leaf
if ($PersonaFromWizard) {
    Copy-Item -LiteralPath $PersonaSource -Destination (Join-Path $TargetReferences 'persona.md') -Force
}

# The committed mirror ships {{PLACEHOLDERS}}, and a half-edited persona.md
# ships them too. Codex loads whichever landed and reads them as literal text,
# so count what is actually in the installed file rather than trusting which
# branch ran: a silent fallback used to end on a clean "installed" summary.
$PersonaTarget = Join-Path $TargetReferences 'persona.md'
if (-not (Test-Path -LiteralPath $PersonaTarget -PathType Leaf)) {
    throw "Persona target is not a regular file: $PersonaTarget"
}
$PersonaUnfilled = @(Select-String -LiteralPath $PersonaTarget -Pattern '\{\{').Count

New-Item -ItemType Directory -Force -Path $TargetSkills | Out-Null
Copy-Item -Path (Join-Path $SourceSkills '*') -Destination $TargetSkills -Recurse -Force

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force

Write-Host "Codex references, user skills, and AGENTS.md installed."
if ($PersonaUnfilled -gt 0) {
    if ($PersonaFromWizard) {
        Write-Host "Persona: INCOMPLETE. $PersonaSource still holds $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s), copied as-is."
    } else {
        Write-Host "Persona: TEMPLATE ONLY. No $PersonaSource, so the committed mirror landed with $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s)."
    }
    if ($PersonaFromWizard) {
        Write-Host "Finish filling $PersonaSource, then re-run this installer."
    } elseif (Test-Path -LiteralPath $PersonaWizard -PathType Leaf) {
        Write-Host ('Run: pwsh -NoProfile -File "{0}". Then re-run this installer.' -f $PersonaWizard)
    } else {
        Write-Host 'This standalone package has no persona wizard. Run the wizard and installer from a full repository checkout.'
    }
} elseif ($PersonaFromWizard) {
    Write-Host "Persona: installed from $PersonaSource."
} else {
    Write-Host "Persona: installed from the committed mirror; no $PersonaSource, and nothing was left to fill."
}
Write-Host "References target: $TargetReferences"
Write-Host "Skills target: $TargetSkills"
Write-Host "AGENTS.md target: $TargetAgents (always-on git guardrails)"
Write-Host "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
