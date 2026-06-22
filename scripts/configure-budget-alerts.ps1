param(
  [Parameter(Mandatory = $true)]
  [string[]]$ContactEmails,
  [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
  [string]$BudgetName = "azure-billing-dashboard-monthly-budget",
  [double]$Amount = 2.6,
  [int[]]$Thresholds = @(50, 75, 90)
)

$ErrorActionPreference = "Stop"

if (-not $SubscriptionId) {
  $account = az account show --output json | ConvertFrom-Json
  $SubscriptionId = $account.id
}

$now = Get-Date
$startDate = Get-Date -Year $now.Year -Month $now.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate = $startDate.AddYears(10).AddMonths(1).AddDays(-1)
$notifications = @{}

foreach ($threshold in $Thresholds) {
  $notifications["Actual_GreaterThan_${threshold}_Percent"] = @{
    enabled = $true
    operator = "GreaterThan"
    threshold = $threshold
    thresholdType = "Actual"
    contactEmails = $ContactEmails
  }
}

$body = @{
  properties = @{
    category = "Cost"
    amount = $Amount
    timeGrain = "Monthly"
    timePeriod = @{
      startDate = $startDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
      endDate = $endDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    notifications = $notifications
  }
} | ConvertTo-Json -Depth 10

$bodyPath = Join-Path $env:TEMP "azure-budget-alerts.json"
Set-Content -LiteralPath $bodyPath -Value $body -NoNewline
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Consumption/budgets/${BudgetName}?api-version=2023-11-01"
az rest --method put --headers Content-Type=application/json --uri $uri --body "@$bodyPath" --output json
if ($LASTEXITCODE -ne 0) {
  throw "Azure Budget configuration failed."
}

Write-Host "Configured budget '$BudgetName' for $Amount with thresholds: $($Thresholds -join ', ')"