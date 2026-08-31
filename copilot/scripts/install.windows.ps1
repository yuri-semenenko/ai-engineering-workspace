param(
  [string]$TargetHome = $env:USERPROFILE,
  [string]$WorkspacePath
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$WorkspaceRoot = Split-Path -Parent $RepoRoot
$PersonaWizard = Join-Path $WorkspaceRoot 'scripts\create-persona.ps1'
# Random tail: the timestamp alone collides when the installer runs twice in
# the same second, and Move-Item onto an existing backup is a hard error.
$Timestamp = '{0}-{1:D4}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), (Get-Random -Maximum 10000)

function Copy-WithBackup {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source not found: $Source"
  }

  $DestinationDir = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null

  if (Test-Path -LiteralPath $Destination) {
    $Backup = "$Destination.pre-copilot-config.$Timestamp"
    Move-Item -LiteralPath $Destination -Destination $Backup
    Write-Host "Backed up $Destination to $Backup"
  }

  Copy-Item -LiteralPath $Source -Destination $Destination
  Write-Host "Copied $Destination"
}

$HomeConfig = Join-Path $RepoRoot 'home\.copilot'
$TargetCopilot = Join-Path $TargetHome '.copilot'

# Prefer the wizard's filled instructions; fall back to the committed template
# (which still holds {{PLACEHOLDERS}}) when copilot/ is used standalone.
$FilledCopilot = Join-Path $WorkspaceRoot 'persona\copilot-instructions.md'
$CopilotSource = Join-Path $HomeConfig 'copilot-instructions.md'
$PersonaFromWizard = Test-Path -LiteralPath $FilledCopilot -PathType Leaf
if ($PersonaFromWizard) { $CopilotSource = $FilledCopilot }

$TargetInstructionsFile = Join-Path $TargetCopilot 'copilot-instructions.md'
Copy-WithBackup -Source $CopilotSource -Destination $TargetInstructionsFile

# The committed template ships {{PLACEHOLDERS}}, and a half-edited wizard output
# ships them too. Copilot reads whichever landed as literal text, so count what
# is actually in the installed file rather than trusting which branch ran: a
# silent fallback used to end on a clean "Done." with nothing else said.
if (-not (Test-Path -LiteralPath $TargetInstructionsFile -PathType Leaf)) {
  throw "Persona target is not a regular file: $TargetInstructionsFile"
}
$PersonaUnfilled = @(Select-String -LiteralPath $TargetInstructionsFile -Pattern '\{\{').Count

$SourceInstructions = Join-Path $HomeConfig 'instructions'
$TargetInstructions = Join-Path $TargetCopilot 'instructions'
New-Item -ItemType Directory -Force -Path $TargetInstructions | Out-Null

Get-ChildItem -LiteralPath $SourceInstructions -Filter '*.instructions.md' | ForEach-Object {
  Copy-WithBackup -Source $_.FullName -Destination (Join-Path $TargetInstructions $_.Name)
}

# Repository-level setup, when a workspace was named. Optional: personal
# instructions above are useful on their own.
if ($WorkspacePath) {
  $Template = Join-Path $RepoRoot 'workspace-template'
  $TargetGithub = Join-Path $WorkspacePath '.github'

  Copy-WithBackup -Source (Join-Path $Template 'AGENTS.md') -Destination (Join-Path $WorkspacePath 'AGENTS.md')
  Copy-WithBackup -Source (Join-Path $Template 'CLAUDE.md') -Destination (Join-Path $WorkspacePath 'CLAUDE.md')
  Copy-WithBackup `
    -Source (Join-Path $Template '.github\copilot-instructions.md') `
    -Destination (Join-Path $TargetGithub 'copilot-instructions.md')

  foreach ($set in @(@('instructions', '*.instructions.md'), @('prompts', '*.prompt.md'))) {
    $sourceDir = Join-Path $Template ".github\$($set[0])"
    $targetDir = Join-Path $TargetGithub $set[0]
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Get-ChildItem -LiteralPath $sourceDir -Filter $set[1] | ForEach-Object {
      Copy-WithBackup -Source $_.FullName -Destination (Join-Path $targetDir $_.Name)
    }
  }
}

Write-Host ''
Write-Host 'Done. No auth files, hooks, MCP config, or memory files were copied.'
if ($PersonaUnfilled -gt 0) {
  if ($PersonaFromWizard) {
    Write-Host "Persona: INCOMPLETE. $FilledCopilot still holds $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s), copied as-is."
  } else {
    Write-Host "Persona: TEMPLATE ONLY. No $FilledCopilot, so the committed template landed with $PersonaUnfilled unfilled {{PLACEHOLDER}} line(s)."
  }
  if ($PersonaFromWizard) {
    Write-Host "Finish filling $FilledCopilot, then re-run this installer."
  } elseif (Test-Path -LiteralPath $PersonaWizard -PathType Leaf) {
    Write-Host ('Run: pwsh -NoProfile -File "{0}". Then re-run this installer.' -f $PersonaWizard)
  } else {
    Write-Host 'This standalone package has no persona wizard. Run the wizard and installer from a full repository checkout.'
  }
} elseif ($PersonaFromWizard) {
  Write-Host "Persona: installed from $FilledCopilot."
} else {
  Write-Host "Persona: installed from the committed template; no $FilledCopilot, and nothing was left to fill."
}
if (-not $WorkspacePath) {
  Write-Host 'For repository-level setup, re-run with -WorkspacePath <path to your repo>.'
}
