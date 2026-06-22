param(
  [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
  [string]$OutputPath = "public/billing-data.json",
  [switch]$NoFallback
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Write-FallbackBillingData {
  param(
    [string]$OutputPath,
    [string]$Reason,
    [string]$PublicNote = "Azure Cost Management data is unavailable for this deployment, so the dashboard is showing fallback data."
  )

  $periodLabel = Get-Date -Format "MMMM yyyy"
  $data = @{
    amount = 0
    currency = "USD"
    periodLabel = $periodLabel
    source = "mock"
    refreshedAt = (Get-Date).ToUniversalTime().ToString("o")
    note = $PublicNote
  } | ConvertTo-Json -Depth 4

  $outputDirectory = Split-Path -Parent $OutputPath
  if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
  }

  Set-Content -LiteralPath $OutputPath -Value $data -NoNewline
  Write-Warning $Reason
  Write-Host "Wrote fallback billing data to $OutputPath"
}

if (-not $SubscriptionId) {
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $accountOutput = & az account show --output json 2>&1
  $accountExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference

  if ($accountExitCode -ne 0) {
    throw "Unable to read Azure account. az account show failed: $($accountOutput -join [Environment]::NewLine)"
  }

  $account = ($accountOutput -join [Environment]::NewLine) | ConvertFrom-Json
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
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$resultOutput = & az rest --method post --headers Content-Type=application/json --uri $uri --body "@$bodyPath" --output json 2>&1
$resultExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($resultExitCode -ne 0) {
  $reason = "Azure Cost Management query failed. This subscription may not support the Cost Management query API or may need more billing history. Azure CLI output: $($resultOutput -join [Environment]::NewLine)"

  if ($NoFallback) {
    throw $reason
  }

  Write-FallbackBillingData -OutputPath $OutputPath -Reason $reason
  exit 0
}

$resultJson = $resultOutput -join [Environment]::NewLine
$result = $resultJson | ConvertFrom-Json
$row = $result.properties.rows[0]

if (-not $row) {
  $reason = "Azure Cost Management returned no cost rows for this subscription."

  if ($NoFallback) {
    throw $reason
  }

  Write-FallbackBillingData -OutputPath $OutputPath -Reason $reason
  exit 0
}

$periodLabel = Get-Date -Format "MMMM yyyy"
$data = @{
  amount = [double]$row[0]
  currency = [string]$row[1]
  periodLabel = $periodLabel
  source = "azure-cost-management"
  refreshedAt = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Depth 4

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $data -NoNewline
Write-Host "Wrote Azure billing data to $OutputPath"