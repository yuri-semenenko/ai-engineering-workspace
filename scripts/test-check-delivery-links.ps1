$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = (Get-Process -Id $PID).Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('delivery-links-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmp) | Out-Null
try {
$paths = @('scripts/check-delivery-links.ps1','claude-code/.claude/settings.example.json','claude-code/.claude/hooks/model-reminder.sh','claude-code/.claude/hooks/workflow-model-guard.sh','claude-code/.claude/statusline.sh','claude-code/.claude/skills/pr-recheck/SKILL.md','claude-code/.claude/skills/pr-review/SKILL.md','codex/skills/pr-recheck/SKILL.md','codex/skills/pr-review/SKILL.md','gemini/commands/pr-recheck.toml','gemini/commands/pr-review.toml')
foreach ($p in $paths) {
    $target = Join-Path $tmp $p
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
    [IO.File]::Copy((Join-Path $root $p), $target)
}
function Run-Check([string]$directory) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $directory 'scripts/check-delivery-links.ps1') 2>&1 | Out-String
        return @{ Code = $LASTEXITCODE; Output = $output }
    } finally { $ErrorActionPreference = $previous }
}
$actual = Run-Check $root
if ($actual.Code -ne 0) { throw "checkout failed: $($actual.Output)" }
$actual = Run-Check $tmp
if ($actual.Code -ne 0) { throw "fixture failed: $($actual.Output)" }
$hook = Join-Path $tmp 'claude-code/.claude/hooks/model-reminder.sh'
Move-Item -LiteralPath $hook -Destination "$hook.saved"
$actual = Run-Check $tmp
if ($actual.Code -eq 0 -or $actual.Output -notmatch 'references missing claude-code/.claude/hooks/model-reminder.sh') { throw "missing hook was not reported: $($actual.Output)" }
Move-Item -LiteralPath "$hook.saved" -Destination $hook
$skill = Join-Path $tmp 'codex/skills/pr-review/SKILL.md'
Move-Item -LiteralPath $skill -Destination "$skill.saved"
$actual = Run-Check $tmp
if ($actual.Code -eq 0 -or $actual.Output -notmatch 'references missing codex/skills/pr-review/SKILL.md') { throw "missing skill was not reported: $($actual.Output)" }
Move-Item -LiteralPath "$skill.saved" -Destination $skill
$reference = Join-Path $tmp 'codex/skills/pr-recheck/SKILL.md'
[IO.File]::WriteAllText($reference, ([IO.File]::ReadAllText($reference).Replace('pr-review','missing-review')))
$actual = Run-Check $tmp
if ($actual.Code -eq 0 -or $actual.Output -notmatch 'codex/skills/pr-recheck/SKILL.md does not reference pr-review') { throw "missing reference was not reported: $($actual.Output)" }
[IO.File]::WriteAllText($reference, ([IO.File]::ReadAllText($reference).Replace('missing-review','pr-review-missing')))
$actual = Run-Check $tmp
if ($actual.Code -eq 0 -or $actual.Output -notmatch 'codex/skills/pr-recheck/SKILL.md does not reference pr-review') { throw "extended skill name was accepted: $($actual.Output)" }
Write-Output 'delivery-links fixtures: missing hook, skill and reference rejected'
} finally {
    $resolved = [IO.Path]::GetFullPath($tmp)
    $prefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('delivery-links-')) {
        [IO.Directory]::Delete($resolved, $true)
    }
}
