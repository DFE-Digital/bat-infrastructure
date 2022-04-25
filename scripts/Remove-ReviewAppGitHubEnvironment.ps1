<#
.SYNOPSIS
Deletes review app GitHub environments.

.DESCRIPTION
Gets all the environments associated with a GitHub repo and where their name includes a number checks the state of the associated PR,
deletes the enviroment if the PR is merged or closed.

.PARAMETER GitHubOrg
(optional) Defaults to DFE-Digital

.EXAMPLE
To see what environments will be deleted:
Import-Module c/path/to/das/gitbub/toolkit -Force
cd ./my-repo
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
../bat-infrastructure/scripts/Remove-ReviewAppGitHubEnvironment.ps1 -WhatIf

.EXAMPLE
To delete environments, you will be prompted to confirm each deletion, enter A to delete all environments
Import-Module c/path/to/das/gitbub/toolkit -Force
cd ./my-repo
Set-GitHubSessionInformation -PatToken <not-a-real-pat-token>
../bat-infrastructure/scripts/Remove-ReviewAppGitHubEnvironment.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory=$false)]
    [String]$GitHubOrg = "DFE-Digital"
)

Begin {
    $InformationPreference = "Continue"

    $RepoName = Split-Path -LeafBase (git remote get-url origin)
    Write-Verbose "Getting environments for $GitHubOrg/$RepoName"
    $Environments = Get-GitHubEnvironment -GitHubOrg $GitHubOrg -GitHubRepo $RepoName

    Write-Information "Retrieved $($Environments.Count) environments for $GitHubOrg/$RepoName"
}

Process {
    foreach ($Environment in $Environments) {
        Remove-Variable -Name Matches -ErrorAction SilentlyContinue -WhatIf:$false
        Write-Verbose "Checking if environment $($Environment.name) is a review app"
        if ($Environment.name -match "\d{1,4}") {
            $PRNumber = $Matches[0]
            if ($PRNumber) {
                Write-Verbose "Environment name contains PR number $PRNumber, getting PR"
                $PRData = gh pr view $PRNumber -R $GitHubOrg/$RepoName --json state,closedAt,createdAt | ConvertFrom-Json
                Remove-Variable -Name Matches -WhatIf:$false
                Write-Verbose "PR state is $($PRData.State)"
                if ($PRData.State -match "^CLOSED$|^MERGED$") {
                    if ($PSCmdlet.ShouldProcess($Environment.name, "gh environments delete")) {
                        Write-Warning "PR $PRNumber is $($Matches[0]), deleting environment $($Environment.name)"
                        gh environments delete $Environment.name --force
                        Start-Sleep -Seconds 1 ## to avoid rate limiting
                    }
                }
                Remove-Variable -Name PRNumber -WhatIf:$false
            }
        }
    }
}
