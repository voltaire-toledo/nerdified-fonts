[CmdletBinding()]
param(
    [string]$ProjectName,

    [Parameter(Mandatory)]
    [ValidatePattern('^(git@github\.com:|https://github\.com/)')]
    [string]$RemoteUrl,

    [string]$Destination,

    [string]$DestinationRoot
)

$ErrorActionPreference = 'Stop'
$templateRoot = Split-Path -Parent $PSScriptRoot

# Resolve full destination path across operating systems
if (-not [string]::IsNullOrWhiteSpace($Destination)) {
    $destination = [System.IO.Path]::GetFullPath($Destination)
    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $ProjectName = Split-Path -Leaf $destination
    }
} elseif (-not [string]::IsNullOrWhiteSpace($DestinationRoot) -and -not [string]::IsNullOrWhiteSpace($ProjectName)) {
    $destination = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot $ProjectName))
} elseif (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
    # Default to a sibling of the repository that holds this template.
    $templateRepositoryRoot = & git -C $templateRoot rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($templateRepositoryRoot)) {
        $templateRepositoryRoot = $templateRoot
    }
    $defaultRoot = Split-Path -Parent ([System.IO.Path]::GetFullPath($templateRepositoryRoot))
    $destination = [System.IO.Path]::GetFullPath((Join-Path $defaultRoot $ProjectName))
} else {
    throw "Either -Destination or -ProjectName must be specified."
}

if ($ProjectName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "Project name '$ProjectName' is invalid. Must match '^[A-Za-z0-9][A-Za-z0-9._-]*$'."
}

$versionMatch = [regex]::Match((Get-Content -Raw -LiteralPath (Join-Path $templateRoot 'AGENTS.md')), 'Scaffold Version:\s*(\S+)')
$scaffoldVersion = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { 'unknown' }

function Write-Status([int]$Step, [string]$Message) {
    Write-Host "[bootstrap $Step/9] $Message" -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command is not available: $Name"
    }
}

function Invoke-Checked([string]$Name, [string[]]$Arguments) {
    & $Name @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " YABA Scaffold v$scaffoldVersion Bootstrap: Initializing New Project" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Project Name    : $ProjectName"
Write-Host " Target Directory: $destination"
Write-Host " Remote Origin   : $RemoteUrl"
Write-Host ""
Write-Host " This automated script executes a 9-step initialization:" -ForegroundColor Yellow
Write-Host "   1. Precheck required tools (git, backlog, rtk, task, pwsh)."
Write-Host "   2. Copy clean YABA v$scaffoldVersion chassis (excluding .git history and template tasks)."
Write-Host "   3. Initialize a fresh local Git repository on 'main'."
Write-Host "   4. Configure GitHub remote origin (no network push will occur)."
Write-Host "   5. Run 'backlog init' to establish a fresh task ledger."
Write-Host "   6. Run 'rtk init' to configure token-saving rules (generating RTK.md)."
Write-Host "   7. Apply safe, Git-aware Backlog defaults (no auto-commit, no browser popups)."
Write-Host "   8. Seed default project setup tasks in the backlog."
Write-Host "   9. Run template validation (bootstrap placeholders expected)."
Write-Host "=================================================================`n" -ForegroundColor Cyan

Write-Status 1 "Prechecking required local tools and target directory."
& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'precheck-tools.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Tool preflight check failed. Please install missing tools."
}

$parentDir = Split-Path -Parent $destination
if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}

$existingItems = @(Get-ChildItem -Force -LiteralPath $destination)
if ($existingItems.Count -gt 0) {
    throw "Destination is not empty: $destination. Choose an empty directory to avoid overwriting project files."
}

Write-Status 2 "Copying the template without its .git history or template Backlog tasks."
if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -match 'Windows')) {
    & robocopy $templateRoot $destination /E /XD .git .backlog /XF backlog.config.yml /NJH /NJS /NFL /NDL
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -gt 7) {
        throw "robocopy failed with exit code $robocopyExitCode."
    }
} else {
    Get-ChildItem -LiteralPath $templateRoot -Force | Where-Object { $_.Name -notin @('.git', 'backlog.config.yml') } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) -Recurse -Force
    }
    # Template task records are never copied; backlog init creates a fresh ledger.
    $copiedBacklog = Join-Path $destination '.ai/.backlog'
    if (Test-Path -LiteralPath $copiedBacklog) {
        Remove-Item -LiteralPath $copiedBacklog -Recurse -Force
    }
}

Push-Location $destination
try {
    Write-Status 3 "Initializing the local Git repository on main."
    Invoke-Checked 'git' @('init', '-b', 'main')

    Write-Status 4 "Adding the supplied GitHub remote; no network push will occur."
    Invoke-Checked 'git' @('remote', 'add', 'origin', $RemoteUrl)
    Invoke-Checked 'git' @('remote', '-v')

    Write-Status 5 "Running 'backlog init' to establish a fresh task ledger."
    Invoke-Checked 'backlog' @(
        'init', $ProjectName, '--defaults', '--backlog-dir', '.ai/.backlog', '--config-location', 'root',
        '--integration-mode', 'none',
        '--auto-open-browser', 'false', '--check-branches', 'true', '--include-remote', 'false'
    )

    Write-Status 6 "Running 'rtk init' to configure token-saving rules."
    Invoke-Checked 'rtk' @('init', '--codex')

    Write-Status 7 "Applying local, Git-aware Backlog.md defaults."
    foreach ($setting in @(
        @('autoOpenBrowser', 'false'),
        @('remoteOperations', 'false'),
        @('autoCommit', 'false'),
        @('filesystemOnly', 'false'),
        @('checkActiveBranches', 'true')
    )) {
        Invoke-Checked 'backlog' @('config', 'set', $setting[0], $setting[1])
    }
    Invoke-Checked 'backlog' @('config', 'list')

    Write-Status 8 "Seeding default project setup tasks."
    Invoke-Checked 'pwsh' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', './scripts/seed-backlog.ps1')

    Write-Status 9 "Running template validation; bootstrap placeholders are expected at this stage."
    Invoke-Checked 'pwsh' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', './scripts/verify-agent-scaffold.ps1')

    Write-Host '[bootstrap] Completed without committing or pushing.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next actions:' -ForegroundColor Green
    Write-Host "  1. cd $destination"
    Write-Host '  2. Run: task next   (lists the seeded setup tasks: project context, PRD, SPECS, Definition of Done, README)'
    Write-Host '  3. Complete those tasks, then run: task verify-bootstrap'
    Write-Host '  4. Inspect git status, then commit and push only when you approve the initial project state.'
}
finally {
    Pop-Location
}
