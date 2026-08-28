#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Filter,
    [string[]]$PowerShellHosts,
    [switch]$KeepSandbox,
    [string[]]$RequireChecks
)

$ErrorActionPreference = 'Stop'

# Windows execution suite for the kit's own scripts.
#
# The CI verify job runs on Linux against the .sh side. Every .sh has a .ps1
# port, and nothing exercised those ports: a broken installer, a mangled
# persona, or a CRLF'd hook script only ever surfaced on a user's machine.
# This runs the Windows entry points end to end.
#
# Every check runs against a sandbox copy of the working tree (tracked plus
# untracked-not-ignored files) under a path containing a space, with HOME
# redirected into the sandbox. Nothing here touches the real repo or ~/.claude.
#
#   scripts\test-windows.ps1                       # every check
#   scripts\test-windows.ps1 -Filter install       # only matching checks
#   scripts\test-windows.ps1 -PowerShellHosts pwsh # skip Windows PowerShell
#   scripts\test-windows.ps1 -KeepSandbox          # leave sandboxes for triage
#   scripts\test-windows.ps1 -RequireChecks a,b    # a skip of these is a failure
#
# Some checks skip when a dependency is absent. On a developer's machine that is
# correct; in CI it is silent loss of coverage, so the workflow passes
# -RequireChecks for everything the runner image is supposed to provide.
#
# Runs under Windows PowerShell 5.1 and PowerShell 7, and by default drives the
# scripts under test through both, since the README hands users the 5.1
# invocation while CI has 7. Nothing here may depend on a cmdlet or behaviour
# that exists in only one of them.
#
# Bash equivalent: the verify job in .github\workflows\ci.yml.

$OnWindows = if (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) { $IsWindows } else { $true }
if (-not $OnWindows) {
    Write-Error 'This suite tests the Windows entry points and must run on Windows.'
    exit 2
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SandboxRoot = Join-Path $env:TEMP ('aiw win tests ' + [guid]::NewGuid().ToString('N').Substring(0, 8))

# A piped wizard run answers the three axes, then takes the default (Enter) for
# each identity question.
$WizardIdentityBlanks = 12

# --- harness -----------------------------------------------------------------

$script:Checks = @()
$script:Sandboxes = @{}

function Add-Check {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Mandatory, Position = 1)][scriptblock]$Body,
        [object[]]$Arguments = @()
    )
    $script:Checks += [pscustomobject]@{ Name = $Name; Body = $Body; Arguments = $Arguments }
}

# A check fails by throwing; Skip-Check marks it skipped instead.
function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Skip-Check {
    param([string]$Reason)
    throw "SKIP:$Reason"
}

# -RequireChecks names the checks that must actually run. A requirement matches
# the check itself or its per-host copies ('install-gemini [pwsh]'), and nothing
# else: substring matching would let 'hook-scripts' also claim
# 'hook-scripts-without-jq', whose dependency state is exercised separately.
function Test-CheckMatchesRequirement {
    param([string]$Name, [string]$Requirement)
    return $Name -eq $Requirement -or
        $Name.StartsWith("$Requirement [", [StringComparison]::OrdinalIgnoreCase)
}

function Test-CheckRequired {
    param([string]$Name)
    if (-not $RequireChecks) { return $false }
    foreach ($requirement in $RequireChecks) {
        if (Test-CheckMatchesRequirement -Name $Name -Requirement $requirement) { return $true }
    }
    return $false
}

function Assert-RequiredChecksExist {
    param([object[]]$Checks, [string[]]$Requirements)
    if (-not $Requirements) { return }
    foreach ($requirement in $Requirements) {
        $matches = @($Checks | Where-Object {
            Test-CheckMatchesRequirement -Name $_.Name -Requirement $requirement
        })
        if ($matches.Count -eq 0) {
            throw "Required check '$requirement' does not match any selected check"
        }
    }
}

function Assert-FileExists {
    param([string]$Path, [string]$Label)
    Assert-That (Test-Path -LiteralPath $Path -PathType Leaf) "$Label missing: $Path"
}

function Assert-DirExists {
    param([string]$Path, [string]$Label)
    Assert-That (Test-Path -LiteralPath $Path -PathType Container) "$Label missing: $Path"
}

# SHA-256 from .NET: Get-FileHash is a module cmdlet and vanishes under a
# PSModulePath pointed at the other edition, which is exactly the failure mode
# this suite exists to catch rather than suffer from.
function Get-Sha256 {
    param([string]$Path)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path))).Replace('-', '')
    } finally {
        $sha.Dispose()
    }
}

function Assert-NoPlaceholders {
    param([string]$Path)
    $hits = @(Select-String -LiteralPath $Path -Pattern '\{\{')
    Assert-That ($hits.Count -eq 0) "unfilled placeholders in $(Split-Path -Leaf $Path): $($hits.Count) line(s)"
}

# --- sandbox -----------------------------------------------------------------

function Get-RepoFiles {
    Push-Location $RepoRoot
    try {
        $files = @(& git ls-files -c -o --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed; this suite needs git and a checkout' }
        return $files
    } finally { Pop-Location }
}

# A pristine copy of the working tree. Gitignored output (a developer's own
# persona/*.md, their settings.json) is excluded, so wizard and installer
# checks start from the same state a fresh clone would.
function New-RepoSandbox {
    param([string]$Label)

    $root = Join-Path $SandboxRoot $Label
    $repo = Join-Path $root 'repo'
    $fakeHome = Join-Path $root 'fake home'
    New-Item -ItemType Directory -Force -Path $repo, $fakeHome | Out-Null

    foreach ($rel in (Get-RepoFiles)) {
        $src = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { continue }
        $dst = Join-Path $repo ($rel -replace '/', '\')
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }

    return [pscustomobject]@{ Root = $root; Repo = $repo; Home = $fakeHome }
}

# One shared sandbox per host, walked in the order CI installs things: the
# persona wizard runs before the installers that consume its output.
function Get-Sandbox {
    param([string]$Key)
    if (-not $script:Sandboxes.ContainsKey($Key)) {
        $script:Sandboxes[$Key] = New-RepoSandbox -Label $Key
    }
    return $script:Sandboxes[$Key]
}

# --- running a .ps1 under a given host --------------------------------------

function Format-Argument {
    param([string]$Value)
    if ($Value -match '[\s"]') { return '"' + ($Value -replace '"', '\"') + '"' }
    return $Value
}

# Runs a script in a child process: $HOME is read-only in-process, stdin needs
# to be pipeable, and a hang has to fail rather than block CI.
#
# Built on ProcessStartInfo rather than Start-Process because Windows
# PowerShell's Start-Process -PassThru does not reliably surface a child's exit
# code, and a suite that cannot read exit codes cannot fail. The child's
# environment is built here too, so the parent's own environment is never
# mutated.
function Invoke-Ps1 {
    param(
        [Parameter(Mandatory)][string]$HostExe,
        [Parameter(Mandatory)][string]$Script,
        [string[]]$ScriptArgs = @(),
        [string]$HomeDir,
        [string[]]$StdinLines,
        [hashtable]$EnvVars = @{},
        [int]$TimeoutSec = 120
    )

    $argLine = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Format-Argument $Script))
    foreach ($a in $ScriptArgs) { $argLine += (Format-Argument $a) }

    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $HostExe
    $psi.Arguments = ($argLine -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true

    # Let the child host compute its own default module path. Inheriting
    # PowerShell 7's PSModulePath makes Windows PowerShell resolve the 7.x core
    # modules and lose cmdlets it does ship (Get-FileHash), which would look
    # like a bug in the script under test.
    [void]$psi.EnvironmentVariables.Remove('PSModulePath')
    if ($HomeDir) {
        New-Item -ItemType Directory -Force -Path $HomeDir | Out-Null
        $full = (Resolve-Path -LiteralPath $HomeDir).Path
        $psi.EnvironmentVariables['USERPROFILE'] = $full
        $psi.EnvironmentVariables['HOMEDRIVE'] = $full.Substring(0, 2)
        $psi.EnvironmentVariables['HOMEPATH'] = $full.Substring(2)
    }
    foreach ($name in $EnvVars.Keys) {
        $psi.EnvironmentVariables[$name] = [string]$EnvVars[$name]
    }

    $proc = [Diagnostics.Process]::Start($psi)
    try {
        if ($StdinLines) {
            foreach ($line in $StdinLines) { $proc.StandardInput.WriteLine($line) }
        }
        $proc.StandardInput.Close()

        # Read asynchronously before waiting: a child that fills the pipe
        # buffer while we block on exit would deadlock.
        $stdout = $proc.StandardOutput.ReadToEndAsync()
        $stderr = $proc.StandardError.ReadToEndAsync()
        if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
            try { $proc.Kill() } catch { }
            return [pscustomobject]@{ ExitCode = -1; Output = 'TIMEOUT'; TimedOut = $true }
        }
        $text = ($stdout.Result + "`n" + $stderr.Result).Trim()
        $proc.WaitForExit()
        return [pscustomobject]@{ ExitCode = $proc.ExitCode; Output = $text; TimedOut = $false }
    } finally {
        $proc.Dispose()
    }
}

function Assert-Ps1Succeeded {
    param($Result, [string]$Label)
    if ($Result.TimedOut) { throw "$Label timed out (likely waiting on interactive input)" }
    Assert-That ($Result.ExitCode -eq 0) "$Label exited $($Result.ExitCode): $($Result.Output)"
}

# Git for Windows and Cygwin both accept a drive-letter path with forward
# slashes, unlike their two different POSIX mount prefixes.
function ConvertTo-BashPath {
    param([string]$Path)
    return ((Resolve-Path -LiteralPath $Path).Path -replace '\\', '/')
}

# --- persona helpers ---------------------------------------------------------

function Get-RecommendedSkills {
    param([string]$Path)
    $names = @()
    $inSection = $false
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^## Recommended for your profile') { $inSection = $true; continue }
        if ($inSection -and $line -match '^## ') { break }
        if ($inSection -and $line -match '^- (.+)$') { $names += $Matches[1].Trim() }
    }
    return $names
}

function Get-SkillCatalog {
    param([string]$RepoPath)
    return @(Get-ChildItem -Directory -LiteralPath (Join-Path $RepoPath 'claude-code\.claude\skills') |
        Select-Object -ExpandProperty Name)
}

# Every installer prefers the wizard's filled persona and falls back to the
# committed template mirror, placeholders and all. CI generates the persona
# before it installs anything; make that a stated precondition so a single
# check run under -Filter behaves the same as a full run.
function Initialize-Persona {
    param([string]$HostExe, $Sandbox)

    if (Test-Path -LiteralPath (Join-Path $Sandbox.Repo 'persona\CLAUDE.md')) { return }
    $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $Sandbox.Repo 'scripts\create-persona.ps1') -ScriptArgs @('-Defaults')
    Assert-Ps1Succeeded $r 'create-persona.ps1 -Defaults (installer precondition)'
}

# --- host resolution ---------------------------------------------------------

$candidates = if ($PowerShellHosts) { $PowerShellHosts } else { @('pwsh', 'powershell') }
$Hosts = @($candidates | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue })
if ($Hosts.Count -eq 0) {
    Write-Error "No PowerShell host found on PATH (looked for: $($candidates -join ', '))"
    exit 2
}
$PrimaryHost = $Hosts[0]

# --- checks: static guards ---------------------------------------------------

Add-Check 'ps1-syntax' {
    # Mirror of the bash -n step in CI, for the PowerShell ports.
    $bad = @()
    foreach ($rel in (Get-RepoFiles | Where-Object { $_ -like '*.ps1' })) {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $RepoRoot ($rel -replace '/', '\')), [ref]$null, [ref]$errors)
        if ($errors.Count -gt 0) { $bad += "$rel ($($errors[0].Message))" }
    }
    Assert-That ($bad.Count -eq 0) "parse errors: $($bad -join '; ')"
}

Add-Check 'sh-line-endings' {
    # .gitattributes pins *.sh to LF. A CRLF checkout breaks every hook and
    # installer the moment a Windows user runs it under bash ($'\r': not found).
    $bad = @()
    $shellFiles = Get-RepoFiles | Where-Object { $_ -like '*.sh' -or $_ -eq 'scripts/hooks/pre-commit' }
    foreach ($rel in $shellFiles) {
        $path = Join-Path $RepoRoot ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        if ([IO.File]::ReadAllBytes($path) -contains 13) { $bad += $rel }
    }
    Assert-That ($bad.Count -eq 0) "CR bytes in shell scripts (must stay LF): $($bad -join ', ')"
}

Add-Check 'require-checks-contract' {
    $checks = @(
        [pscustomobject]@{ Name = 'hook-scripts' }
        [pscustomobject]@{ Name = 'install-gemini [pwsh]' }
    )
    Assert-That (Test-CheckMatchesRequirement -Name 'hook-scripts' -Requirement 'hook-scripts') 'exact required check did not match'
    Assert-That (Test-CheckMatchesRequirement -Name 'install-gemini [pwsh]' -Requirement 'install-gemini') 'per-host required check did not match'
    Assert-That (-not (Test-CheckMatchesRequirement -Name 'hook-scripts-without-jq' -Requirement 'hook-scripts')) 'required check matched a neighbouring name'

    $unknownError = ''
    try {
        Assert-RequiredChecksExist -Checks $checks -Requirements @('does-not-exist')
    } catch {
        $unknownError = $_.Exception.Message
    }
    Assert-That ($unknownError -eq "Required check 'does-not-exist' does not match any selected check") 'unknown required check was accepted'
}

Add-Check 'model-tier-fields' {
    # Both CI jobs run the ADR-0012 guard and its regression fixtures through
    # one script. This used to be a hand-written PowerShell port of the same
    # grep, and the two copies had already drifted into matching YAML only, so
    # there is no port any more: run the real thing through bash, which this
    # suite already needs for the hooks.
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Skip-Check 'no bash on PATH (Git for Windows provides it)'
    }
    $test = ConvertTo-BashPath (Join-Path $RepoRoot 'scripts\test-check-model-tiers.sh')
    $out = (& bash $test 2>&1 | Out-String).Trim()
    Assert-That ($LASTEXITCODE -eq 0) "test-check-model-tiers.sh exited $LASTEXITCODE : $out"
}

# --- checks: sync / drift guard ---------------------------------------------

foreach ($hostExe in $Hosts) {
    Add-Check "sync-check [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $sb.Repo 'scripts\sync-codex-references.ps1') -ScriptArgs @('-Check')
        Assert-Ps1Succeeded $r 'sync-codex-references.ps1 -Check'
    }
}

Add-Check 'sync-write-idempotent' {
    # The write path must be a no-op on a synced tree: if it rewrote the mirror
    # with different line endings, every Windows user would see phantom drift.
    $sb = Get-Sandbox $PrimaryHost
    $mirrors = @(
        (Join-Path $sb.Repo 'codex\references\persona.md'),
        (Join-Path $sb.Repo 'gemini\references\GEMINI.md')
    )
    $mirrors += @(Get-ChildItem -Recurse -File -LiteralPath (Join-Path $sb.Repo 'codex\references\memory-seed.example') |
        Select-Object -ExpandProperty FullName)
    $before = @{}
    foreach ($m in $mirrors) {
        Assert-FileExists $m 'mirror'
        $before[$m] = Get-Sha256 -Path $m
    }

    Assert-Ps1Succeeded (Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'scripts\sync-codex-references.ps1')) 'sync-codex-references.ps1'

    foreach ($m in $mirrors) {
        Assert-FileExists $m 'mirror after sync'
        Assert-That ((Get-Sha256 -Path $m) -eq $before[$m]) "sync rewrote $(Split-Path -Leaf $m) (line-ending drift?)"
    }
    Assert-Ps1Succeeded (Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'scripts\sync-codex-references.ps1') -ScriptArgs @('-Check')) 'sync -Check after write'
}

# --- checks: persona wizard --------------------------------------------------

foreach ($hostExe in $Hosts) {
    Add-Check "wizard-defaults [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $sb.Repo 'scripts\create-persona.ps1') -ScriptArgs @('-Defaults')
        Assert-Ps1Succeeded $r 'create-persona.ps1 -Defaults'

        foreach ($name in 'persona.md', 'CLAUDE.md', 'recommended-skills.md', 'copilot-instructions.md') {
            $path = Join-Path $sb.Repo "persona\$name"
            Assert-FileExists $path 'wizard output'
            Assert-NoPlaceholders $path
        }

        # The templates carry non-ASCII punctuation, and a host whose default
        # encoding mangles it would ship a persona full of U+FFFD or cp1252
        # gibberish. Compare against the template minus its leading HTML
        # comment, which the wizard strips on the way out.
        foreach ($pair in @(, @('CLAUDE.template.md', 'CLAUDE.md')) + @(, @('persona.template.md', 'persona.md'))) {
            $template = [IO.File]::ReadAllText((Join-Path $sb.Repo "persona\$($pair[0])"), [Text.Encoding]::UTF8)
            $generated = [IO.File]::ReadAllText((Join-Path $sb.Repo "persona\$($pair[1])"), [Text.Encoding]::UTF8)
            $body = [regex]::Replace($template, '(?ms)^<!--.*?-->\r?\n', '')

            $expected = ([regex]::Matches($body, '[^\x00-\x7F]')).Count
            $actual = ([regex]::Matches($generated, '[^\x00-\x7F]')).Count
            Assert-That ($actual -ge $expected) "$($pair[1]) kept $actual of the template's $expected non-ASCII chars"

            $known = @{}
            foreach ($c in $template.ToCharArray()) { $known[$c] = $true }
            $strange = @([regex]::Matches($generated, '[^\x00-\x7F]') |
                ForEach-Object { $_.Value } |
                Sort-Object -Unique |
                Where-Object { -not $known.ContainsKey([char]$_) })
            Assert-That ($strange.Count -eq 0) "$($pair[1]) has characters absent from the template (encoding lost): $($strange -join ' ')"
        }

        $catalog = Get-SkillCatalog $sb.Repo
        $recommended = Get-RecommendedSkills (Join-Path $sb.Repo 'persona\recommended-skills.md')
        Assert-That ($recommended.Count -gt 0) 'recommended-skills.md lists no skills'
        $unknown = @($recommended | Where-Object { $catalog -notcontains $_ })
        Assert-That ($unknown.Count -eq 0) "recommends skills that do not ship: $($unknown -join ', ')"
    }
}

Add-Check 'wizard-profile-matrix' {
    # Windows port of check-recommended-skills.sh: across every profile, the
    # recommended-skills mapping may only name skills that ship. The mapping is
    # duplicated in both wizards, so this is where a one-sided edit surfaces.
    # Driven through the environment overrides, like the bash guard.
    $sb = New-RepoSandbox -Label 'wizard matrix'
    $catalog = Get-SkillCatalog $sb.Repo
    $wizard = Join-Path $sb.Repo 'scripts\create-persona.ps1'
    $recPath = Join-Path $sb.Repo 'persona\recommended-skills.md'
    $failures = @()

    foreach ($discipline in 'frontend', 'fullstack') {
        foreach ($seniority in 'mid', 'senior', 'staff', 'principal') {
            foreach ($workflow in 'delivery-focused', 'architecture-focused', 'review-focused', 'learning-focused') {
                $profile = "$discipline/$seniority/$workflow"
                Remove-Item -LiteralPath $recPath -Force -ErrorAction SilentlyContinue
                $r = Invoke-Ps1 -HostExe $PrimaryHost -Script $wizard -ScriptArgs @('-Defaults') -TimeoutSec 60 `
                    -EnvVars @{ DISCIPLINE = $discipline; SENIORITY = $seniority; WORKFLOW = $workflow }
                if ($r.TimedOut -or $r.ExitCode -ne 0) {
                    $failures += "[$profile] wizard exited $($r.ExitCode): $($r.Output)"
                    continue
                }
                if (-not (Test-Path -LiteralPath $recPath)) {
                    $failures += "[$profile] wrote no recommended-skills.md"
                    continue
                }
                $expectedHeader = "Profile: discipline=$discipline, seniority=$seniority, workflow=$workflow."
                if (@(Select-String -LiteralPath $recPath -Pattern ([regex]::Escape($expectedHeader))).Count -eq 0) {
                    $failures += "[$profile] the environment overrides were ignored"
                }
                $unknown = @(Get-RecommendedSkills $recPath | Where-Object { $catalog -notcontains $_ })
                if ($unknown.Count -gt 0) { $failures += "[$profile] recommends unknown skill(s): $($unknown -join ', ')" }
            }
        }
    }

    Assert-That ($failures.Count -eq 0) ($failures -join '; ')
}

Add-Check 'wizard-interactive' {
    # The prompts themselves: -Defaults and the environment overrides both skip
    # Read-Host, so nothing else here covers the path a user actually walks.
    $sb = New-RepoSandbox -Label 'wizard interactive'
    $answers = @('frontend', 'principal', 'review-focused') + @('Staff Engineer') + @('') * ($WizardIdentityBlanks - 1)
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'scripts\create-persona.ps1') -StdinLines $answers -TimeoutSec 60
    Assert-Ps1Succeeded $r 'create-persona.ps1 (answers piped to the prompts)'

    $recPath = Join-Path $sb.Repo 'persona\recommended-skills.md'
    Assert-FileExists $recPath 'recommended-skills.md'
    Assert-That (@(Select-String -LiteralPath $recPath -Pattern 'discipline=frontend, seniority=principal, workflow=review-focused').Count -eq 1) `
        'piped answers did not reach the profile header'
    Assert-That (@(Select-String -LiteralPath (Join-Path $sb.Repo 'persona\persona.md') -Pattern 'Staff Engineer').Count -ge 1) `
        'a typed identity answer was dropped'
}

# --- checks: installers ------------------------------------------------------

foreach ($hostExe in $Hosts) {

    Add-Check "install-claude-copy [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        Initialize-Persona -HostExe $HostExe -Sandbox $sb
        $fakeHome = Join-Path $sb.Home 'claude'
        $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $sb.Repo 'claude-code\scripts\install.windows.ps1') -HomeDir $fakeHome
        Assert-Ps1Succeeded $r 'claude install.windows.ps1 (Copy)'

        $target = Join-Path $fakeHome '.claude'
        Assert-DirExists $target 'installed .claude'
        Assert-FileExists (Join-Path $target 'CLAUDE.md') 'installed CLAUDE.md'
        Assert-FileExists (Join-Path $target 'settings.json') 'seeded settings.json'
        Assert-FileExists (Join-Path $target 'statusline.sh') 'statusline'
        Assert-FileExists (Join-Path $target 'hooks\model-reminder.sh') 'hook'
        Assert-FileExists (Join-Path $fakeHome 'persona.md') 'full persona at home root'
        Assert-NoPlaceholders (Join-Path $target 'CLAUDE.md')

        # The tree has to arrive whole, not just its top-level files.
        $installedSkills = @(Get-ChildItem -Directory -LiteralPath (Join-Path $target 'skills')).Count
        $sourceSkills = (Get-SkillCatalog $sb.Repo).Count
        Assert-That ($installedSkills -eq $sourceSkills) "installed $installedSkills of $sourceSkills skills"
        Assert-FileExists (Join-Path $target 'agents\independent-review.md') 'independent-review agent'

        # A machine without jq runs the hooks as no-ops, so the installer has to
        # say so rather than report a clean install.
        if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
            Assert-That ($r.Output -match 'jq') 'jq is missing but the installer did not warn about it'
        }
    }

    Add-Check "install-codex [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        Initialize-Persona -HostExe $HostExe -Sandbox $sb
        $fakeHome = Join-Path $sb.Home 'codex'
        $codexHome = Join-Path $fakeHome '.codex'
        $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $sb.Repo 'codex\scripts\install.windows.ps1') -ScriptArgs @('-CodexHome', $codexHome) -HomeDir $fakeHome
        Assert-Ps1Succeeded $r 'codex install.windows.ps1'
        Assert-That ($r.Output -match 'Persona: installed from') "installer did not report the filled persona: $($r.Output)"

        Assert-FileExists (Join-Path $codexHome 'AGENTS.md') 'AGENTS.md'
        Assert-FileExists (Join-Path $codexHome 'references\persona.md') 'installed persona'
        Assert-NoPlaceholders (Join-Path $codexHome 'references\persona.md')
        Assert-DirExists (Join-Path $codexHome 'references\memory-seed.example') 'memory seed'
        $skills = @(Get-ChildItem -Directory -LiteralPath (Join-Path $codexHome 'skills'))
        $sourceSkills = @(Get-ChildItem -Directory -LiteralPath (Join-Path $sb.Repo 'codex\skills'))
        Assert-That ($skills.Count -eq $sourceSkills.Count) "installed $($skills.Count) of $($sourceSkills.Count) codex skills"
        foreach ($skill in $skills) {
            Assert-FileExists (Join-Path $skill.FullName 'SKILL.md') "$($skill.Name) SKILL.md"
            Assert-FileExists (Join-Path $skill.FullName 'agents\openai.yaml') "$($skill.Name) agent manifest"
        }
    }

    Add-Check "install-copilot [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        Initialize-Persona -HostExe $HostExe -Sandbox $sb
        $fakeHome = Join-Path $sb.Home 'copilot'
        $workspace = Join-Path $sb.Home 'copilot workspace'
        $r = Invoke-Ps1 -HostExe $HostExe -Script (Join-Path $sb.Repo 'copilot\scripts\install.windows.ps1') `
            -ScriptArgs @('-TargetHome', $fakeHome, '-WorkspacePath', $workspace) -HomeDir $fakeHome
        Assert-Ps1Succeeded $r 'copilot install.windows.ps1'
        Assert-That ($r.Output -match 'Persona: installed from') "installer did not report the filled persona: $($r.Output)"
        # The workspace was installed, so the hint about skipping it must not fire.
        Assert-That ($r.Output -notmatch 'For repository-level setup') 'installer offered workspace setup it had already done'

        $instructions = Join-Path $fakeHome '.copilot\copilot-instructions.md'
        Assert-FileExists $instructions 'copilot-instructions.md'
        Assert-NoPlaceholders $instructions
        $sourceCount = @(Get-ChildItem -LiteralPath (Join-Path $sb.Repo 'copilot\home\.copilot\instructions') -Filter '*.instructions.md').Count
        $installed = @(Get-ChildItem -LiteralPath (Join-Path $fakeHome '.copilot\instructions') -Filter '*.instructions.md').Count
        Assert-That ($installed -eq $sourceCount) "installed $installed of $sourceCount instruction files"

        # Repository-level setup, the same surface the Linux CI job asserts.
        Assert-FileExists (Join-Path $workspace 'AGENTS.md') 'workspace AGENTS.md'
        Assert-FileExists (Join-Path $workspace '.github\copilot-instructions.md') 'workspace copilot-instructions.md'
        $template = Join-Path $sb.Repo 'copilot\workspace-template\.github'
        foreach ($set in @(, @('instructions', '*.instructions.md')) + @(, @('prompts', '*.prompt.md'))) {
            $expected = @(Get-ChildItem -LiteralPath (Join-Path $template $set[0]) -Filter $set[1]).Count
            $actual = @(Get-ChildItem -LiteralPath (Join-Path $workspace ".github\$($set[0])") -Filter $set[1] -ErrorAction SilentlyContinue).Count
            Assert-That ($actual -eq $expected) "workspace $($set[0]): installed $actual of $expected"
        }
    }

    Add-Check "install-gemini [$hostExe]" -Arguments @($hostExe) {
        param([string]$HostExe)
        $sb = Get-Sandbox $HostExe
        Initialize-Persona -HostExe $HostExe -Sandbox $sb
        $fakeHome = Join-Path $sb.Home 'gemini'
        $geminiHome = Join-Path $fakeHome '.gemini'
        $installer = Join-Path $sb.Repo 'gemini\scripts\install.windows.ps1'
        $r = Invoke-Ps1 -HostExe $HostExe -Script $installer -ScriptArgs @('-GeminiHome', $geminiHome) -HomeDir $fakeHome
        Assert-Ps1Succeeded $r 'gemini install.windows.ps1'
        Assert-That ($r.Output -match 'Persona: installed from') "installer did not report the filled persona: $($r.Output)"

        Assert-FileExists (Join-Path $geminiHome 'GEMINI.md') 'GEMINI.md'
        Assert-NoPlaceholders (Join-Path $geminiHome 'GEMINI.md')
        Assert-FileExists (Join-Path $geminiHome 'settings.json') 'settings.json'
        $sourceCount = @(Get-ChildItem -LiteralPath (Join-Path $sb.Repo 'gemini\commands') -Filter '*.toml').Count
        $installed = @(Get-ChildItem -LiteralPath (Join-Path $geminiHome 'commands') -Filter '*.toml').Count
        Assert-That ($installed -eq $sourceCount) "installed $installed of $sourceCount commands"

        # Re-running must not clobber a user's edited settings.
        $marker = '{ "sentinel": true }'
        Set-Content -LiteralPath (Join-Path $geminiHome 'settings.json') -Value $marker -NoNewline
        Assert-Ps1Succeeded (Invoke-Ps1 -HostExe $HostExe -Script $installer -ScriptArgs @('-GeminiHome', $geminiHome) -HomeDir $fakeHome) 'gemini install (re-run)'
        $kept = (Get-Content -LiteralPath (Join-Path $geminiHome 'settings.json') -Raw).Trim()
        Assert-That ($kept -eq $marker) 'a second run overwrote existing settings.json'
    }
}

Add-Check 'install-claude-rerun' {
    # A re-run must back the old tree up rather than nest a copy inside it, and
    # back-to-back runs must not collide on the backup name: the timestamp there
    # has second resolution, so it carries a random tail.
    $sb = New-RepoSandbox -Label 'claude rerun'
    $fakeHome = Join-Path $sb.Home 'claude'
    $installer = Join-Path $sb.Repo 'claude-code\scripts\install.windows.ps1'
    Initialize-Persona -HostExe $PrimaryHost -Sandbox $sb
    foreach ($pass in 1, 2, 3) {
        Assert-Ps1Succeeded (Invoke-Ps1 -HostExe $PrimaryHost -Script $installer -HomeDir $fakeHome) "install pass $pass"
    }

    Assert-FileExists (Join-Path $fakeHome '.claude\CLAUDE.md') 'reinstalled CLAUDE.md'
    Assert-That (-not (Test-Path -LiteralPath (Join-Path $fakeHome '.claude\.claude'))) 'a re-run nested .claude inside itself'
    $backups = @(Get-ChildItem -LiteralPath $fakeHome -Filter '.claude.backup.*' -Force)
    Assert-That ($backups.Count -eq 2) "expected 2 backups after 3 installs, found $($backups.Count)"
}

Add-Check 'install-claude-symlink' {
    $sb = New-RepoSandbox -Label 'claude symlink'
    $fakeHome = Join-Path $sb.Home 'claude'
    Initialize-Persona -HostExe $PrimaryHost -Sandbox $sb
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'claude-code\scripts\install.windows.ps1') -ScriptArgs @('-Mode', 'Symlink') -HomeDir $fakeHome
    if ($r.ExitCode -ne 0) {
        if ($r.Output -match 'Could not create symlink') {
            Skip-Check 'unprivileged shell: symlink mode needs Administrator or Developer Mode, and the installer says so (Copy mode is the default)'
        }
        throw "symlink install exited $($r.ExitCode): $($r.Output)"
    }

    $target = Join-Path $fakeHome '.claude'
    $item = Get-Item -LiteralPath $target -Force
    Assert-That ([bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) '.claude is not a link'
    Assert-FileExists (Join-Path $target 'CLAUDE.md') 'CLAUDE.md through the link'
    # Drop the link before the sandbox is cleaned up, so no recursive delete
    # can walk through it.
    [IO.Directory]::Delete($target)
}

Add-Check 'install-claude-first-run' {
    # No persona yet: the installer must drive the wizard to completion instead
    # of stalling on a prompt. Untested on the Linux side, where CI always has
    # a persona by the time the installer runs.
    $sb = New-RepoSandbox -Label 'claude first run'
    $fakeHome = Join-Path $sb.Home 'claude'
    Assert-That (-not (Test-Path -LiteralPath (Join-Path $sb.Repo 'persona\CLAUDE.md'))) 'sandbox was not pristine'

    $answers = @('fullstack', 'staff', 'architecture-focused') + @('') * $WizardIdentityBlanks
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'claude-code\scripts\install.windows.ps1') `
        -HomeDir $fakeHome -StdinLines $answers -TimeoutSec 90
    Assert-Ps1Succeeded $r 'first-run install (wizard, then install)'
    Assert-FileExists (Join-Path $sb.Repo 'persona\CLAUDE.md') 'wizard output'
    Assert-FileExists (Join-Path $fakeHome '.claude\CLAUDE.md') 'installed CLAUDE.md'
    Assert-NoPlaceholders (Join-Path $fakeHome '.claude\CLAUDE.md')
}

Add-Check 'install-unfilled-persona' {
    # Codex, Gemini and Copilot never run the wizard: they fall back to the
    # committed mirrors, which ship {{PLACEHOLDERS}} the tool then reads as
    # literal text. That fallback used to be silent and end on a clean
    # "installed" summary, so assert on what each installer says, not only on
    # what it wrote. New-RepoSandbox excludes gitignored wizard output and
    # Initialize-Persona is deliberately not called here.
    $sb = New-RepoSandbox -Label 'unfilled persona'
    Assert-That (-not (Test-Path -LiteralPath (Join-Path $sb.Repo 'persona\persona.md'))) 'sandbox was not pristine'

    # A home per case: a shared one lets an earlier run's state decide a later
    # assertion.
    $codexHome = Join-Path $sb.Home 'codex'
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'codex\scripts\install.windows.ps1') `
        -ScriptArgs @('-CodexHome', (Join-Path $codexHome '.codex')) -HomeDir $codexHome
    Assert-Ps1Succeeded $r 'codex install without a persona'
    Assert-That ($r.Output -match 'Persona: TEMPLATE ONLY') "codex installer did not report the unfilled persona: $($r.Output)"
    Assert-That ($r.Output -notmatch 'Persona: installed from') 'codex installer claimed a persona it did not install'

    $geminiHome = Join-Path $sb.Home 'gemini'
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'gemini\scripts\install.windows.ps1') `
        -ScriptArgs @('-GeminiHome', (Join-Path $geminiHome '.gemini')) -HomeDir $geminiHome
    Assert-Ps1Succeeded $r 'gemini install without a persona'
    Assert-That ($r.Output -match 'Persona: TEMPLATE ONLY') "gemini installer did not report the unfilled persona: $($r.Output)"

    $copilotHome = Join-Path $sb.Home 'copilot'
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'copilot\scripts\install.windows.ps1') `
        -ScriptArgs @('-TargetHome', $copilotHome) -HomeDir $copilotHome
    Assert-Ps1Succeeded $r 'copilot install without a persona'
    Assert-That ($r.Output -match 'Persona: TEMPLATE ONLY') "copilot installer did not report the unfilled persona: $($r.Output)"
    Assert-That ($r.Output -match 'For repository-level setup') 'copilot installer did not mention the workspace half it skipped'

    # A persona that exists but is half-filled is a different cause with the
    # same cost, and it needs a different fix than "run the wizard".
    Set-Content -LiteralPath (Join-Path $sb.Repo 'persona\persona.md') -Value 'Role: {{ROLE}}'
    $incompleteHome = Join-Path $sb.Home 'codex incomplete'
    $r = Invoke-Ps1 -HostExe $PrimaryHost -Script (Join-Path $sb.Repo 'codex\scripts\install.windows.ps1') `
        -ScriptArgs @('-CodexHome', (Join-Path $incompleteHome '.codex')) -HomeDir $incompleteHome
    Assert-Ps1Succeeded $r 'codex install with a half-filled persona'
    Assert-That ($r.Output -match 'Persona: INCOMPLETE') "codex installer did not report the half-filled persona: $($r.Output)"
    Assert-That ($r.Output -notmatch 'TEMPLATE ONLY') 'a half-filled persona was reported as an untouched template'
}

# --- checks: the shell parts a Windows user still runs ----------------------

Add-Check 'hook-scripts' {
    # statusline.sh and the hooks are the part of the kit Windows cannot run
    # natively: Claude Code shells out to bash, and they parse stdin with jq.
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Skip-Check 'no bash on PATH (Git for Windows provides it)'
    }
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Skip-Check 'no jq on PATH: the statusline and every guardrail hook in settings.example.json parse stdin with jq and degrade to a silent no-op without it'
    }

    $sb = Get-Sandbox $PrimaryHost
    $statusline = ConvertTo-BashPath (Join-Path $sb.Repo 'claude-code\.claude\statusline.sh')
    $payload = '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"' + (ConvertTo-BashPath $sb.Repo) + '"}}'
    $rendered = ($payload | & bash $statusline 2>&1 | Out-String).Trim()
    Assert-That ($LASTEXITCODE -eq 0) "statusline.sh exited $LASTEXITCODE : $rendered"
    Assert-That ($rendered -match 'Opus') "statusline did not render the model name: '$rendered'"
    Assert-That ($rendered -match 'repo') "statusline did not render the directory: '$rendered'"

    $reminder = ConvertTo-BashPath (Join-Path $sb.Repo 'claude-code\.claude\hooks\model-reminder.sh')
    $fired = ('{"prompt":"/rfc new cache layer"}' | & bash $reminder 2>&1 | Out-String)
    Assert-That ($LASTEXITCODE -eq 0) "model-reminder.sh exited $LASTEXITCODE : $fired"
    Assert-That ($fired -match 'model-reminder hook') 'model-reminder.sh did not fire on /rfc'
    $quiet = ('{"prompt":"just a question"}' | & bash $reminder 2>&1 | Out-String)
    Assert-That ([string]::IsNullOrWhiteSpace($quiet)) "model-reminder.sh fired on an ordinary prompt: $quiet"
}

Add-Check 'hook-scripts-without-jq' {
    # The other half of the pair above: hide jq inside each Bash invocation so
    # the degraded path runs even when the host (including CI) has jq installed.
    # Silent guardrails are worse than absent ones.
    $bashCommand = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bashCommand) {
        Skip-Check 'no bash on PATH (Git for Windows provides it)'
    }
    $bashWithoutJq = 'PATH=/usr/bin:/bin; export PATH; exec bash "$@"'

    $sb = Get-Sandbox $PrimaryHost
    $statusline = ConvertTo-BashPath (Join-Path $sb.Repo 'claude-code\.claude\statusline.sh')
    $rendered = ('{"model":{"display_name":"Opus"}}' | & $bashCommand.Source -c $bashWithoutJq bash $statusline 2>&1 | Out-String).Trim()
    Assert-That ($rendered -match 'jq') "statusline hid the missing dependency instead of naming it: '$rendered'"

    # The notice is once per session, and the marker that enforces that lives in
    # the temp directory. Point it at this sandbox: a marker left in the real
    # temp directory would silence the notice on the suite's next run, and the
    # assertion below would fail for a reason that has nothing to do with the
    # hook.
    $markerDir = Join-Path $sb.Root 'hook temp'
    New-Item -ItemType Directory -Force -Path $markerDir | Out-Null
    $previousTmp = $env:TMPDIR
    $env:TMPDIR = (ConvertTo-BashPath $markerDir) + '/'
    try {
        $reminder = ConvertTo-BashPath (Join-Path $sb.Repo 'claude-code\.claude\hooks\model-reminder.sh')
        $notice = ('{"session_id":"suite","prompt":"anything"}' | & $bashCommand.Source -c $bashWithoutJq bash $reminder 2>&1 | Out-String)
        Assert-That ($LASTEXITCODE -eq 0) "model-reminder.sh exited $LASTEXITCODE : $notice"
        Assert-That ($notice -match 'jq is not on PATH') 'the prompt hook did not report that the guardrails are inactive'

        $repeat = ('{"session_id":"suite","prompt":"anything else"}' | & $bashCommand.Source -c $bashWithoutJq bash $reminder 2>&1 | Out-String)
        Assert-That ([string]::IsNullOrWhiteSpace($repeat)) "the setup notice repeated within one session: $repeat"

        $other = ('{"session_id":"another","prompt":"anything"}' | & $bashCommand.Source -c $bashWithoutJq bash $reminder 2>&1 | Out-String)
        Assert-That ($other -match 'jq is not on PATH') 'a new session did not get the setup notice'
    } finally {
        # Windows does not normally set TMPDIR, so restoring a null means
        # removing the variable rather than blanking it.
        if ($null -eq $previousTmp) {
            Remove-Item Env:TMPDIR -ErrorAction SilentlyContinue
        } else {
            $env:TMPDIR = $previousTmp
        }
    }
}

# --- run ---------------------------------------------------------------------

$selected = @($script:Checks | Where-Object { -not $Filter -or $_.Name -like "*$Filter*" })
if ($selected.Count -eq 0) {
    Write-Error "No checks match filter '$Filter'"
    exit 2
}
Assert-RequiredChecksExist -Checks $selected -Requirements $RequireChecks

Write-Host "Windows script suite: $($selected.Count) check(s), hosts: $($Hosts -join ', ')"
Write-Host "Sandbox root: $SandboxRoot"
Write-Host ''

New-Item -ItemType Directory -Force -Path $SandboxRoot | Out-Null
$results = @()
foreach ($check in $selected) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $status = 'PASS'
    $detail = ''
    try {
        & $check.Body @($check.Arguments)
    } catch {
        $message = $_.Exception.Message
        if ($message -like 'SKIP:*') {
            $status = 'SKIP'
            $detail = $message.Substring(5)
            # A skip is missing coverage wearing a pass. Named checks are the
            # ones whose environment CI controls, so there a skip is a failure.
            if (Test-CheckRequired $check.Name) {
                $status = 'FAIL'
                $detail = "required check skipped: $detail"
            }
        } else {
            $status = 'FAIL'
            $detail = $message
        }
    }
    $sw.Stop()
    $results += [pscustomobject]@{ Name = $check.Name; Status = $status; Detail = $detail; Ms = $sw.ElapsedMilliseconds }

    $line = '[{0}] {1} ({2} ms)' -f $status, $check.Name, $sw.ElapsedMilliseconds
    if ($detail) { $line += "`n       $detail" }
    Write-Host $line -ForegroundColor @{ PASS = 'Green'; FAIL = 'Red'; SKIP = 'Yellow' }[$status]
}

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
$skipped = @($results | Where-Object { $_.Status -eq 'SKIP' })
Write-Host ''
Write-Host ('{0} passed, {1} failed, {2} skipped' -f
    ($results.Count - $failed.Count - $skipped.Count), $failed.Count, $skipped.Count)

if ($KeepSandbox) {
    Write-Host "Sandboxes kept at $SandboxRoot"
} else {
    Remove-Item -LiteralPath $SandboxRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failed.Count -gt 0) { exit 1 }
exit 0
