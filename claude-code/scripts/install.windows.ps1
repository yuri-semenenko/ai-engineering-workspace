param(
    [ValidateSet('Copy', 'Symlink')]
    [string]$Mode = 'Copy'
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Split-Path -Parent $ScriptDir            # ...\claude-code
$RepoRoot = Split-Path -Parent $ConfigDir
$PersonaDir = Join-Path $RepoRoot 'persona'
$SourceClaude = Join-Path $ConfigDir '.claude'
$TargetClaude = Join-Path $HOME '.claude'

function Test-IsReparsePoint {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $item = Get-Item -LiteralPath $Path -Force
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Backup-ExistingPath {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $backup = "$Path.backup.$(Get-Date -Format yyyyMMddHHmmss)"
        Move-Item -LiteralPath $Path -Destination $backup
        Write-Host "Moved existing path to $backup"
    }
}

if (-not (Test-Path -LiteralPath $SourceClaude)) {
    throw "Source Claude config not found: $SourceClaude"
}

New-Item -ItemType Directory -Force -Path $HOME | Out-Null

# --- 1. Persona: generate the user's own files on first install ---------------
if (-not (Test-Path -LiteralPath (Join-Path $PersonaDir 'CLAUDE.md'))) {
    Write-Host 'No persona found yet. Running the persona wizard...'
    & powershell -NoProfile -File (Join-Path $RepoRoot 'scripts\create-persona.ps1')
}

# --- 2. Provision user-specific files into the source tree (gitignored) -------
Copy-Item -LiteralPath (Join-Path $PersonaDir 'CLAUDE.md') -Destination (Join-Path $SourceClaude 'CLAUDE.md') -Force
$personaFull = Join-Path $PersonaDir 'persona.md'
if (Test-Path -LiteralPath $personaFull) {
    Copy-Item -LiteralPath $personaFull -Destination (Join-Path $HOME 'persona.md') -Force
}
$settings = Join-Path $SourceClaude 'settings.json'
if (-not (Test-Path -LiteralPath $settings)) {
    Copy-Item -LiteralPath (Join-Path $SourceClaude 'settings.example.json') -Destination $settings -Force
    Write-Host 'Seeded settings.json from settings.example.json (edit freely; it is gitignored).'
}

# --- 3. Symlink or copy the .claude tree --------------------------------------
if ($Mode -eq 'Symlink') {
    if (Test-Path -LiteralPath $TargetClaude) {
        if (Test-IsReparsePoint -Path $TargetClaude) {
            Remove-Item -LiteralPath $TargetClaude -Force
        } else {
            Backup-ExistingPath -Path $TargetClaude
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $TargetClaude -Target $SourceClaude | Out-Null
    } catch {
        throw "Could not create symlink. Re-run as Administrator, enable Developer Mode, or use the default Copy mode."
    }
} else {
    Backup-ExistingPath -Path $TargetClaude
    Copy-Item -Path $SourceClaude -Destination $TargetClaude -Recurse -Force
}

Write-Host "Claude config installed in $Mode mode."
Write-Host "Claude config target: $TargetClaude"
Write-Host "Codex references are provisioned separately by codex\scripts\install.windows.ps1."

# The hooks and statusline are shell scripts that read their input with jq. Say
# so at install time: a missing dependency turns the guardrails into no-ops
# rather than into an error.
$missing = @('bash', 'jq') | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
if ($missing) {
    Write-Warning ("Not on PATH: {0}. The hooks and statusline are shell scripts that parse their input with jq, so until both exist the branch guard, secret scan, and protected-path guard do nothing at all. Git for Windows provides bash; for jq: winget install jqlang.jq" -f ($missing -join ', '))
}
