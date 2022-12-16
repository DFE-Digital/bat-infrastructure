[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 1)]
    [String]$YamlFile,
    [Parameter(Mandatory = $false)]
    [Int]$TimeoutSeconds = 2 * 60
)

$ErrorActionPreference = "Stop"

Import-Module powershell-yaml

function Invoke-NativeCommand() {
    $command = $args[0]
    $commandArgs = @()
    if ($args.Count -gt 1) {
        $commandArgs = $args[1..($args.Count - 1)]
    }

    $output = (& $command $commandArgs) -join "`n"
    $result = $LASTEXITCODE

    if ($result -ne 0) {
        throw "$command $commandArgs exited with code $result."
    }

    return $output
}

$definition = ConvertFrom-Yaml ((Get-Content $YamlFile) -join "`n")
$appName = $definition.name
$resourceGroup = $definition.resourcegroup
$environment = $definition.properties.managedEnvironmentId


# Does the app exist already?

$appExists = (Invoke-NativeCommand az containerapp list --environment $environment -g $resourceGroup --query "[?name == '$appName']") -ne '[]'


# If there's already an active revision ensure it continues to receive all the traffic until the new revision has successfully started

$definition.properties.configuration.ingress.traffic = @()

$haveExistingActiveRevisions = $false

if ($appExists -eq $true) {
    $existingRevisions = ConvertFrom-Json (Invoke-NativeCommand az containerapp revision list --name $appName -g $resourceGroup)

    foreach ($r in $existingRevisions) {
        $trafficWeight = $r.properties.trafficWeight
        if ($trafficWeight -eq 0) {
            continue
        } else {
            $haveExistingActiveRevisions = $true
            $definition.properties.configuration.ingress.traffic += @{
                revisionName = $r.name
                weight = $r.properties.trafficWeight
            }
        }
    }
}

$definition.properties.configuration.ingress.traffic += @{
    latestRevision = $true
    weight = $(if ($haveExistingActiveRevisions -eq $true) { 0 } else { 100 })
}


# Create the new revision

$tempYamlPath = New-TemporaryFile
(ConvertTo-Yaml $definition) | Out-File $tempYamlPath

$action = if ($appExists -eq $true) { "update" } else { "create" }
(Invoke-NativeCommand az containerapp $action -n $AppName -g $resourceGroup --yaml $tempYamlPath --only-show-errors) | Out-Null
$revision = (Invoke-NativeCommand az containerapp show -n $AppName -g $resourceGroup --query "properties.latestRevisionName" -o tsv)


# Wait for the new revision to spin up successfully

$timer = [Diagnostics.Stopwatch]::StartNew()
while ($true) {
    $containerRevision = (ConvertFrom-Json (Invoke-NativeCommand az containerapp revision show --revision $revision --name $appName -g $resourceGroup))
    $healthState = $containerRevision.properties.healthState
    $provisioningState = $containerRevision.properties.provisioningState
    $replicas = $containerRevision.properties.replicas

    if ($provisioningState -eq "Failed" -or $healthState -eq "Unhealthy" -or ($replicas -eq 0 -and $provisioningState -eq "Provisioned")) {
        Write-Error "Container provisioning failed for revision $revision; provisioning state: '$provisioningState', health state: '$healthState'."
        exit 1
    }

    if ($provisioningState -eq "Provisioned") {
        break
    }

    if ($timer.ElapsedMilliseconds -gt ($timeoutSeconds * 1000)) {
        Write-Error "Timed out waiting for container to prevision successfully"
        exit 1
    }

    Start-Sleep 5
}


# Swap 100% traffic to the new revision and deactivate older revisions

if ($haveExistingActiveRevisions -eq $true) {
    Invoke-NativeCommand az containerapp ingress traffic set --name $appName -g $resourceGroup --revision-weight latest=100 | Out-Null

    foreach ($r in $existingRevisions) {
        if ($r.name -ne $revision) {
            Invoke-NativeCommand az containerapp revision deactivate --revision $r.name --name $appName -g $resourceGroup | Out-Null
        }
    }
}