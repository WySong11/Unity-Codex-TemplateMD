# Unity + Codex environment check and opt-in setup helper.
# PowerShell 5.1 compatible. No third-party modules required.
# Source: https://docs.unity.com/en-us/unity-cli/
[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Check', 'Setup', 'Codex', 'Mcp', 'All')]
    [string]$Action = 'Menu',
    [string]$ProjectPath = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$script:FailedSteps = 0
$script:ProjectRoot = $null
$script:UnityAvailable = $false

function Write-Section([string]$Title) {
    Write-Host "`n========== $Title ==========" -ForegroundColor Cyan
}

function Write-Note([string]$Message) {
    Write-Host "[INFO] $Message"
}

function Write-Warn([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
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
        if ($code -ne 0) { Write-Warn "$Name returned exit code $code." }
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

function Test-Cli {
    Write-Section 'Unity CLI'
    if (-not (Test-Exe 'unity')) {
        Write-Warn 'Unity CLI (unity) was not found in PATH.'
        $script:UnityAvailable = $false
        return
    }
    $code = Invoke-Tool 'unity' @('--version')
    if ($code -ne 0) { Write-Fail 'unity --version failed.'; $script:UnityAvailable = $false; return }
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
    Write-Note 'Official Windows sources: Unity CLI PowerShell installer or winget Unity.CLI.'
    Write-Note 'Installer script URL: https://unity.com/install.ps1'
    Write-Warn 'The official installer is downloaded over HTTPS and executed locally; review the script before approving.'
    if (-not (Confirm-Change 'Download the official Unity CLI beta installer for review?')) { Write-Note 'Skipped Unity CLI installation.'; return }
    $scriptPath = Join-Path ([IO.Path]::GetTempPath()) ('unity-cli-install-' + [guid]::NewGuid().ToString('N') + '.ps1')
    $oldChannel = [Environment]::GetEnvironmentVariable('UNITY_CLI_CHANNEL', 'Process')
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri 'https://unity.com/install.ps1' -UseBasicParsing -MaximumRedirection 5 -OutFile $scriptPath
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Official installer download did not produce a file.' }
        if ((Get-Item -LiteralPath $scriptPath).Length -lt 100) { throw 'Downloaded installer file is unexpectedly small.' }
        $sha256 = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
        Write-Note "Downloaded official installer SHA256: $sha256"
        Write-Note "Downloaded installer is at: $scriptPath"
        if (-not (Confirm-Change 'Execute this downloaded script? (Review the file first if required)')) {
            Write-Note 'Installer execution skipped.'
            return
        }
        $env:UNITY_CLI_CHANNEL = 'beta'
        Write-Note 'Running official Unity CLI beta installer in this PowerShell session.'
        & $scriptPath
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { Write-Fail "Unity installer returned $LASTEXITCODE." }
    } catch {
        Write-Fail "CLI installation failed: $($_.Exception.Message)"
    } finally {
        [Environment]::SetEnvironmentVariable('UNITY_CLI_CHANNEL', $oldChannel, 'Process')
        Remove-Item -LiteralPath $scriptPath -ErrorAction SilentlyContinue
    }
    Refresh-ProcessPath
    Test-Cli
    if (-not $script:UnityAvailable) { Write-Warn 'Open a new terminal and run Check. PATH changes may not be visible yet.' }
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
    if ($script:UnityAvailable) { [void](Invoke-Tool 'unity' @('skill', 'install', '--list')) }
}

function Test-EditorConnectivity {
    if (-not $script:UnityAvailable -or -not $script:ProjectRoot) { return }
    Write-Section 'Editor connectivity (read-only)'
    $code = Invoke-Tool 'unity' @('status', '--project-path', $script:ProjectRoot, '--format', 'json')
    if ($code -ne 0) { Write-Warn 'Unity Editor may be closed, loading, awaiting input, or blocked by permissions.' }
}

function Setup-CliAndPipeline {
    Test-Cli
    if (-not $script:UnityAvailable) {
        if (-not (Test-Exe 'unity')) { Install-UnityCli }
        else { Write-Warn 'Existing unity executable failed validation. Not installing over it automatically.' }
    } else {
        Write-Section 'CLI version policy'
        $code = Invoke-Tool 'unity' @('self-update', '--check', '--format', 'json')
        if ($code -eq 0) {
            if (Confirm-Change 'Apply official current-channel CLI self-update (no-op if already current)?') {
                $result = Invoke-Tool 'unity' @('self-update', '--yes')
                if ($result -ne 0) { Write-Fail 'CLI update failed.' }
                else { Test-Cli }
            }
        } else { Write-Warn 'Update availability could not be verified. No CLI update attempted.' }
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
