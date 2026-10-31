[CmdletBinding()]
param(
    [switch]$RequireWeb
)

$ErrorActionPreference = 'Continue'

$tools = @(
    @{ Name = "Git"; Cmd = "git"; Arg = "--version"; Required = $true; Doc = "https://git-scm.com/" },
    @{ Name = "Backlog.md"; Cmd = "backlog"; Arg = "--version"; Required = $true; Doc = "https://github.com/MrLesk/Backlog.md" },
    @{ Name = "RTK (Token Killer)"; Cmd = "rtk"; Arg = "--version"; Required = $true; Doc = "https://github.com/rtk-ai/rtk" },
    @{ Name = "Task (Go-Task)"; Cmd = "task"; Arg = "--version"; Required = $true; Doc = "https://taskfile.dev" },
    @{ Name = "PowerShell Core"; Cmd = "pwsh"; Arg = "--version"; Required = $true; Doc = "https://github.com/PowerShell/PowerShell" },
    @{ Name = "Node.js"; Cmd = "node"; Arg = "--version"; Required = $RequireWeb.IsPresent; Doc = "https://nodejs.org/" },
    @{ Name = "npm"; Cmd = "npm"; Arg = "--version"; Required = $RequireWeb.IsPresent; Doc = "https://nodejs.org/" },
    @{ Name = "pnpm"; Cmd = "pnpm"; Arg = "--version"; Required = $false; Doc = "https://pnpm.io/" }
)

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " YABA Preflight: Verifying Required Tools & Runtimes" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$allPassed = $true

foreach ($t in $tools) {
    $found = Get-Command $t.Cmd -ErrorAction SilentlyContinue
    if ($found) {
        $ver = (& $t.Cmd $t.Arg 2>&1 | Select-Object -First 1).ToString().Trim()
        Write-Host ("  [PASS] {0,-26} : {1}" -f $t.Name, $ver) -ForegroundColor Green
    } else {
        if ($t.Required) {
            Write-Host ("  [FAIL] {0,-26} : NOT FOUND (Required) -> {1}" -f $t.Name, $t.Doc) -ForegroundColor Red
            $allPassed = $false
        } else {
            Write-Host ("  [WARN] {0,-26} : NOT FOUND (Optional runtime) -> {1}" -f $t.Name, $t.Doc) -ForegroundColor Yellow
        }
    }
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
    $gainLine = rtk gain 2>&1 | Select-String "Tokens saved"
    if ($gainLine) {
        Write-Host ("  [INFO] {0,-26} : {1}" -f "RTK Token Optimization", $gainLine.ToString().Trim()) -ForegroundColor Cyan
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan

if (-not $allPassed) {
    Write-Host "ERROR: Mandatory tools are missing. Please install missing tools above before proceeding.`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All required tools verified successfully!`n" -ForegroundColor Green
}
