param(
  [string]$TargetHome = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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

Write-Host ''
Write-Host 'Done. No auth files, hooks, MCP config, or memory files were copied.'
Write-Host 'For repository-level setup, manually review and copy files from workspace-template/.'
