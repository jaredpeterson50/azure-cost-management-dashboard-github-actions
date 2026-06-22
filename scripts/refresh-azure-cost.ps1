param(
  [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
  [string]$OutputPath = "public/billing-data.json"
)

$ErrorActionPreference = "Stop"

if (-not $SubscriptionId) {
  $account = az account show --output json | ConvertFrom-Json
  $SubscriptionId = $account.id
}

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
  throw "Azure Cost Management returned no cost rows for subscription $SubscriptionId."
}

$periodLabel = Get-Date -Format "MMMM yyyy"
$data = @{
  amount = [double]$row[0]
  currency = [string]$row[1]
  periodLabel = $periodLabel
  source = "azure-cost-management"
  subscriptionId = $SubscriptionId
  refreshedAt = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Depth 4

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $data -NoNewline
Write-Host "Wrote Azure billing data to $OutputPath"