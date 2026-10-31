[CmdletBinding()]
param(
    [switch]$Check
)

# .agents/skills/ is the canonical skill source (Codex, Copilot, Antigravity,
# Hermes). Claude Code reads only .claude/skills/, so this script regenerates
# that directory as an exact copy. Output is a single JSON object.

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repositoryRoot '.agents/skills'
$mirrorPath = Join-Path $repositoryRoot '.claude/skills'

function Get-FileHashMap([string]$BasePath) {
    $map = @{}
    if (Test-Path -LiteralPath $BasePath) {
        foreach ($file in Get-ChildItem -LiteralPath $BasePath -Recurse -File -Force) {
            $relativePath = [System.IO.Path]::GetRelativePath($BasePath, $file.FullName).Replace('\', '/')
            $map[$relativePath] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    $map
}

function Write-Result([hashtable]$Result) {
    $Result | ConvertTo-Json -Compress -Depth 3 | Write-Output
}

if ($Check) {
    $sourceFiles = Get-FileHashMap $sourcePath
    $mirrorFiles = Get-FileHashMap $mirrorPath
    $missing = @($sourceFiles.Keys | Where-Object { -not $mirrorFiles.ContainsKey($_) } | Sort-Object)
    $extra = @($mirrorFiles.Keys | Where-Object { -not $sourceFiles.ContainsKey($_) } | Sort-Object)
    $changed = @($sourceFiles.Keys | Where-Object { $mirrorFiles.ContainsKey($_) -and $mirrorFiles[$_] -ne $sourceFiles[$_] } | Sort-Object)

    if ($missing.Count + $extra.Count + $changed.Count -gt 0) {
        Write-Result @{
            status  = 'drift'
            reason  = '.claude/skills/ does not match .agents/skills/.'
            missing = $missing
            extra   = $extra
            changed = $changed
            fix     = 'Run: task skills:sync'
        }
        exit 1
    }

    Write-Result @{ status = 'in-sync'; files = $sourceFiles.Count }
    exit 0
}

if (Test-Path -LiteralPath $mirrorPath) {
    Remove-Item -LiteralPath $mirrorPath -Recurse -Force
}
if (Test-Path -LiteralPath $sourcePath) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $mirrorPath) -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $mirrorPath -Recurse -Force
}

Write-Result @{ status = 'synced'; files = (Get-FileHashMap $mirrorPath).Count }
