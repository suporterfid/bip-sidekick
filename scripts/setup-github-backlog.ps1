param(
    [string]$Repository = "suporterfid/bip-sidekick"
)

$ErrorActionPreference = "Stop"

function Invoke-Gh {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GhArguments
    )

    $attempts = 3

    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        $output = (& gh @GhArguments 2>&1) | Out-String

        if ($LASTEXITCODE -eq 0) {
            if (-not [string]::IsNullOrWhiteSpace($output)) {
                Write-Host $output.Trim()
            }

            return
        }

        $isTransient = $output -match "502|503|504|timed out|couldn't respond to your request in time"
        if ($isTransient -and $attempt -lt $attempts) {
            Start-Sleep -Seconds (2 * $attempt)
            continue
        }

        throw "gh $($GhArguments -join ' ') failed with exit code $LASTEXITCODE.`n$output"
    }
}

function Invoke-GhJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GhArguments
    )

    $attempts = 3

    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        $output = (& gh @GhArguments 2>&1) | Out-String

        if ($LASTEXITCODE -eq 0) {
            if ([string]::IsNullOrWhiteSpace($output)) {
                return $null
            }

            return $output | ConvertFrom-Json
        }

        $isTransient = $output -match "502|503|504|timed out|couldn't respond to your request in time"
        if ($isTransient -and $attempt -lt $attempts) {
            Start-Sleep -Seconds (2 * $attempt)
            continue
        }

        throw "gh $($GhArguments -join ' ') failed with exit code $LASTEXITCODE.`n$output"
    }
}

function Ensure-Label {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Label
    )

    Invoke-Gh -GhArguments @(
        "label", "create", $Label.Name,
        "--repo", $Repository,
        "--color", $Label.Color,
        "--description", $Label.Description,
        "--force"
    )
}

function Ensure-Issue {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Definition,
        [Parameter(Mandatory = $true)]
        [hashtable]$IssueLookup
    )

    if ($IssueLookup.ContainsKey($Definition.Title)) {
        return $IssueLookup[$Definition.Title]
    }

    $arguments = @(
        "issue", "create",
        "--repo", $Repository,
        "--title", $Definition.Title,
        "--body", $Definition.Body
    )

    foreach ($label in $Definition.Labels) {
        $arguments += @("--label", $label)
    }

    Invoke-Gh -GhArguments $arguments
    return $null
}

function Add-LabelsToIssue {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Number,
        [Parameter(Mandatory = $true)]
        [string[]]$Labels
    )

    $arguments = @(
        "issue", "edit", $Number.ToString(),
        "--repo", $Repository
    )

    foreach ($label in $Labels) {
        $arguments += @("--add-label", $label)
    }

    Invoke-Gh -GhArguments $arguments
}

$labels = @(
    @{ Name = "backlog"; Description = "Long-lived planned work and future topics"; Color = "0E8A16" },
    @{ Name = "needs-triage"; Description = "Newly captured item that still needs sorting"; Color = "FBCA04" },
    @{ Name = "next-up"; Description = "Small near-term shortlist"; Color = "1D76DB" },
    @{ Name = "priority:high"; Description = "Highest relative priority"; Color = "B60205" },
    @{ Name = "priority:medium"; Description = "Medium relative priority"; Color = "D93F0B" },
    @{ Name = "priority:low"; Description = "Lower relative priority"; Color = "0E8A16" },
    @{ Name = "effort:s"; Description = "Small implementation size"; Color = "C2E0C6" },
    @{ Name = "effort:m"; Description = "Medium implementation size"; Color = "F9D0C4" },
    @{ Name = "effort:l"; Description = "Large implementation size"; Color = "F7C6C7" },
    @{ Name = "area:runtime"; Description = "Hermes runtime, compose, or packaging"; Color = "5319E7" },
    @{ Name = "area:briefing"; Description = "Daily brief and summarization flow"; Color = "0E8A16" },
    @{ Name = "area:governance"; Description = "Approvals, audit, and safety posture"; Color = "BFD4F2" },
    @{ Name = "area:integrations"; Description = "Google, OpenWA, Telegram, or MCP wiring"; Color = "0052CC" },
    @{ Name = "area:docs"; Description = "README, ADRs, and workflow documentation"; Color = "0075CA" }
)

$issuePlans = @{
    "Hermes-native runtime package and Docker deployment" = @("backlog", "next-up", "priority:high", "effort:l", "area:runtime")
    "Bip identity source: vault/BIP.md generates Hermes SOUL.md" = @("backlog", "priority:high", "effort:m", "area:runtime")
    "Compose migration: replace agent, telegram-bridge, and brief-engine with Hermes" = @("backlog", "priority:high", "effort:l", "area:runtime")
    "Hermes Telegram gateway allowlist and manual approvals" = @("backlog", "next-up", "priority:high", "effort:l", "area:governance")
    "Read-only MCP integration and tool filtering" = @("backlog", "priority:medium", "effort:l", "area:integrations")
    "Daily brief cron in Hermes" = @("backlog", "next-up", "priority:high", "effort:m", "area:briefing")
    "Container-scoped shell for Hermes with approval guardrails" = @("backlog", "priority:medium", "effort:m", "area:governance")
    "Append-only audit mirror for approvals and executed actions" = @("backlog", "priority:high", "effort:m", "area:governance")
    "Gated send and deploy hands for Stage 5" = @("backlog", "priority:low", "effort:l", "area:governance")
    "Documentation and ADR update for Hermes-native architecture" = @("backlog", "priority:medium", "effort:m", "area:docs")
}

$projectBootstrapIssue = @{
    Title = "Provision GitHub Project backlog and saved views"
    Body = @"
## Goal
Create the repository-owned GitHub Project that mirrors the workflow documented in `docs/GITHUB_BACKLOG.md`.

## Requirements
- Refresh GitHub auth with `read:project` and `project`.
- Create a project named `Bip Sidekick Backlog`.
- Link `suporterfid/bip-sidekick` to the project.
- Add the `Priority`, `Area`, `Effort`, and `Target` fields described in `docs/GITHUB_BACKLOG.md`.
- Add the open backlog issues to the project.

## Acceptance criteria
- The project exists under the repository owner.
- The repository is linked to the project.
- Open backlog issues can be viewed through `Inbox`, `Backlog`, and `Next` filters in the GitHub UI.
"@
    Labels = @("backlog", "priority:medium", "effort:s", "area:docs")
}

$authStatus = (& gh auth status 2>&1) | Out-String

foreach ($label in $labels) {
    Ensure-Label -Label $label
}

$issues = Invoke-GhJson -GhArguments @(
    "issue", "list",
    "--repo", $Repository,
    "--state", "all",
    "--limit", "200",
    "--json", "number,title"
)

$issueLookup = @{}
foreach ($issue in $issues) {
    $issueLookup[$issue.title] = $issue
}

Ensure-Issue -Definition $projectBootstrapIssue -IssueLookup $issueLookup | Out-Null

$issues = Invoke-GhJson -GhArguments @(
    "issue", "list",
    "--repo", $Repository,
    "--state", "all",
    "--limit", "200",
    "--json", "number,title"
)

$issueLookup = @{}
foreach ($issue in $issues) {
    $issueLookup[$issue.title] = $issue
}

foreach ($title in $issuePlans.Keys) {
    if (-not $issueLookup.ContainsKey($title)) {
        Write-Warning "Skipping missing issue: $title"
        continue
    }

    Add-LabelsToIssue -Number $issueLookup[$title].number -Labels $issuePlans[$title]
}

if ($authStatus -match "read:project" -and $authStatus -match "(^|[', ])project([', ]|$)") {
    Write-Host "Project scopes are available. Create or update 'Bip Sidekick Backlog' with gh project commands."
    Write-Host "Use docs/GITHUB_BACKLOG.md for the exact field layout and saved views."
}
else {
    Write-Warning "GitHub Project scopes are missing. Run 'gh auth refresh -s read:project -s project' and rerun this script when you want to bootstrap the Project."
}
