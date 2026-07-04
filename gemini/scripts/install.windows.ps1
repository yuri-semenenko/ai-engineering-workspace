param(
    [string]$GeminiHome = $(if ($env:GEMINI_HOME) { $env:GEMINI_HOME } else { Join-Path $HOME '.gemini' })
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Split-Path -Parent $ScriptDir            # ...\gemini
$RepoRoot = Split-Path -Parent $ConfigDir
$SourceContext = Join-Path $ConfigDir 'references\GEMINI.md'
$SourceCommands = Join-Path $ConfigDir 'commands'
$SourceSettings = Join-Path $ConfigDir 'settings.example.json'
$TargetContext = Join-Path $GeminiHome 'GEMINI.md'
$TargetCommands = Join-Path $GeminiHome 'commands'
$TargetSettings = Join-Path $GeminiHome 'settings.json'

if (-not (Test-Path -LiteralPath $SourceContext)) {
    throw "Source context not found: $SourceContext (run scripts\sync-codex-references.ps1 first)"
}
if (-not (Test-Path -LiteralPath $SourceCommands)) {
    throw "Source commands not found: $SourceCommands"
}
if (-not (Test-Path -LiteralPath $SourceSettings)) {
    throw "Source settings not found: $SourceSettings"
}

New-Item -ItemType Directory -Force -Path $GeminiHome | Out-Null

# Prefer the user's filled condensed persona over the committed template mirror.
$personaFilled = Join-Path $RepoRoot 'persona\CLAUDE.md'
if (Test-Path -LiteralPath $personaFilled) {
    Copy-Item -LiteralPath $personaFilled -Destination $TargetContext -Force
    Write-Host 'Installed filled persona from persona\CLAUDE.md.'
} else {
    Copy-Item -LiteralPath $SourceContext -Destination $TargetContext -Force
}

New-Item -ItemType Directory -Force -Path $TargetCommands | Out-Null
Copy-Item -Path (Join-Path $SourceCommands '*.toml') -Destination $TargetCommands -Force

# Seed settings only on first install; never clobber a user's existing config.
if (Test-Path -LiteralPath $TargetSettings) {
    Write-Host "Left existing settings untouched: $TargetSettings"
} else {
    Copy-Item -LiteralPath $SourceSettings -Destination $TargetSettings -Force
    Write-Host "Seeded settings: $TargetSettings"
}

Write-Host "Gemini CLI context, commands, and settings installed."
Write-Host "Context target: $TargetContext (GEMINI.md, always-on persona)"
Write-Host "Commands target: $TargetCommands"
Write-Host "Settings target: $TargetSettings (tool allowlist + guardrail hooks + sandbox)"
Write-Host "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
