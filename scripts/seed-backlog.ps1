[CmdletBinding()]
param()

# Creates the default project setup tasks through the Backlog.md CLI. Runs once
# per project: it does nothing when the backlog already has tasks. Output is a
# single JSON object.

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Write-Result([hashtable]$Result) {
    $Result | ConvertTo-Json -Compress -Depth 4 | Write-Output
}

if (-not (Get-Command 'backlog' -ErrorAction SilentlyContinue)) {
    Write-Result @{ status = 'error'; reason = 'backlog CLI not found on PATH.'; fix = 'See .ai/shared/instructions/tool-prerequisites.md' }
    exit 1
}

Push-Location $repositoryRoot
try {
    $existing = (& backlog task list --plain 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        Write-Result @{ status = 'error'; reason = "backlog task list failed: $($existing.Trim())"; fix = 'Run task backlog:init first.' }
        exit 1
    }
    if ($existing -match 'TASK-\d+') {
        Write-Result @{ status = 'skipped'; reason = 'Backlog already has tasks; seeding runs only on an empty backlog.' }
        exit 0
    }

    $created = [ordered]@{}

    function New-SeedTask([string]$Key, [string]$Title, [string]$Priority, [string]$Description, [string[]]$Criteria, [string[]]$DependsOn) {
        $arguments = @('task', 'create', $Title, '--type', 'chore', '--priority', $Priority, '--labels', 'project-setup', '--description', $Description)
        foreach ($criterion in $Criteria) {
            $arguments += @('--ac', $criterion)
        }
        $dependencyIds = @($DependsOn | Where-Object { $_ } | ForEach-Object { $created[$_] })
        if ($dependencyIds.Count -gt 0) {
            $arguments += @('--dep', ($dependencyIds -join ','))
        }
        $arguments += '--plain'
        $output = (& backlog @arguments 2>&1 | Out-String)
        $idMatch = [regex]::Match($output, 'Task (TASK-\d+)')
        if ($LASTEXITCODE -ne 0 -or -not $idMatch.Success) {
            throw "backlog task create failed for '$Title': $($output.Trim())"
        }
        $created[$Key] = $idMatch.Groups[1].Value
    }

    New-SeedTask 'context' 'Complete the project context' 'high' `
        'Agents read .ai/shared/instructions/project-context.md at the start of every session. While it says "Status: template", they must ask for facts instead of acting. Capture the facts once so every session starts informed.' `
        @(
            'Every field in .ai/shared/instructions/project-context.md has a factual value confirmed by the user, not inferred',
            'The "Status: template" line is replaced with the current project status',
            'Key commands and verification lists the real build, lint and test commands, or states that none exist yet'
        )

    New-SeedTask 'intents' 'Capture project intents and core acceptance criteria in Backlog' 'high' `
        'Capture initial project requirements, real-world examples, and acceptance criteria through Backlog tasks and documents or an on-demand INTENTS.md, keeping the workspace free of rotting PRD/SPECS boilerplate.' `
        @(
            'Initial features, technical choices, and expected outcomes are recorded in Backlog tasks or INTENTS.md',
            'Out-of-scope boundaries are clearly identified to prevent agent drift',
            'Verification commands (build, lint, test) are captured in project context or backlog config'
        ) @('context')

    $definitionOfDoneBaseline = @'
A shared Definition of Done stops work from being called finished when it is only written. Backlog.md adds the project Definition of Done to every new task.

Baseline to adapt:

1. Acceptance criteria verified with evidence: test output, a command result, or a screenshot.
2. Build, lint, and tests pass locally with the documented project commands.
3. New or changed behavior is covered by automated tests.
4. README or inline docs updated when behavior or setup changes.
5. No secrets, credentials, or personal data committed.
6. The diff was self-reviewed or reviewed in a pull request.
7. The Backlog task has a final summary naming the verification evidence.

Examples of project-specific items:

- "Lighthouse accessibility score of 90 or higher on changed pages" (web UI)
- "Database migration runs forward and back on a copy of production data" (services)
- "Public API changes are recorded in CHANGELOG.md" (libraries)
'@

    New-SeedTask 'dod' 'Establish the project Definition of Done' 'high' `
        $definitionOfDoneBaseline `
        @(
            'The user has agreed on a Definition of Done list adapted from the baseline in this task',
            'The list is recorded under definition_of_done in backlog.config.yml so new tasks inherit it',
            'Every item can be checked objectively (a command, an artifact or a review), not by opinion'
        ) @('intents')

    New-SeedTask 'readme' 'Write the README for human readers' 'medium' `
        'README.md still contains the scaffold template. The README is for people (users, contributors, reviewers); agents take their instructions from AGENTS.md. Follow the section guide inside README.md and delete the template notice when done.' `
        @(
            'README.md opens with the project name, a one-line description and, if available, a logo',
            'Purpose, features, quickstart, usage, development, contributing and license sections are filled in or deliberately removed',
            'At least one screenshot or demo GIF is included for user-facing projects, or the README states why none applies',
            'A documentation or demo site (for example GitHub Pages) is linked if one exists',
            'The quickstart works when followed step by step from a clean clone',
            'The YABA template notice and the remaining HTML guidance comments are removed'
        ) @('intents')

    New-SeedTask 'commit' 'Make the initial commit' 'medium' `
        'Bootstrap leaves the project uncommitted so the user can review it first. AGENTS.md requires explicit approval before any commit or push.' `
        @(
            'task verify-bootstrap passes',
            'The user reviewed git status and approved the initial commit',
            'The commit is pushed to origin only after the user approves the push'
        ) @('context', 'intents', 'dod', 'readme')

    Write-Result @{ status = 'seeded'; tasks = $created }
}
catch {
    Write-Result @{ status = 'error'; reason = $_.Exception.Message; created = $created }
    exit 1
}
finally {
    Pop-Location
}
