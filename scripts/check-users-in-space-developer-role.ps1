#!/usr/bin/env pwsh
[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(Mandatory=$true)]
  [string]$Space,
  [Parameter(Mandatory=$true)]
  [string]$SlackWebhook,
  [Parameter(Mandatory=$false)]
  [switch]$Unset,
  [Parameter(Mandatory=$false)]
  [string]$Whitelist
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

function Get-RolesToBeDeleted {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Space,
    [Parameter(Mandatory=$true)]
    [hashtable]$Headers,
    [Parameter(Mandatory=$false)]
    [array]$ProtectedUserNames
  )

  $SpaceDetails = Invoke-RestMethod -Uri "https://api.london.cloud.service.gov.uk/v3/spaces?names=$Space" -Headers $Headers
  $SpaceGuid = $SpaceDetails.resources[0].guid

  $Roles = Invoke-RestMethod -Uri "https://api.london.cloud.service.gov.uk/v3/roles?space_guids=$SpaceGuid&types=space_developer" -Headers $Headers

  if (!$ProtectedUserNames) {
    $Roles.resources
  }
  else {
    $ProtectedUsers = Invoke-RestMethod -Uri "https://api.london.cloud.service.gov.uk/v3/users?usernames=$($ProtectedUserNames -join ',')" -Headers $Headers
    $Roles.resources | Where-Object { $_.relationships.user.data.guid -notin $ProtectedUsers.resources.guid }
  }
}

function Remove-Role {
  param (
    [Parameter(Mandatory=$true)]
    [array]$RolesToBeDeleted,
    [Parameter(Mandatory=$true)]
    [hashtable]$Headers
  )

  foreach ($Role in $RolesToBeDeleted.guid) {
    Write-Information "Deleting role $Role"
    Invoke-RestMethod -StatusCodeVariable Status -Method Delete -Uri "https://api.london.cloud.service.gov.uk/v3/roles/$Role" -Headers $Headers
    if ($Status -eq 202) {
      Write-Information "Deleted role"
    }
    else {
      Write-Information "Failed to delete role: status code $Status"
    }
  }
}

function Write-SlackMessage {
  param (
    [Parameter(Mandatory=$true)]
    [hashtable]$Headers,
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [Parameter(Mandatory=$true)]
    [array]$RolesToBeDeleted,
    [Parameter(Mandatory=$true)]
    [string]$SlackWebhook
  )

  $UsersIdsCsv = $RolesToBeDeleted.relationships.user.data.guid -join ','
  $Users = Invoke-RestMethod -Uri "https://api.london.cloud.service.gov.uk/v3/users?guids=$UsersIdsCsv" -Headers $Headers

  $Body = ConvertTo-Json -InputObject @{
    text = "$Message`n$($Users.resources.username -join "`n")`n`nTo resolve SSO Ids, please visit:`nhttps://dfedigital.atlassian.net/wiki/spaces/BaT/pages/1935048705/Single+sign-on+SSO"
    type = "mrkdwn"
  }

  Write-Information "Posting to Slack $Message"
  $Response = Invoke-RestMethod -Uri $SlackWebhook -Method Post -Body $Body -ContentType 'application/json'
  Write-Information $Response
}

function Invoke-RoleProcessing {
  param (
    [Parameter(Mandatory=$true)]
    [array]$RolesToBeDeleted,
    [Parameter(Mandatory=$true)]
    [hashtable]$Headers,
    [Parameter(Mandatory=$true)]
    [string]$SlackWebhook,
    [Parameter(Mandatory=$true)]
    [string]$Space,
    [Parameter(Mandatory=$false)]
    [switch]$Unset
  )

  if ($Unset.IsPresent) {
    Remove-Role -RolesToBeDeleted $RolesToBeDeleted -Headers $Headers
    $Message = ":warning: The following users had SpaceDeveloper role revoked in PaaS space $Space`:"
  }
  else {
    $Message = ":warning: The following users have the SpaceDeveloper role in PaaS space $Space`:"
  }

  Write-SlackMessage -Message $Message -Headers $Headers -RolesToBeDeleted $RolesToBeDeleted -SlackWebhook $SlackWebhook
}

$Bearer = cf oauth-token
$Headers = @{
  Authorization = "$Bearer"
  Accept        = "application/json"
}

if ($Whitelist) {
  $ProtectedUserNames = $Whitelist.Split(",")
  $RolesToBeDeleted = Get-RolesToBeDeleted -Space $Space -Headers $Headers -ProtectedUserNames $ProtectedUserNames
}
else {
  $RolesToBeDeleted = Get-RolesToBeDeleted -Space $Space -Headers $Headers
}

Write-Information "Retrieved $($RolesToBeDeleted.count) roles"
if ($RolesToBeDeleted.count -gt 0) {
  if ($Unset.IsPresent) {
    Invoke-RoleProcessing -RolesToBeDeleted $RolesToBeDeleted -Headers $Headers -SlackWebhook $SlackWebhook -Space $Space -Unset
  }
  else {
    Invoke-RoleProcessing -RolesToBeDeleted $RolesToBeDeleted -Headers $Headers -SlackWebhook $SlackWebhook -Space $Space
  }
  
}
