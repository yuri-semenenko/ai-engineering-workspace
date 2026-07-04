param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' })
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Split-Path -Parent $ScriptDir            # ...\codex
$RepoRoot = Split-Path -Parent $ConfigDir
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
$personaFilled = Join-Path $RepoRoot 'persona\persona.md'
if (Test-Path -LiteralPath $personaFilled) {
    Copy-Item -LiteralPath $personaFilled -Destination (Join-Path $TargetReferences 'persona.md') -Force
    Write-Host 'Installed filled persona from persona\persona.md.'
}

New-Item -ItemType Directory -Force -Path $TargetSkills | Out-Null
Copy-Item -Path (Join-Path $SourceSkills '*') -Destination $TargetSkills -Recurse -Force

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
Copy-Item -LiteralPath $SourceAgents -Destination $TargetAgents -Force

Write-Host "Codex references, user skills, and AGENTS.md installed."
Write-Host "References target: $TargetReferences"
Write-Host "Skills target: $TargetSkills"
Write-Host "AGENTS.md target: $TargetAgents (always-on git guardrails)"
Write-Host "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
