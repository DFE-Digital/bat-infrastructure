<#
.SYNOPSIS
Gets review apps from a CloudFoundry space and state data from the associated GitHub Pull Request.

.DESCRIPTION
Gets review apps from a CloudFoundry space and state data from the associated GitHub Pull Request.
Uses the cf and gh command line utilties to get data from CloudFoundry and GitHub, you must already be authenticated with using those utilities for the script to work.

.PARAMETER CfSpace
(optional) Defaults to bat-qa.  The script relies on hardcoded metadata in the $Metadata variable to map CloudFoundry apps to GitHub repos.  To use this script in a different
space you will need to modify $MetaData

.PARAMETER GitHubOrg
(optional) Defaults to DFE-Digital

.EXAMPLE
$Apps = ./Get-ReviewAppPullRequestState.ps1
$Apps | Where-Object { $_.PRState -ne $null -and $_.PRState -ne "OPEN" } | Format-Table
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [String]$CfSpace = "bat-qa",
    [Parameter(Mandatory=$false)]
    [String]$GitHubOrg = "DFE-Digital"
)

class CfApp {
    [String]$Name
    [String]$RequestedStatus
    [String]$Processes
    [String]$PRCreatedDate
    [String]$PRClosedDate
    [String]$PRState
}

$Metadata = @(
    @{ CfAppPrefix = "apply"; GitHubRepoName = "apply-for-teacher-training" },
    @{ CfAppPrefix = "find"; GitHubRepoName = "find-teacher-training" },
    @{ CfAppPrefix = "publish"; GitHubRepoName = "publish-teacher-training" },
    @{ CfAppPrefix = "register"; GitHubRepoName = "register-trainee-teachers" },
    @{ CfAppPrefix = "teacher"; GitHubRepoName = "teacher-training-api" }
)

cf target -s $CfSpace | Out-Null

$CfAppOutput = cf apps

$CfApps = @()

$FoundTableHeader = $false
foreach ($Row in $CfAppOutput) {
    if ($Row -match "name\s*requested\sstate\s*processes\s*routes") {
        $FoundTableHeader = $true
        continue
    }

    if ($FoundTableHeader) {
        $Row -match "^(\S+)\s+(\S+)\s+(\S+)" | Out-Null
        $CfApps += New-Object -TypeName CfApp -Property @{ Name = $Matches[1]; RequestedStatus = $Matches[2]; Processes = $Matches[3] }
        Remove-Variable -Name Matches -ErrorAction SilentlyContinue
    }
}

foreach ($App in $CfApps) {
    Write-Verbose "Checking if app $($App.Name) is a review app"
    if ($App.Name -match "^(\w+)-.+-(\d+)$") {
        $AppPrefix = $Matches[1]
        $PRNumber = $Matches[2]
        $RepoName = ($Metadata | Where-Object { $_.CfAppPrefix -match $AppPrefix } | Select-Object -Property GitHubRepoName).GitHubRepoName
        Write-Verbose "Getting state for PR $PRNumber from $GitHubOrg/$RepoName"
        $PRData = gh pr view $PRNumber -R $GitHubOrg/$RepoName --json state,closedAt,createdAt | ConvertFrom-Json
        $App.PRCreatedDate = $PRData.CreatedAt
        $App.PRClosedDate = $PRData.ClosedAt
        $App.PRState = $PRData.State
        Write-Verbose "PR $PRNumber has state $($App.PRState)"
        Start-Sleep -Seconds 2
    }
    Remove-Variable Matches -ErrorAction SilentlyContinue
}

$CfApps
