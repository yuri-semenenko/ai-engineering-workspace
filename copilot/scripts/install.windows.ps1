param(
  [string]$TargetHome = $env:USERPROFILE,
  [string]$WorkspacePath
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
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
$FilledCopilot = Join-Path (Split-Path -Parent $RepoRoot) 'persona\copilot-instructions.md'
$CopilotSource = Join-Path $HomeConfig 'copilot-instructions.md'
if (Test-Path -LiteralPath $FilledCopilot) { $CopilotSource = $FilledCopilot }

Copy-WithBackup `
  -Source $CopilotSource `
  -Destination (Join-Path $TargetCopilot 'copilot-instructions.md')

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
if (-not $WorkspacePath) {
  Write-Host 'For repository-level setup, re-run with -WorkspacePath <path to your repo>.'
}
