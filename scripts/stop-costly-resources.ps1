param(
  [double]$ThresholdAmount = 2.6,
  [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
  [string]$TagName = "AutoShutdown",
  [string]$TagValue = "true",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $SubscriptionId) {
  $account = az account show --output json | ConvertFrom-Json
  $SubscriptionId = $account.id
}

function Get-MonthToDateCost {
  param([string]$SubscriptionId)

  $bodyPath = Join-Path $env:TEMP "azure-cost-query.json"
  $query = @{
    type = "ActualCost"
    timeframe = "MonthToDate"
    dataset = @{
      granularity = "None"
      aggregation = @{
        totalCost = @{
          name = "Cost"
          function = "Sum"
        }
      }
    }
  } | ConvertTo-Json -Depth 8

  Set-Content -LiteralPath $bodyPath -Value $query -NoNewline
  $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/query?api-version=2023-11-01"
  $result = az rest --method post --headers Content-Type=application/json --uri $uri --body "@$bodyPath" --output json | ConvertFrom-Json
  $row = $result.properties.rows[0]

  if (-not $row) {
    throw "Azure Cost Management returned no month-to-date cost row."
  }

  return [pscustomobject]@{
    Amount = [double]$row[0]
    Currency = [string]$row[1]
  }
}

function Invoke-StopResource {
  param($Resource, [switch]$DryRun)

  $id = $Resource.id
  $name = $Resource.name
  $type = $Resource.type
  $resourceGroup = $Resource.resourceGroup

  switch ($type) {
    "Microsoft.Compute/virtualMachines" {
      $command = "az vm deallocate --ids `"$id`" --no-wait"
    }
    "Microsoft.Compute/virtualMachineScaleSets" {
      $command = "az vmss deallocate --ids `"$id`" --no-wait"
    }
    "Microsoft.Web/sites" {
      $command = "az webapp stop --ids `"$id`""
    }
    "Microsoft.ContainerService/managedClusters" {
      $command = "az aks stop --ids `"$id`" --no-wait"
    }
    "Microsoft.ContainerInstance/containerGroups" {
      $command = "az container stop --name `"$name`" --resource-group `"$resourceGroup`""
    }
    default {
      Write-Host "Skipping unsupported tagged resource: $name ($type)"
      return
    }
  }

  if ($DryRun) {
    Write-Host "DRY RUN: would run $command"
    return
  }

  Write-Host "Stopping $name ($type)"
  Invoke-Expression $command
}

$cost = Get-MonthToDateCost -SubscriptionId $SubscriptionId
Write-Host "Month-to-date Azure cost: $($cost.Amount) $($cost.Currency). Shutdown threshold: $ThresholdAmount $($cost.Currency)."

if ($cost.Amount -lt $ThresholdAmount) {
  Write-Host "Below threshold; no resources stopped."
  exit 0
}

$filter = "tagName eq '$TagName' and tagValue eq '$TagValue'"
$resources = az resource list --tag $filter --query "[?resourceGroup!='rg-azure-billing-dashboard']" --output json | ConvertFrom-Json

if (-not $resources -or $resources.Count -eq 0) {
  Write-Host "Threshold reached, but no resources are tagged $TagName=$TagValue outside rg-azure-billing-dashboard."
  exit 0
}

foreach ($resource in $resources) {
  Invoke-StopResource -Resource $resource -DryRun:$DryRun
}