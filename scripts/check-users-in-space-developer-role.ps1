#!/usr/bin/env pwsh

[CmdletBinding(PositionalBinding = $False)]
param([Parameter(Mandatory)] $space, [Parameter(Mandatory)] $slack_webhook, $unset, $whitelist)

$ErrorActionPreference = "Stop"
$bearer = $(cf oauth-token)

$headers = @{
  Authorization = "$bearer"
  Accept        = "application/json"
}

$UNSET = $unset -eq "true"
if ($UNSET -and $whitelist) {
  $PROTECTED_USERNAMES = $whitelist.Split(",")
}

function rolesToBeDeleted {
  param($space, $headers)

  $space_details = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/spaces?names=${space}" -H $headers
  $space_guid = $space_details.resources[0].guid

  $roles = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/roles?space_guids=${space_guid}&types=space_developer" -H $headers

  if (-not $PROTECTED_USERNAMES) {
    return $roles.resources
  }

  $protected_users = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/users?usernames=$($PROTECTED_USERNAMES -join ',')" -H $headers

  $roles.resources | Where-Object {
    $_.relationships.user.data.guid -notin $protected_users.resources.guid
  }
}

function deleteRoles {
  param ($roles_to_be_deleted, $headers)

  $roles_to_be_deleted.guid | ForEach-Object {
    Write-Host "Deleting role ${_}"
    Invoke-RestMethod -StatusCodeVariable "status" -Method Delete "https://api.london.cloud.service.gov.uk/v3/roles/${_}" -H $headers
    if ($status -eq 202) { Write-Host "ok" } else { Write-Host "Failed: status code ${status}" }
  }
}

function notify {
  param ($message, $headers, $roles_to_be_deleted)

  $users_ids_csv = $roles_to_be_deleted.relationships.user.data.guid -join ','
  $users = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/users?guids=${users_ids_csv}" -H $headers

  $body = ConvertTo-Json @{
    text = $message + "`n" +
      $($users.resources.username -join "`n") + "`n" + "`n" +
      "To resolve SSO Ids, please visit:`n" +
      "https://dfedigital.atlassian.net/wiki/spaces/BaT/pages/1935048705/Single+sign-on+SSO"
    type = "mrkdwn"
  }

  Write-Host "Posting to Slack"
  $response = Invoke-RestMethod -uri $slack_webhook -Method Post -body $body -ContentType 'application/json'
  Write-Host $response
}

function processRoles {
  param ($roles_to_be_deleted, $headers, $space, $unset)

  if ($unset) {
    deleteRoles $roles_to_be_deleted $headers
    $message = ":warning: The following users had SpaceDeveloper role revoked in PaaS space ${space}:"
  }
  else {
    $message = ":warning: The following users have the SpaceDeveloper role in PaaS space ${space}:"
  }

  notify $message $headers $roles_to_be_deleted
}

# BEGIN
$roles_to_be_deleted = rolesToBeDeleted $space $headers $UNSET

if ($roles_to_be_deleted.count -gt 0) {
  processRoles $roles_to_be_deleted $headers $space $UNSET
}
# END
