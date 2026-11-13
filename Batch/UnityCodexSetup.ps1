# Unity + Codex environment check and opt-in setup helper.
# PowerShell 5.1 compatible. No third-party modules required.
# Source: https://docs.unity.com/en-us/unity-cli/
[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Check', 'Setup', 'Codex', 'Mcp', 'All')]
    [string]$Action = 'Menu',
    [string]$ProjectPath = '',
    # Selects the channel for a new CLI install. Omit to choose at the prompt.
    [ValidateSet('stable', 'beta')]
    [string]$CliChannel
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$script:FailedSteps = 0
$script:ProjectRoot = $null
$script:UnityAvailable = $false
$script:UnityCliRelease = $null

function Write-Section([string]$Title) {
    Write-Host "`n========== $Title ==========" -ForegroundColor Cyan
}

function Write-Note([string]$Message) {
    Write-Host "[INFO] $Message"
}

function Write-Warn([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

# Beta.17 exit categories are hints only; the invoked command and its message are authoritative.
function Get-UnityExitHint([int]$Code) {
    switch ($Code) {
        1  { return 'General failure or configuration write failure; inspect the command output.' }
        2  { return 'Invalid or missing CLI argument; check the actual subcommand --help.' }
        4  { return 'Command-specific input/auth failure (e.g. VCS_TOKEN_REQUIRED); inspect output.' }
        7  { return 'Network/service unavailable; check connectivity, DNS and proxy.' }
        14 { return 'Operation timed out; check network/Editor state.' }
        17 { return 'Unity Editor unavailable; check loading, compilation and Safe Mode.' }
        18 { return 'Unity Editor awaiting dialog input; inspect safely before responding.' }
        default { return 'Check the command-specific error message.' }
    }
}

function Write-Fail([string]$Message) {
    $script:FailedSteps++
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Confirm-Change([string]$Question) {
    $answer = Read-Host "$Question [y/N]"
    return ($answer -match '^(y|yes)$')
}

function Test-Exe([string]$Name) {
    return ($null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue))
}

function Invoke-Tool([string]$Name, [string[]]$Arguments) {
    Write-Host ("`n> " + $Name + ' ' + ($Arguments -join ' ')) -ForegroundColor DarkCyan
    try {
        & $Name @Arguments | Out-Host
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 1 }
        if ($code -ne 0) {
            Write-Warn "$Name returned exit code $code."
            if ($Name -eq 'unity') { Write-Warn (Get-UnityExitHint ([int]$code)) }
        }
        return [int]$code
    } catch {
        Write-Warn "$Name failed: $($_.Exception.Message)"
        return 1
    }
}

function Get-UnityVersion([string]$Root) {
    $versionFile = Join-Path $Root 'ProjectSettings\ProjectVersion.txt'
    try {
        $line = Get-Content -LiteralPath $versionFile -Encoding UTF8 |
            Where-Object { $_ -match '^m_EditorVersion:\s*(.+)$' } | Select-Object -First 1
        if ($line -match '^m_EditorVersion:\s*(.+)$') { return $Matches[1].Trim() }
    } catch { }
    return 'unknown'
}

function Test-UnityProject([string]$Root) {
    if ([string]::IsNullOrWhiteSpace($Root)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Root 'Assets') -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Root 'Packages\manifest.json') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'ProjectSettings\ProjectVersion.txt') -PathType Leaf)
}

function Resolve-ProjectRoot {
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        $candidates += $ProjectPath
    } else {
        $candidates += (Get-Location).ProviderPath
        $candidates += (Split-Path -Parent $PSScriptRoot)
    }
    foreach ($candidate in $candidates) {
        try { $full = [IO.Path]::GetFullPath($candidate) } catch { continue }
        if (Test-UnityProject $full) { return $full }
    }
    if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        throw "Invalid Unity project path: $ProjectPath (requires Assets, Packages/manifest.json and ProjectSettings/ProjectVersion.txt)."
    }
    return $null
}

function Get-PipelineDependency {
    if (-not $script:ProjectRoot) { return $null }
    $manifestPath = Join-Path $script:ProjectRoot 'Packages\manifest.json'
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $manifest.dependencies) { throw 'Missing dependencies object.' }
        $p = $manifest.dependencies.PSObject.Properties['com.unity.pipeline']
        if ($null -eq $p) { return $null }
        return [string]$p.Value
    } catch {
        Write-Fail "Unable to read Packages/manifest.json: $($_.Exception.Message)"
        return 'INVALID_MANIFEST'
    }
}

function Get-PipelineResolvedVersion {
    if (-not $script:ProjectRoot) { return $null }
    $lockPath = Join-Path $script:ProjectRoot 'Packages\packages-lock.json'
    if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) { return $null }
    try {
        $lock = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $lock.dependencies) { return $null }
        $p = $lock.dependencies.PSObject.Properties['com.unity.pipeline']
        if ($null -eq $p) { return $null }
        return [string]$p.Value.version
    } catch {
        Write-Warn 'Unable to read packages-lock.json. Resolve status is unknown.'
        return $null
    }
}

function Get-UnityCliRelease([string]$Version) {
    $pattern = '^v?(?<core>\d+\.\d+\.\d+)(?:-(?<prerelease>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$'
    if ($Version -notmatch $pattern) { return $null }

    $core = [version]$Matches['core']
    $prerelease = $Matches['prerelease']
    $channel = 'prerelease'
    $betaNumber = $null
    if (-not $prerelease) { $channel = 'stable' }
    elseif ($prerelease -match '^beta\.(\d+)$') {
        $channel = 'beta'
        $betaNumber = [long]$Matches[1]
    }
    return [pscustomobject]@{
        Version = $Version.TrimStart('v')
        Core = $core
        Channel = $channel
        BetaNumber = $betaNumber
    }
}

function Test-Cli {
    Write-Section 'Unity CLI'
    $script:UnityAvailable = $false
    $script:UnityCliRelease = $null
    if (-not (Test-Exe 'unity')) {
        Write-Warn 'Unity CLI (unity) was not found in PATH.'
        return
    }
    try {
        $versionText = (& unity --format human --version | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE." }
        $script:UnityCliRelease = Get-UnityCliRelease $versionText
        if (-not $script:UnityCliRelease) { throw "Unrecognized version: $versionText" }
    } catch {
        Write-Fail "Could not identify the Unity CLI version: $($_.Exception.Message)"
        return
    }
    Write-Note "Unity CLI $($script:UnityCliRelease.Version) ($($script:UnityCliRelease.Channel))"
    $code = Invoke-Tool 'unity' @('pipeline', '--help')
    if ($code -ne 0) {
        Write-Fail 'The unity command does not expose the expected Pipeline CLI. Check PATH for a conflicting executable.'
        $script:UnityAvailable = $false
        return
    }
    $script:UnityAvailable = $true
    $where = @(Get-Command -Name unity -All -ErrorAction SilentlyContinue | ForEach-Object { $_.Source } | Select-Object -Unique)
    if ($where.Count -gt 0) { Write-Note ('Resolved paths: ' + ($where -join '; ')) }
    if ($where.Count -gt 1) { Write-Warn 'Multiple unity commands found. Confirm the one that is executed.' }
}

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $currentParts = @($env:Path -split ';') | Where-Object { $_ }
    $seen = @{}
    foreach ($part in $currentParts) { $seen[$part.TrimEnd('\').ToLowerInvariant()] = $true }
    foreach ($part in (@($machine, $user) -join ';') -split ';') {
        if ($part -and -not $seen.ContainsKey($part.TrimEnd('\').ToLowerInvariant())) {
            $currentParts += $part
            $seen[$part.TrimEnd('\').ToLowerInvariant()] = $true
        }
    }
    $env:Path = $currentParts -join ';' 
}

function Install-UnityCli {
    Write-Section 'Install Unity CLI (missing only)'
    $channel = $CliChannel
    if (-not $channel) {
        $channel = Read-Host 'Unity CLI install channel [stable (default)/beta]'
        if ([string]::IsNullOrWhiteSpace($channel)) { $channel = 'stable' }
        $channel = $channel.Trim()
        if ($channel -notin @('stable', 'beta')) {
            Write-Fail "Unknown CLI install channel: $channel. Choose stable or beta."
            return
        }
    }
    $channel = $channel.ToLowerInvariant()
    $manifestName = 'latest.json'
    $installerChannel = ''
    if ($channel -eq 'beta') {
        $manifestName = 'latest-beta.json'
        $installerChannel = 'beta'
    }

    Write-Note 'Official Windows sources: Unity CLI PowerShell installer or winget Unity.CLI.'
    Write-Note 'Installer script URL: https://unity.com/install.ps1'
    Write-Warn 'The official installer is downloaded over HTTPS and executed locally; review the script before approving.'
    if (-not (Confirm-Change "Check the $channel release and download the official installer for review?")) {
        Write-Note 'Skipped Unity CLI installation.'
        return
    }
    $scriptPath = Join-Path ([IO.Path]::GetTempPath()) ('unity-cli-install-' + [guid]::NewGuid().ToString('N') + '.ps1')
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $manifestUrl = "https://public-cdn.cloud.unity3d.com/hub/prod/cli/$manifestName"
        $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing -MaximumRedirection 5
        $release = Get-UnityCliRelease $manifest.version
        if (-not $release -or $release.Channel -ne $channel) {
            Write-Fail "The $channel feed did not return a $channel release (reported: $($manifest.version)). Choose a channel with an available release."
            return
        }
        Invoke-WebRequest -Uri 'https://unity.com/install.ps1' -UseBasicParsing -MaximumRedirection 5 -OutFile $scriptPath
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Official installer download did not produce a file.' }
        if ((Get-Item -LiteralPath $scriptPath).Length -lt 100) { throw 'Downloaded installer file is unexpectedly small.' }
        $sha256 = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
        Write-Note "Downloaded official installer SHA256: $sha256"
        Write-Note "Downloaded installer is at: $scriptPath"
        if (-not (Confirm-Change "Execute the downloaded script to install Unity CLI $($release.Version) ($channel)?")) {
            Write-Note 'Installer execution skipped.'
            return
        }
        # Pin the reviewed release so the official installer's latest fallback cannot change channels.
        & $scriptPath -Target $release.Version -Channel $installerChannel
        if (-not $?) { throw "Official installer returned exit code $LASTEXITCODE." }
    } catch {
        Write-Fail "CLI installation failed: $($_.Exception.Message)"
    } finally {
        Remove-Item -LiteralPath $scriptPath -ErrorAction SilentlyContinue
    }
    Refresh-ProcessPath
    Test-Cli
    if (-not $script:UnityAvailable) { Write-Warn 'Open a new terminal and run Check. PATH changes may not be visible yet.' }
    elseif ($script:UnityCliRelease.Version -ne $release.Version) {
        Write-Fail "PATH resolves to $($script:UnityCliRelease.Version), expected $($release.Version)."
        $script:UnityAvailable = $false
    }
}

function Show-UnityProject {
    Write-Section 'Unity project / Pipeline package'
    if (-not $script:ProjectRoot) { Write-Warn 'No Unity project root found. Pipeline install/upgrade is skipped.'; return }
    Write-Note "Project: $script:ProjectRoot"
    Write-Note ("Editor version: " + (Get-UnityVersion $script:ProjectRoot))
    $declared = Get-PipelineDependency
    if ($null -eq $declared) { Write-Warn 'com.unity.pipeline is not declared in Packages/manifest.json.' }
    elseif ($declared -eq 'INVALID_MANIFEST') { Write-Warn 'Manifest could not be parsed. No package changes are safe.' }
    else { Write-Note "Pipeline manifest dependency: $declared" }
    $resolved = Get-PipelineResolvedVersion
    if ($resolved) { Write-Note "Pipeline lockfile version: $resolved" }
    elseif ($declared) { Write-Warn 'Pipeline package resolution was not verified from packages-lock.json.' }
}

function Test-Codex {
    Write-Section 'Git / Codex / Unity Skills'
    if (Test-Exe 'git') { [void](Invoke-Tool 'git' @('--version')) }
    else { Write-Warn 'Git for Windows is not on PATH. Existing GitWorkflow Batch helpers require Git.' }
    if (Test-Exe 'codex') {
        [void](Invoke-Tool 'codex' @('--version'))
        $help = Invoke-Tool 'codex' @('plugin', '--help')
        if ($help -eq 0) { [void](Invoke-Tool 'codex' @('plugin', 'list')) }
        else { Write-Warn 'Cannot inspect Codex Plugin with this Codex CLI. VS Code extension state is separate.' }
        [void](Invoke-Tool 'codex' @('mcp', 'list'))
    } else {
        Write-Warn 'codex CLI is not on PATH; VS Code Codex extension may still be available.'
        Write-Warn 'Codex CLI is not installed automatically by this script.'
    }
    if ($script:UnityAvailable) {
        [void](Invoke-Tool 'unity' @('skill', 'install', '--list'))
        $help = (& unity skill refresh --help | Out-String)
        if ($LASTEXITCODE -eq 0 -and $help -match '(?m)^\s+--dry-run\b') {
            $previewCode = Invoke-Tool 'unity' @('skill', 'refresh', '--dry-run', '--format', 'json')
            if ($previewCode -ne 0) { Write-Warn 'Skill refresh preview unavailable; no refresh was performed.' }
            else { Write-Note 'Review per-Skill would-update/would-skip/would-prune statuses and conflicts manually.' }
        } else {
            Write-Note 'Skill refresh dry-run is skipped (option not detected in CLI help).'
        }
    }
}

function Test-EditorConnectivity {
    if (-not $script:UnityAvailable -or -not $script:ProjectRoot) { return }
    Write-Section 'Editor connectivity (read-only)'
    $code = Invoke-Tool 'unity' @('status', '--project-path', $script:ProjectRoot, '--format', 'json')
    if ($code -ne 0) { Write-Warn 'Unity Editor may be closed, loading, awaiting input, or blocked by permissions.' }
}

function Get-UnityCliUpdateCandidate([string]$Channel) {
    $current = $script:UnityCliRelease
    Write-Note "Checking the $Channel feed for updates to $($current.Version) ($($current.Channel))."
    try {
        $json = (& unity self-update --check --channel $Channel --format json | Out-String)
        if ($LASTEXITCODE -ne 0) { throw "Exit code $LASTEXITCODE." }
        $check = $json | ConvertFrom-Json
        if ($check.success -ne $true -or $check.data.currentVersion -ne $current.Version) {
            throw 'Update response did not identify the current CLI.'
        }
        $candidate = Get-UnityCliRelease $check.data.latestVersion
        if (-not $candidate) { throw 'Update response did not identify a release.' }
    } catch {
        Write-Warn "Could not verify updates for $Channel`: $($_.Exception.Message)"
        return
    }

    if ($candidate.Channel -ne $Channel) {
        Write-Note "The $Channel feed returned $($candidate.Version) ($($candidate.Channel)). No $Channel update was selected."
        return
    }
    $newer = $candidate.Core -gt $current.Core
    if ($candidate.Core -eq $current.Core -and $current.Channel -eq 'beta') {
        $newer = $candidate.Channel -eq 'stable' -or $candidate.BetaNumber -gt $current.BetaNumber
    }
    if ($newer) { return $candidate }
    Write-Note "The $Channel feed has no newer release (reported: $($candidate.Version))."
}

function Update-UnityCli {
    Write-Section 'CLI version policy'
    $current = $script:UnityCliRelease
    if ($current.Channel -notin @('stable', 'beta')) {
        Write-Warn "Automatic update selection is unavailable for $($current.Version)."
        return
    }

    $candidate = Get-UnityCliUpdateCandidate 'stable'
    if ($current.Channel -eq 'beta') {
        $switchToStable = $candidate -and (Confirm-Change "Switch from $($current.Version) (beta) to $($candidate.Version) (stable)?")
        if (-not $switchToStable) {
            $candidate = Get-UnityCliUpdateCandidate 'beta'
            if (-not $candidate -or -not (Confirm-Change "Update to $($candidate.Version) (beta)?")) {
                Write-Note "Keeping Unity CLI $($current.Version) (beta)."
                return
            }
        }
    } elseif (-not $candidate -or -not (Confirm-Change "Update to $($candidate.Version) (stable)?")) {
        return
    }

    $result = Invoke-Tool 'unity' @('self-update', '--channel', $candidate.Channel, '--target', $candidate.Version, '--yes')
    if ($result -ne 0) { Write-Fail 'CLI update failed.'; return }
    Test-Cli
    if (-not $script:UnityAvailable -or $script:UnityCliRelease.Version -ne $candidate.Version) {
        Write-Fail "CLI update to $($candidate.Version) could not be verified on PATH."
        $script:UnityAvailable = $false
    }
}

function Setup-CliAndPipeline {
    Test-Cli
    if (-not $script:UnityAvailable) {
        if (-not (Test-Exe 'unity')) { Install-UnityCli }
        else { Write-Warn 'Existing unity executable failed validation. Not installing over it automatically.' }
    } else {
        Update-UnityCli
    }
    Show-UnityProject
    if (-not $script:ProjectRoot) {
        Write-Note 'Run again with -ProjectPath "C:\Path\To\UnityProject" to manage Pipeline.'
        return
    }
    if (-not $script:UnityAvailable) { Write-Fail 'Cannot install Pipeline because Unity CLI is unavailable.'; return }
    $version = Get-UnityVersion $script:ProjectRoot
    if ($version -notmatch '^6000\.' -and $version -notmatch '^6\.') {
        Write-Warn "Unity Editor 6.x+ was not verified (ProjectVersion=$version). Pipeline changes skipped."
        return
    }
    $declared = Get-PipelineDependency
    if ($declared -eq 'INVALID_MANIFEST') { return }
    $embeddedPipeline = Join-Path $script:ProjectRoot 'Packages\com.unity.pipeline'
    if ($null -eq $declared -and (Test-Path -LiteralPath $embeddedPipeline)) {
        Write-Warn 'Found an embedded Pipeline package under Packages/com.unity.pipeline. No registry install is attempted.'
    } elseif ($null -eq $declared) {
        Write-Note 'No Pipeline package is declared in this Unity project.'
        if (Confirm-Change 'Run unity pipeline install for this project?') {
            $code = Invoke-Tool 'unity' @('pipeline', 'install', '--project-path', $script:ProjectRoot)
            if ($code -ne 0) { Write-Fail 'Pipeline installation failed. Check Unity auth login, Editor and network.' }
        }
    } elseif ($declared -match '^(file:|git\+|git@|ssh:|https?:|\.{1,2}[/\\]|[/\\])') {
        Write-Warn 'Pipeline dependency is not a normal registry version. Package source is preserved; no upgrade attempted.'
    } else {
        Write-Note "Pipeline is already declared as $declared."
        $code = Invoke-Tool 'unity' @('pipeline', 'list-versions', '--format', 'json')
        if ($code -ne 0) {
            Write-Warn 'Could not check official Pipeline versions. Upgrade skipped.'
        } elseif (Confirm-Change 'Check/apply latest compatible Pipeline through official upgrade (may change manifest/lockfile)?') {
            $code = Invoke-Tool 'unity' @('pipeline', 'upgrade', '--project-path', $script:ProjectRoot)
            if ($code -ne 0) { Write-Fail 'Pipeline upgrade failed. Existing project files were not reset.' }
        }
    }
    Write-Section 'Pipeline after-check'
    $newVersion = Get-PipelineDependency
    $newResolved = Get-PipelineResolvedVersion
    Write-Note "Manifest: $newVersion / Lockfile: $newResolved"
    if ($script:UnityAvailable) {
        Write-Note 'Open the target Unity Editor to complete import, compilation and connectivity validation.'
        Test-EditorConnectivity
    }
}

function Setup-Codex {
    Write-Section 'Official Unity Codex Plugin + Skills (opt-in)'
    if (-not $script:UnityAvailable) { Write-Warn 'Unity CLI unavailable. Codex setup skipped.'; return }
    if (-not (Test-Exe 'codex')) {
        Write-Warn 'codex CLI is unavailable. VS Code extension may exist, but cannot be validated by this script.'
        Write-Warn 'No alternate Codex installation is attempted. Set up Codex CLI first if necessary.'
        return
    }
    $code = Invoke-Tool 'unity' @('setup', 'codex', '--dry-run')
    if ($code -ne 0) { Write-Warn 'Codex setup preview failed; no changes were made.'; return }
    if (-not (Confirm-Change 'Install or update official Unity Codex Plugin + Skill configuration?')) {
        Write-Note 'Codex configuration unchanged.'; return
    }
    $code = Invoke-Tool 'unity' @('setup', 'codex')
    if ($code -ne 0) { Write-Fail 'Unity Codex setup failed.'; return }
    Write-Note 'Start a fresh Codex session and verify Plugin and Skill recognition in the actual client.'
    Test-Codex
}

function Setup-Mcp {
    Write-Section 'Unity MCP for Codex (opt-in)'
    if (-not $script:UnityAvailable) { Write-Warn 'Unity CLI unavailable. MCP configuration skipped.'; return }
    if (-not (Test-Exe 'codex')) { Write-Warn 'codex CLI unavailable; MCP configuration skipped.'; return }
    [void](Invoke-Tool 'codex' @('mcp', 'list'))
    $code = Invoke-Tool 'unity' @('mcp', 'configure', 'codex', '--dry-run')
    if ($code -ne 0) { Write-Warn 'MCP configuration preview failed; no changes were made.'; return }
    Write-Warn 'MCP setup may modify Codex settings and tool/network permissions.'
    if (-not (Confirm-Change 'Apply official Codex MCP configuration now?')) { Write-Note 'MCP configuration unchanged.'; return }
    $code = Invoke-Tool 'unity' @('mcp', 'configure', 'codex')
    if ($code -ne 0) { Write-Fail 'MCP configuration failed.'; return }
    [void](Invoke-Tool 'codex' @('mcp', 'list'))
    Write-Note 'Restart the actual Codex client and test a read-only Unity MCP call.'
}

try {
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1 or later is required.' }
    $script:ProjectRoot = Resolve-ProjectRoot
    Write-Host 'Unity + Codex Setup (Windows)' -ForegroundColor Green
    Write-Note 'No Git operations, Unity Editor installs, or permission bypasses are performed.'
    if ($Action -eq 'Menu') {
        Write-Host "`n1. Check only (no changes)"
        Write-Host '2. Install/update Unity CLI and current-project Pipeline'
        Write-Host '3. Configure official Unity Codex Plugin + Skills (approval required)'
        Write-Host '4. Configure Unity MCP for Codex (approval required)'
        Write-Host '5. All steps (each change requires approval)'
        $choice = Read-Host 'Choose 1-5 (anything else exits)'
        switch ($choice) {
            '1' { $Action = 'Check' }
            '2' { $Action = 'Setup' }
            '3' { $Action = 'Codex' }
            '4' { $Action = 'Mcp' }
            '5' { $Action = 'All' }
            default { exit 0 }
        }
    }
    if ($Action -in @('Setup', 'All') -and (-not $script:ProjectRoot) -and [string]::IsNullOrWhiteSpace($ProjectPath)) {
        Write-Note 'This folder is not a Unity project root; Pipeline operations need an explicit project.'
        $entered = Read-Host 'Unity project path (blank to skip Pipeline)'
        if (-not [string]::IsNullOrWhiteSpace($entered)) {
            $ProjectPath = $entered.Trim('"')
            $script:ProjectRoot = Resolve-ProjectRoot
        }
    }
    if ($Action -eq 'Check') {
        Test-Cli
        Show-UnityProject
        Test-Codex
        Test-EditorConnectivity
    } elseif ($Action -eq 'Setup') {
        Setup-CliAndPipeline
    } elseif ($Action -eq 'Codex') {
        Test-Cli
        Setup-Codex
    } elseif ($Action -eq 'Mcp') {
        Test-Cli
        Setup-Mcp
    } elseif ($Action -eq 'All') {
        Setup-CliAndPipeline
        Setup-Codex
        Setup-Mcp
    }
    Write-Section 'Final result'
    if ($script:FailedSteps -gt 0) {
        Write-Host "[ERROR] $script:FailedSteps step(s) had failures. Review logs above." -ForegroundColor Red
        exit 1
    }
    Write-Note 'Finished. Skipped/unverified steps are not considered installed.'
    exit 0
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
