#!/usr/bin/env pwsh

param([String] $space, [String] $slackwebhook)

$data = @()

$bearer = $(cf oauth-token)

$headers = @{
  Authorization = "$bearer"
  Accept        = "application/json"
}

$get_space_details = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/spaces?names=$space"  -H $headers
$space_guid = $get_space_details.resources[0].guid

$get_space_details = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/roles?space_guids=$space_guid&types=space_developer"  -H $headers

$get_developer_ids = $get_space_details.resources.relationships.user.data.guid

Foreach ($id in $get_developer_ids) {
  $num += 1
  $user = Invoke-RestMethod "https://api.london.cloud.service.gov.uk/v3/users?guids=$id" -H $headers
  Write-Output $user.resources.username
  $data += $num.ToString() + (". ") + $user.resources.username + "`n"

 }

$uriSlack = $slackwebhook
$body = ConvertTo-Json @{
  text = ":warning: <!here>The following users have the SpaceDeveloper role in PaaS space $space : `n" + $data + "`n" + "To resolve SSO Ids, please visit `n https://dfedigital.atlassian.net/wiki/spaces/BaT/pages/1935048705/Single+sign-on+SSO"
  type = "mrkdwn"
}

write-host $body

Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json'
