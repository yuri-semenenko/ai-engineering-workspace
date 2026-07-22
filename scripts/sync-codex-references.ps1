param(
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

$CanonPersona = Join-Path $RepoRoot 'persona\persona.template.md'
$CanonCondensed = Join-Path $RepoRoot 'persona\CLAUDE.template.md'
$CanonMemory = Join-Path $RepoRoot 'claude-code\.claude\memory-seed.example'
$MirrorPersona = Join-Path $RepoRoot 'codex\references\persona.md'
$MirrorMemory = Join-Path $RepoRoot 'codex\references\memory-seed.example'
$MirrorGemini = Join-Path $RepoRoot 'gemini\references\GEMINI.md'
$SkillsRoot = Join-Path $RepoRoot 'codex\skills'
$GeminiCommandsRoot = Join-Path $RepoRoot 'gemini\commands'
$LoopsValidator = Join-Path $RepoRoot 'scripts\validate-loops.ps1'

# Read the frontmatter `name:` from a SKILL.md, or $null if absent.
function Get-SkillName {
    param([string]$Path)

    $lines = @(Get-Content -LiteralPath $Path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') {
        return $null
    }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }
        if ($lines[$i] -match '^name:\s*(.+?)\s*$') {
            return $Matches[1]
        }
    }
    return $null
}

# Validate the owned-here Codex skills: each has SKILL.md + agents/openai.yaml
# and a frontmatter name matching its directory. There is no auto-fix.
function Test-Skills {
    param([string]$Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        Write-Error "SKILLS: directory missing: $Root"
        return $false
    }

    $ok = $true
    foreach ($entry in Get-ChildItem -LiteralPath $Root) {
        if (-not $entry.PSIsContainer) {
            Write-Error "SKILLS: stray file at skills root: $($entry.Name)"
            $ok = $false
            continue
        }

        $name = $entry.Name
        $skillMd = Join-Path $entry.FullName 'SKILL.md'
        $agentYaml = Join-Path $entry.FullName 'agents\openai.yaml'

        if (-not (Test-Path -LiteralPath $skillMd)) {
            Write-Error "SKILLS: $name missing SKILL.md"
            $ok = $false
        }
        if (-not (Test-Path -LiteralPath $agentYaml)) {
            Write-Error "SKILLS: $name missing agents/openai.yaml"
            $ok = $false
        }

        if (Test-Path -LiteralPath $skillMd) {
            $fmName = Get-SkillName -Path $skillMd
            if ([string]::IsNullOrEmpty($fmName)) {
                Write-Error "SKILLS: $name SKILL.md has no frontmatter name:"
                $ok = $false
            } elseif ($fmName -ne $name) {
                Write-Error "SKILLS: $name frontmatter name ('$fmName') != directory name"
                $ok = $false
            }
        }
    }

    return $ok
}

# Validate the owned-here Gemini command ports: commands root holds only *.toml
# files, each with a prompt field. There is no auto-fix.
function Test-GeminiCommands {
    param([string]$Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        Write-Error "GEMINI: commands directory missing: $Root"
        return $false
    }

    $ok = $true
    foreach ($entry in Get-ChildItem -LiteralPath $Root) {
        if ($entry.PSIsContainer -or $entry.Extension -ne '.toml') {
            Write-Error "GEMINI: non-.toml entry in commands/: $($entry.Name)"
            $ok = $false
            continue
        }
        if (-not (Select-String -LiteralPath $entry.FullName -Pattern '^\s*prompt\s*=' -Quiet)) {
            Write-Error "GEMINI: $($entry.Name) has no prompt field"
            $ok = $false
        }
    }

    return $ok
}

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label missing: $Path"
    }
}

function Get-RelativeFileHashes {
    param([string]$Root)

    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
    Get-ChildItem -Recurse -File -LiteralPath $rootPath |
        Sort-Object FullName |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($rootPath.Length).TrimStart('\')
            [pscustomobject]@{
                Path = $relativePath
                Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            }
        }
}

function Test-DirectoryMirror {
    param(
        [string]$CanonRoot,
        [string]$MirrorRoot,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $MirrorRoot)) {
        Write-Error "DRIFT: $Label mirror missing"
        return $false
    }

    $canonFiles = @(Get-RelativeFileHashes -Root $CanonRoot)
    $mirrorFiles = @(Get-RelativeFileHashes -Root $MirrorRoot)
    $canonByPath = @{}
    $mirrorByPath = @{}

    foreach ($file in $canonFiles) {
        $canonByPath[$file.Path] = $file.Hash
    }
    foreach ($file in $mirrorFiles) {
        $mirrorByPath[$file.Path] = $file.Hash
    }

    $ok = $true
    foreach ($path in $canonByPath.Keys) {
        if (-not $mirrorByPath.ContainsKey($path)) {
            Write-Error "DRIFT: $Label missing mirror file: $path"
            $ok = $false
        } elseif ($canonByPath[$path] -ne $mirrorByPath[$path]) {
            Write-Error "DRIFT: $Label differs: $path"
            $ok = $false
        }
    }
    foreach ($path in $mirrorByPath.Keys) {
        if (-not $canonByPath.ContainsKey($path)) {
            Write-Error "DRIFT: $Label has extra mirror file: $path"
            $ok = $false
        }
    }

    return $ok
}

Assert-PathExists -Path $CanonPersona -Label 'Canon persona'
Assert-PathExists -Path $CanonCondensed -Label 'Canon condensed persona'
Assert-PathExists -Path $CanonMemory -Label 'Canon memory-seed'

if ($Check) {
    $mirrorOk = $true
    $skillsOk = $true
    $loopsOk = $true

    if (-not (Test-Path -LiteralPath $MirrorPersona)) {
        Write-Error 'DRIFT: codex\references\persona.md mirror missing'
        $mirrorOk = $false
    } elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $CanonPersona).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $MirrorPersona).Hash) {
        Write-Error 'DRIFT: codex\references\persona.md differs from canon'
        $mirrorOk = $false
    }

    if (-not (Test-DirectoryMirror -CanonRoot $CanonMemory -MirrorRoot $MirrorMemory -Label 'codex\references\memory-seed.example')) {
        $mirrorOk = $false
    }

    if (-not (Test-Path -LiteralPath $MirrorGemini)) {
        Write-Error 'DRIFT: gemini\references\GEMINI.md mirror missing'
        $mirrorOk = $false
    } elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $CanonCondensed).Hash -ne (Get-FileHash -Algorithm SHA256 -LiteralPath $MirrorGemini).Hash) {
        Write-Error 'DRIFT: gemini\references\GEMINI.md differs from canon (persona\CLAUDE.template.md)'
        $mirrorOk = $false
    }

    if (-not (Test-Skills -Root $SkillsRoot)) {
        Write-Error 'Fix the skill structure above (no auto-fix: skills are owned-here canon).'
        $skillsOk = $false
    }

    if (-not (Test-GeminiCommands -Root $GeminiCommandsRoot)) {
        Write-Error 'Fix the Gemini command structure above (no auto-fix: owned-here ports).'
        $skillsOk = $false
    }

    & $LoopsValidator -Root $RepoRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Fix the canonical loop contracts above.'
        $loopsOk = $false
    }

    if (-not $mirrorOk) {
        Write-Error 'Run: scripts\sync-codex-references.ps1; git add codex\references gemini\references'
    }

    if ($mirrorOk -and $skillsOk -and $loopsOk) { exit 0 } else { exit 1 }
}

& $LoopsValidator -Root $RepoRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Canonical loop contracts invalid; no mirror files were changed.'
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MirrorPersona) | Out-Null
Copy-Item -LiteralPath $CanonPersona -Destination $MirrorPersona -Force

if (Test-Path -LiteralPath $MirrorMemory) {
    Remove-Item -LiteralPath $MirrorMemory -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $MirrorMemory | Out-Null
Copy-Item -Path (Join-Path $CanonMemory '*') -Destination $MirrorMemory -Recurse -Force

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MirrorGemini) | Out-Null
Copy-Item -LiteralPath $CanonCondensed -Destination $MirrorGemini -Force

Write-Host 'Synced codex\references and gemini\references from canon (persona\ + claude-code\).'

# Ports are owned-here and cannot be regenerated; surface broken structure now.
if (-not (Test-Skills -Root $SkillsRoot)) {
    throw 'Skill structure invalid (owned-here canon, no auto-fix). Fix the files above.'
}
Write-Host 'Validated codex\skills structure.'
if (-not (Test-GeminiCommands -Root $GeminiCommandsRoot)) {
    throw 'Gemini command structure invalid (owned-here ports, no auto-fix). Fix the files above.'
}
Write-Host 'Validated gemini\commands structure.'
