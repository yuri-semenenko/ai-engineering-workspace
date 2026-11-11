$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$settings = Join-Path $root 'claude-code/.claude/settings.example.json'
try { $config = Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json } catch {
    [Console]::Error.WriteLine("delivery-links: cannot parse commands in $settings")
    exit 1
}
$bad = $false
if ($null -eq $config -or $null -eq $config.hooks -or $config.hooks -isnot [pscustomobject] -or
    $config.statusLine.command -isnot [string] -or -not $config.statusLine.command.StartsWith('bash ~/.claude/')) {
    [Console]::Error.WriteLine("delivery-links: local hooks and status line are required in $settings")
    exit 1
}
$commands = @()
foreach ($event in $config.hooks.PSObject.Properties) {
    if ($event.Value -isnot [array]) {
        [Console]::Error.WriteLine("delivery-links: hook event must be an array in $settings")
        exit 1
    }
    foreach ($group in $event.Value) {
        if ($group -isnot [pscustomobject] -or $group.hooks -isnot [array]) {
            [Console]::Error.WriteLine("delivery-links: hook group must contain an array in $settings")
            exit 1
        }
        foreach ($hook in $group.hooks) {
            if ($hook -isnot [pscustomobject]) {
                [Console]::Error.WriteLine("delivery-links: hook must be an object in $settings")
                exit 1
            }
            $commands += $hook.command
        }
    }
}
$localHooks = @($commands | Where-Object { $_ -is [string] -and $_.StartsWith('bash ~/.claude/') })
if ($localHooks.Count -eq 0) {
    [Console]::Error.WriteLine("delivery-links: no local hooks in $settings")
    exit 1
}
$commands += $config.statusLine.command
foreach ($command in $commands) {
    if ($command -isnot [string]) { continue }
    if ($command.Contains("`n") -or $command.Contains("`r")) {
        [Console]::Error.WriteLine("delivery-links: multiline command in $settings")
        $bad = $true; continue
    }
    if (-not $command.StartsWith('bash ~/.claude/')) { continue }
    $relative = $command.Substring('bash ~/.claude/'.Length)
    if ($relative.Contains('..') -or ($relative -cnotmatch '^hooks/[A-Za-z0-9._-]+\.sh$' -and $relative -cne 'statusline.sh')) {
        [Console]::Error.WriteLine("delivery-links: unsupported command in ${settings}: $command")
        $bad = $true; continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root "claude-code/.claude/$relative") -PathType Leaf)) {
        [Console]::Error.WriteLine("delivery-links: $settings references missing claude-code/.claude/$relative")
        $bad = $true
    }
}
$pairs = @(
    @('claude-code/.claude/skills/pr-recheck/SKILL.md','claude-code/.claude/skills/pr-review/SKILL.md','pr-review'),
    @('codex/skills/pr-recheck/SKILL.md','codex/skills/pr-review/SKILL.md','pr-review'),
    @('codex/skills/pr-review/SKILL.md','codex/skills/pr-recheck/SKILL.md','pr-recheck'),
    @('gemini/commands/pr-recheck.toml','gemini/commands/pr-review.toml','pr-review')
)
foreach ($pair in $pairs) {
    $source = Join-Path $root $pair[0]; $target = Join-Path $root $pair[1]
    $pattern = '(?<![A-Za-z0-9_-])' + [regex]::Escape($pair[2]) + '(?![A-Za-z0-9_-])'
    if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or -not [regex]::IsMatch([IO.File]::ReadAllText($source), $pattern)) {
        [Console]::Error.WriteLine("delivery-links: $($pair[0]) does not reference $($pair[2])"); $bad = $true
    }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        [Console]::Error.WriteLine("delivery-links: $($pair[0]) references missing $($pair[1])"); $bad = $true
    }
}
if ($bad) { exit 1 }
Write-Output 'delivery-links: checked Claude commands and declared review links'
