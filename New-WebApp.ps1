. ".\Includes.ps1"

function Get-Confirmation {
    param (
        [string] $title,
        [string] $prompt
    )
    $options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No", "&Cancel")
    switch ($Host.UI.PromptForChoice($title, $prompt, $options, 0)) {
        0 { return $true }
        1 { return $false }
        2 { Exit-PSSession }
    }
}

## Confirm subscription
function Get-Subscription {
    $subscriptions = Get-AzSubscription
    $defaultSubscription = Select-Object $subscriptions -First 1
    if (Get-Confirmation("Subscription options: ", "Do you want to use {0}?" -f ($defaultSubscription.Name))) {
        return $defaultSubscription
    }
    $names = [string[]] (Select-Object $subscriptions -ExpandProperty Name)
    $name = Get-Choice "Which subscription do you want to use?", $names
    return $subscriptions[$names.IndexOf($name)]
}

function Get-Location {
    $defaultLocation = Get-AzStorageAccount | Select-Object -ExpandProperty Location -First 1
    if (Get-Confirmation("Use default location?", "Do you want to use $defaultLocation to host your site?")) {
        return $defaultLocation
    }
    else {
        $locations = Get-AzLocation |
        Where-Object { $_.Providers.Contains("Microsoft.Web") -eq $true } |
        Select-Object -ExpandProperty Location
        Write-Host "Here are the available locations:"
        Write-Host $locations.Join(", ")
        return Select-Location($locations)
    }
}

function Select-Location {
    param (
        $locations,
        [int] $attempt = 0
    )
    $location = Read-Host "Please enter the name of the location you wish to use: "
    if ($locations.Contains($location)) {
        return $location
    }
    else {
        if (++$attempt -gt 2) {
            Write-Host "We seem to be crossing our signals here. Exiting..."
            Exit-PSSession
        }
        return Select-Location($locations, $attempt)
    }
}

function Get-AppServicePlan {
    Write-Host("Loading service plans...")
    $servicePlans = Get-AzAppServicePlan

    if($servicePlans.Length -eq 0) {
        Write-Host("You have no service plans yet. Let's create one.")
        return New-AppServicePlan
    }

    $defaultServicePlan = $servicePlans | Select-Object -First 1 `
                                            -Property Name, `
                                            @{Name="Sku"; Expression={"{0} - {1}" -f ($_.Sku.Tier, $_.Sku.Name)}}
    if (Get-Confirmation("Service plan - ",
            "Do you want to use '{0}:{1}' to host your site?" `
                -f ($defaultServicePlan.Name, $defaultServicePlan.Sku))
    ) {
        return $servicePlans[0];
    }

    $servicePlanNames = New-Object System.Collections.ArrayList
    $servicePlans | ForEach-Object {
        $servicePlanNames.Add("{0} ({1} - {2})" -f ($_.Name, $_.Sku.Tier, $_.Sku.Name)) > $null
    }
    $servicePlanNames.Add("Create new App Service Plan") > $null

    $servicePlanName = (Get-Choice "Choose a service plan", [String[]] $servicePlanNames.ToArray())
    $servicePlanIndex = $servicePlanNames.IndexOf($servicePlanName)

    if ($servicePlanIndex -eq $servicePlans.Count) {
        return New-AppServicePlan
    }
    return $servicePlans[$servicePlanIndex]
}

function New-AppServicePlan {
    $name = Read-Host("What do you want to name the service plan?")
    $tiers = ("&Free", "&Standard")
    $tierIndex = $Host.UI.PromptForChoice(
        "App Service Plan Tier - ",
        "Which tier would you like to use?",
        [System.Management.Automation.Host.ChoiceDescription[]] $tiers,
        0
    )
    $tier = $tiers[$tierIndex].Substring(1)
    $resourceGroup = Get-ResourceGroup
    return New-AzAppServicePlan `
        -Name $name -Location $resourceGroup.Location `
        -ResourceGroupName $resourceGroup.ResourceGroupName -Tier $tier
}

function Get-ResourceGroup {
    $resourceGroups = Get-AzResourceGroup
    if ($resourceGroups.Length -gt 0) {
        if (Get-Confirmation("Resource group options - ", "Do you want to use {0}?" -f $resourceGroups[0].ResourceGroupName)) {
            return $resourceGroups[0]
        }
        else {
            $names = New-Object System.Collections.ArrayList
            $resourceGroups | Select-Object -ExpandProperty ResourceGroupName | ForEach-Object {
                $names.Add($_) > $null
            }
            $names.Add("Create new") > $null
            $name = Get-Choice "What resource group do you want to use?", [String[]] $names.ToArray()
            if($names.IndexOf($name) -eq $names.Count - 1) {
                New-ResourceGroup
            }
            return $resourceGroups[$names.IndexOf($name)]
        }
    }
}

function New-ResourceGroup {
    $name = Read-Host "What do you want to call your resource group?"
    $location = Get-Location
    return New-AzResourceGroup $name $location
}

$name = Read-Host("What would you like to call it?")
$plan = Get-AppServicePlan
Write-Host $plan
New-AzWebApp -WhatIf -Name $name -Location $plan.Location -AppServicePlan $plan.Name -ResourceGroupName $plan.ResourceGroup
