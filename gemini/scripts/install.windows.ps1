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
$PersonaSource = Join-Path $RepoRoot 'persona\CLAUDE.md'
$PersonaFromWizard = Test-Path -LiteralPath $PersonaSource
if ($PersonaFromWizard) {
    Copy-Item -LiteralPath $PersonaSource -Destination $TargetContext -Force
} else {
    Copy-Item -LiteralPath $SourceContext -Destination $TargetContext -Force
}

# The committed mirror ships {{PLACEHOLDERS}}, and a half-edited CLAUDE.md ships
# them too. GEMINI.md is re-sent on every prompt, so either one costs tokens on
# every turn to say nothing. Count what actually landed rather than trusting
# which branch ran: a silent fallback used to end on a clean "installed" summary.
$PersonaUnfilled = @(Select-String -LiteralPath $TargetContext -Pattern '\{\{').Count

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
if ($PersonaUnfilled -gt 0) {
    if ($PersonaFromWizard) {
        Write-Host "Persona: INCOMPLETE. $PersonaSource still holds $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s), copied as-is."
    } else {
        Write-Host "Persona: TEMPLATE ONLY. No $PersonaSource, so the committed mirror landed with $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s)."
    }
    Write-Host 'Gemini re-sends that file on every prompt. Run scripts\create-persona.ps1, then re-run this installer.'
} elseif ($PersonaFromWizard) {
    Write-Host "Persona: installed from $PersonaSource."
} else {
    Write-Host "Persona: installed from the committed mirror; no $PersonaSource, and nothing was left to fill."
}
Write-Host "Context target: $TargetContext (GEMINI.md, always-on persona)"
Write-Host "Commands target: $TargetCommands"
Write-Host "Settings target: $TargetSettings (tool allowlist + guardrail hooks + sandbox)"
Write-Host "Runtime state, auth, logs, sessions, telemetry, and cache files were not copied."
