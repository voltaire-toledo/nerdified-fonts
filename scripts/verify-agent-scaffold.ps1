[CmdletBinding()]
param(
    [switch]$RequireBootstrap
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-ScaffoldError([string]$Message) {
    $errors.Add($Message)
}

function Add-ScaffoldWarning([string]$Message) {
    $warnings.Add($Message)
}

function Test-RequiredPath([string]$RelativePath) {
    $path = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-ScaffoldError "Missing required path: $RelativePath"
    }
}

function Get-RepositoryText([string]$RelativePath) {
    Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot $RelativePath)
}

# Reads top-level scalar keys from SKILL.md frontmatter, including folded (>) and literal (|) blocks.
function Get-SkillFrontmatter([string]$Path) {
    $lines = @(Get-Content -LiteralPath $Path)
    if ($lines.Count -lt 2 -or $lines[0].Trim() -ne '---') {
        return $null
    }
    $closingIndex = -1
    for ($index = 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -eq '---') {
            $closingIndex = $index
            break
        }
    }
    if ($closingIndex -lt 0) {
        return $null
    }
    $fields = @{}
    $currentKey = $null
    for ($index = 1; $index -lt $closingIndex; $index++) {
        $line = $lines[$index]
        if ($line -match '^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$') {
            $currentKey = $Matches[1]
            $value = $Matches[2].Trim()
            if ($value -in @('>', '>-', '|', '|-')) {
                $value = ''
            }
            $fields[$currentKey] = $value.Trim('"', "'")
        }
        elseif ($null -ne $currentKey -and $line -match '^\s+\S') {
            $fields[$currentKey] = ($fields[$currentKey] + ' ' + $line.Trim()).Trim()
        }
    }
    $fields
}

$requiredPaths = @(
    'AGENTS.md',
    '.gitignore',
    'scripts/seed-backlog.ps1',
    'Taskfile.yml',
    'README.md',
    '.ai/shared/instructions/README-template.md',
    '.ai/shared/instructions/keystone-instructions.md',
    '.ai/shared/instructions/project-context.md',
    '.ai/shared/instructions/tool-prerequisites.md',
    '.ai/shared/instructions/skill-authoring.md',
    '.github/copilot-instructions.md',
    '.claude/CLAUDE.md',
    'scripts/bootstrap-new-project.ps1',
    'scripts/sync-skills.ps1',
    'backlog.config.yml'
)

foreach ($relativePath in $requiredPaths) {
    Test-RequiredPath $relativePath
}

if ($errors.Count -eq 0) {
    $gitIgnore = Get-RepositoryText '.gitignore'
    foreach ($requiredException in @('!AGENTS.md', '!.ai/**', '!.agents/**', '!.claude/**', '!backlog.config.yml')) {
        if ($gitIgnore -notmatch [regex]::Escape($requiredException)) {
            Add-ScaffoldError ".gitignore is missing required exception: $requiredException"
        }
    }

    $rootInstructions = Get-RepositoryText 'AGENTS.md'
    foreach ($requiredRule in @('Do not commit, push, deploy', 'backlog instructions overview', '.ai/shared/instructions/project-context.md', '.ai/shared/instructions/tool-prerequisites.md', 'rtk --version', 'mechanical edits')) {
        if ($rootInstructions -notmatch [regex]::Escape($requiredRule)) {
            Add-ScaffoldError "AGENTS.md is missing required contract text: $requiredRule"
        }
    }

    # README.md starts as a copy of the template; once the project replaces it, it is
    # the project's own file and only the template marker matters.
    $readmeText = Get-RepositoryText 'README.md'
    if ($readmeText -match 'YABA:README-TEMPLATE') {
        if ($readmeText -ne (Get-RepositoryText '.ai/shared/instructions/README-template.md')) {
            Add-ScaffoldError 'README.md still has the template marker but differs from .ai/shared/instructions/README-template.md. Finish replacing it and remove the marker, or restore the template.'
        }
        $message = 'README.md is still the scaffold template. Replace it with the project README.'
        if ($RequireBootstrap) {
            Add-ScaffoldError $message
        } else {
            Add-ScaffoldWarning $message
        }
    }

    $sourceDocuments = @(
        '.ai/shared/instructions/README-template.md',
        '.ai/shared/instructions/keystone-instructions.md',
        '.ai/shared/instructions/tool-prerequisites.md',
        '.ai/shared/instructions/skill-authoring.md',
        '.github/copilot-instructions.md',
        '.claude/CLAUDE.md'
    )
    foreach ($relativePath in $sourceDocuments) {
        $content = Get-RepositoryText $relativePath
        foreach ($retiredReference in @('.ai/HANDOFF.md', '.ai/BACKLOG.md', 'Gemini CLI')) {
            if ($content -match [regex]::Escape($retiredReference)) {
                Add-ScaffoldError "$relativePath still refers to retired scaffold content: $retiredReference"
            }
        }
    }

    $adapterContracts = @(
        @{ Path = '.github/copilot-instructions.md'; Marker = 'AGENTS.md' },
        @{ Path = '.claude/CLAUDE.md'; Marker = '@../AGENTS.md' }
    )
    foreach ($adapter in $adapterContracts) {
        if ((Get-RepositoryText $adapter.Path) -notmatch [regex]::Escape($adapter.Marker)) {
            Add-ScaffoldError "$($adapter.Path) does not point to the root contract."
        }
    }

    # Claude Code resolves @imports relative to the importing file, not the repository root.
    $claudeAdapterDirectory = Join-Path $repositoryRoot '.claude'
    foreach ($importLine in (Get-RepositoryText '.claude/CLAUDE.md') -split "`r?`n" | Where-Object { $_ -match '^@(\S+)\s*$' }) {
        $importPath = $importLine.Trim().Substring(1)
        if (-not (Test-Path -LiteralPath (Join-Path $claudeAdapterDirectory $importPath))) {
            Add-ScaffoldError ".claude/CLAUDE.md import does not resolve relative to .claude/: $importPath"
        }
    }

    foreach ($retiredPath in @('.gemini', '.antigravitycli', '.backlog', '.ai/shared/skills', '.claude/agents/project-manager-backlog.md')) {
        if (Test-Path -LiteralPath (Join-Path $repositoryRoot $retiredPath)) {
            Add-ScaffoldError "Retired scaffold path is still present: $retiredPath"
        }
    }

    $toolPrerequisites = Get-RepositoryText '.ai/shared/instructions/tool-prerequisites.md'
    foreach ($requiredToolMarker in @('rtk --version', 'rtk gain', 'backlog --version', 'github.com/rtk-ai/rtk', 'github.com/MrLesk/Backlog.md')) {
        if ($toolPrerequisites -notmatch [regex]::Escape($requiredToolMarker)) {
            Add-ScaffoldError "Tool prerequisites are missing required guidance: $requiredToolMarker"
        }
    }

    $backlogConfig = Get-RepositoryText 'backlog.config.yml'
    if ($backlogConfig -notmatch 'backlog_directory:\s*"?\.ai/\.backlog"?') {
        Add-ScaffoldError 'backlog.config.yml must set backlog_directory: ".ai/.backlog".'
    }
    foreach ($unsafeDefault in @('auto_open_browser: true', 'remote_operations: true', 'filesystem_only: true')) {
        if ($backlogConfig -match [regex]::Escape($unsafeDefault)) {
            Add-ScaffoldError "Unsafe Backlog default remains enabled: $unsafeDefault"
        }
    }

    $skillsPath = Join-Path $repositoryRoot '.agents/skills'
    if (Test-Path -LiteralPath $skillsPath) {
        foreach ($skillDirectory in Get-ChildItem -LiteralPath $skillsPath -Directory -Force) {
            $skillLabel = ".agents/skills/$($skillDirectory.Name)"
            $skillFile = Join-Path $skillDirectory.FullName 'SKILL.md'
            if (-not (Test-Path -LiteralPath $skillFile)) {
                Add-ScaffoldError "$skillLabel is missing SKILL.md."
                continue
            }
            $frontmatter = Get-SkillFrontmatter $skillFile
            if ($null -eq $frontmatter) {
                Add-ScaffoldError "$skillLabel/SKILL.md must start with YAML frontmatter delimited by '---'."
                continue
            }
            $skillName = $frontmatter['name']
            if ([string]::IsNullOrWhiteSpace($skillName)) {
                Add-ScaffoldError "$skillLabel/SKILL.md frontmatter is missing 'name'."
            }
            elseif ($skillName -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $skillName -ne $skillDirectory.Name) {
                Add-ScaffoldError "$skillLabel/SKILL.md 'name' must be lowercase-hyphenated and match the folder name; found '$skillName'."
            }
            $skillDescription = $frontmatter['description']
            if ([string]::IsNullOrWhiteSpace($skillDescription)) {
                Add-ScaffoldError "$skillLabel/SKILL.md frontmatter is missing 'description'."
            }
            elseif ($skillDescription.Length -gt 1536) {
                Add-ScaffoldError "$skillLabel/SKILL.md 'description' is $($skillDescription.Length) characters; Claude Code truncates at 1536."
            }
            $skillLineCount = @(Get-Content -LiteralPath $skillFile).Count
            if ($skillLineCount -gt 500) {
                Add-ScaffoldWarning "$skillLabel/SKILL.md has $skillLineCount lines; move detail into references/ to stay under 500."
            }
        }
    }

    $mirrorCheck = & (Join-Path $PSScriptRoot 'sync-skills.ps1') -Check
    if ($LASTEXITCODE -ne 0) {
        Add-ScaffoldError "Claude Code skill mirror is out of date: $mirrorCheck"
    }

    $versionPattern = 'Scaffold Version:\s*(\S+)'
    $contractVersionMatch = [regex]::Match((Get-RepositoryText 'AGENTS.md'), $versionPattern)
    if (-not $contractVersionMatch.Success) {
        Add-ScaffoldError 'AGENTS.md is missing its Scaffold Version stamp.'
    }
    else {
        $contractVersion = $contractVersionMatch.Groups[1].Value
        $stampedFiles = @(
            Get-ChildItem -LiteralPath (Join-Path $repositoryRoot '.claude'), (Join-Path $repositoryRoot '.github'), (Join-Path $repositoryRoot '.ai/shared/instructions') -Filter '*.md' -File -Recurse -Force -ErrorAction SilentlyContinue
        )
        foreach ($stampedFile in $stampedFiles) {
            foreach ($stamp in [regex]::Matches((Get-Content -Raw -LiteralPath $stampedFile.FullName), $versionPattern)) {
                if ($stamp.Groups[1].Value -ne $contractVersion) {
                    $stampedPath = [System.IO.Path]::GetRelativePath($repositoryRoot, $stampedFile.FullName).Replace('\', '/')
                    Add-ScaffoldError "$stampedPath has Scaffold Version $($stamp.Groups[1].Value); AGENTS.md has $contractVersion."
                }
            }
        }
    }

    $projectContext = Get-RepositoryText '.ai/shared/instructions/project-context.md'
    $templateMarkers = @('Status: template', 'not set')
    $templateIsIncomplete = $templateMarkers | Where-Object { $projectContext -match [regex]::Escape($_) }
    if ($templateIsIncomplete) {
        $message = 'Project context still has template markers. Complete it before product work.'
        if ($RequireBootstrap) {
            Add-ScaffoldError $message
        } else {
            Add-ScaffoldWarning $message
        }
    }
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($scaffoldError in $errors) {
    Write-Output "ERROR: $scaffoldError"
}

if ($errors.Count -gt 0) {
    throw "Agent scaffold verification failed with $($errors.Count) error(s)."
}

Write-Output "Agent scaffold verification passed with $($warnings.Count) warning(s)."
