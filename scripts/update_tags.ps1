#!/usr/bin/env pwsh

# Install Az module if not installed
if ( -not (Get-InstalledModule -Name Az)) {
    Install-Module  -Name Az
}

# Login to Azure if not authenticated yet
if ( -not (Get-AzContext)) {
    Connect-AzAccount
}

function Set-TagsOnResourceGroup {
    param(
        [string]$SubscriptionName,
        [string]$ResourceGroupName,
        [hashtable]$Tags
    )

    Set-AzContext -Subscription $SubscriptionName
    $resource_groups = Get-AzResourceGroup -Name $ResourceGroupName

    $resource_groups.foreach{
        Write-Host "Adding tags to" $_.ResourceGroupName
        $_ | Set-AzResourceGroup -Tag $Tags
    }
}

# s105
$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="School experience service";
    "Environment"="Dev";
}
Set-TagsOnResourceGroup -SubscriptionName "s105-schoolexperience-development" -ResourceGroupName "s105d*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="School experience service";
    "Environment"="Test";
}
Set-TagsOnResourceGroup -SubscriptionName "s105-schoolexperience-test" -ResourceGroupName "s105t*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="School experience service";
    "Environment"="Prod";
}
Set-TagsOnResourceGroup -SubscriptionName "s105-schoolexperience-production" -ResourceGroupName "s105p*" -Tags $tags

# s106
$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Apply for postgraduate teacher training";
    "Environment"="Dev";
}
Set-TagsOnResourceGroup -SubscriptionName "s106-applyforpostgraduateteachertraining-development" -ResourceGroupName "s106d*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Apply for postgraduate teacher training";
    "Environment"="Test";
}
Set-TagsOnResourceGroup -SubscriptionName "s106-applyforpostgraduateteachertraining-test" -ResourceGroupName "s106t*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Apply for postgraduate teacher training";
    "Environment"="Prod";
}
Set-TagsOnResourceGroup -SubscriptionName "s106-applyforpostgraduateteachertraining-production" -ResourceGroupName "s106p*" -Tags $tags

# s121
$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Find postgraduate teacher training";
    "Environment"="Dev";
}
Set-TagsOnResourceGroup -SubscriptionName "s121-findpostgraduateteachertraining-development" -ResourceGroupName "s121d*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Find postgraduate teacher training";
    "Environment"="Test";
}
Set-TagsOnResourceGroup -SubscriptionName "s121-findpostgraduateteachertraining-test" -ResourceGroupName "s121t*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Teacher services";
    "Product"="Find postgraduate teacher training";
    "Environment"="Prod";
}
Set-TagsOnResourceGroup -SubscriptionName "s121-findpostgraduateteachertraining-production" -ResourceGroupName "s121p*" -Tags $tags

# s146
$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="Get into teaching website";
    "Environment"="Dev";
}
Set-TagsOnResourceGroup -SubscriptionName "s146-getintoteachingwebsite-development" -ResourceGroupName "s146d*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="Get into teaching website";
    "Environment"="Test";
}
Set-TagsOnResourceGroup -SubscriptionName "s146-getintoteachingwebsite-test" -ResourceGroupName "s146t*" -Tags $tags

$tags = @{
    "Portfolio"="Early Years and Schools Group";
    "Service Line"="Teaching Workforce";
    "Service"="Get into teaching";
    "Product"="Get into teaching website";
    "Environment"="Prod";
}
Set-TagsOnResourceGroup -SubscriptionName "s146-getintoteachingwebsite-production" -ResourceGroupName "s146p*" -Tags $tags
