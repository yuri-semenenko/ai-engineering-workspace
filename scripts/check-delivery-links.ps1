$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$settings = Join-Path $root 'claude-code/.claude/settings.example.json'
try { $config = Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json } catch {
    [Console]::Error.WriteLine("delivery-links: cannot parse commands in $settings")
    exit 1
}
$bad = $false
$commands = @($config.statusLine.command)
foreach ($event in $config.hooks.PSObject.Properties) {
    foreach ($group in $event.Value) { foreach ($hook in $group.hooks) { $commands += $hook.command } }
}
foreach ($command in $commands) {
    if ($command -isnot [string] -or -not $command.StartsWith('bash ~/.claude/')) { continue }
    $relative = $command.Substring('bash ~/.claude/'.Length)
    if ($relative.Contains('..') -or $relative.Contains(' ') -or ($relative -notmatch '^hooks/[^/\s]+\.sh$' -and $relative -ne 'statusline.sh')) {
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
