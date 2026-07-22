param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$repoRoot = (Resolve-Path -LiteralPath $Root).Path
$loopsRoot = Join-Path $repoRoot 'loops'
$skillsRoot = Join-Path $repoRoot 'claude-code\.claude\skills'
$requiredSections = @(
    '## Identity',
    '## Purpose',
    '## Scope',
    '## Inputs',
    '## Skill composition',
    '## State',
    '## Verification',
    '## Output',
    '## Limits',
    '## Human handoff',
    '## Autonomy'
)

$status = 0
$identifiers = @{}

function Fail([string]$Message) {
    Write-Error "LOOPS: $Message"
    $script:status = 1
}

if (-not (Test-Path -LiteralPath $loopsRoot -PathType Container)) {
    Write-Error "LOOPS: directory missing: $loopsRoot"
    exit 1
}
if (-not (Test-Path -LiteralPath $skillsRoot -PathType Container)) {
    Write-Error "LOOPS: canonical skills directory missing: $skillsRoot"
    exit 1
}

$loopCount = 0
foreach ($loopDir in Get-ChildItem -LiteralPath $loopsRoot) {
    if (-not $loopDir.PSIsContainer) {
        continue
    }

    $loopCount++
    $name = $loopDir.Name
    $loopMd = Join-Path $loopDir.FullName 'LOOP.md'
    foreach ($requiredFile in @('LOOP.md', 'output.md', 'state.example.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $loopDir.FullName $requiredFile) -PathType Leaf)) {
            Fail "$name missing $requiredFile"
        }
    }
    if (-not (Test-Path -LiteralPath $loopMd -PathType Leaf)) { continue }

    $content = Get-Content -Raw -LiteralPath $loopMd
    foreach ($section in $requiredSections) {
        if (-not [regex]::IsMatch($content, "(?m)^$([regex]::Escape($section))$")) {
            Fail "$name missing required section: $section"
        }
    }

    $idMatch = [regex]::Match($content, '(?m)^- \*\*Identifier:\*\* `([^`]+)`$')
    $identifier = if ($idMatch.Success) { $idMatch.Groups[1].Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($identifier)) {
        Fail "$name has no stable Identifier"
    } elseif ($identifier -ne $name) {
        Fail "$name Identifier ('$identifier') does not match directory name"
    } elseif ($identifiers.ContainsKey($identifier)) {
        Fail "duplicate Identifier: $identifier"
    } else {
        $identifiers[$identifier] = $true
    }

    $autonomyMatch = [regex]::Match($content, '(?m)^- \*\*Autonomy level:\*\* `([^`]+)`$')
    $autonomy = if ($autonomyMatch.Success) { $autonomyMatch.Groups[1].Value } else { '' }
    if ($autonomy -notin @('L0 — Documented', 'L1 — Report Only')) {
        Fail "$name declares unsupported autonomy level: $(if ($autonomy) { $autonomy } else { 'missing' })"
    }

    if (-not $content.Contains('[output.md](output.md)')) { Fail "$name does not link output.md" }
    if (-not $content.Contains('[state.example.md](state.example.md)')) { Fail "$name does not link state.example.md" }

    $skillMatches = [regex]::Matches($content, 'skills/([a-z0-9-]+)/SKILL\.md')
    if ($skillMatches.Count -eq 0) {
        Fail "$name references no canonical skills"
    } else {
        $skillMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | ForEach-Object {
            if (-not (Test-Path -LiteralPath (Join-Path $skillsRoot "$_\SKILL.md") -PathType Leaf)) {
                Fail "$name references unknown skill: $_"
            }
        }
    }

    if ($autonomy -eq 'L1 — Report Only') {
        if (-not [regex]::IsMatch($content, '(?m)^### Prohibited write and outbound actions$')) {
            Fail "$name L1 loop lacks write-action prohibition heading"
        }
        if (-not [regex]::IsMatch($content, '(?i)must not')) {
            Fail "$name L1 loop does not explicitly prohibit write actions"
        }
    }
}

if ($loopCount -eq 0) { Fail 'no loop directories found' }
if ($status -eq 0) { Write-Host "loops: $loopCount canonical loop contracts valid" }
exit $status
