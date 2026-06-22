param(
  [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
  [string]$StorageAccount = $env:AZURE_STORAGE_ACCOUNT
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command,
    [Parameter(Mandatory = $true)]
    [string]$ErrorMessage
  )

  $output = & $Command 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "$ErrorMessage`n$($output -join [Environment]::NewLine)"
  }

  return $output
}

if (-not $ResourceGroup) {
  throw "Resource group is required. Pass -ResourceGroup or set AZURE_RESOURCE_GROUP."
}

if (-not $StorageAccount) {
  throw "Storage account is required. Pass -StorageAccount or set AZURE_STORAGE_ACCOUNT."
}

Invoke-NativeCommand -ErrorMessage "Cost refresh failed." -Command { npm run refresh:cost } | Write-Host
Invoke-NativeCommand -ErrorMessage "Build failed." -Command { npm run build } | Write-Host

$key = Invoke-NativeCommand -ErrorMessage "Unable to list storage account keys for '$StorageAccount' in resource group '$ResourceGroup'." -Command {
  az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query '[0].value' --output tsv
}
$key = ($key | Out-String).Trim()

if (-not $key) {
  throw "Azure CLI returned an empty storage account key for '$StorageAccount'."
}

Invoke-NativeCommand -ErrorMessage "Unable to enable static website hosting for '$StorageAccount'." -Command {
  az storage blob service-properties update --account-name $StorageAccount --account-key $key --static-website --index-document index.html --404-document index.html --output none
} | Write-Host

Invoke-NativeCommand -ErrorMessage "Unable to upload static site files to '$StorageAccount'." -Command {
  az storage blob upload-batch --account-name $StorageAccount --account-key $key --destination '$web' --source dist --overwrite --output none
} | Write-Host

$endpoint = Invoke-NativeCommand -ErrorMessage "Unable to read static website endpoint for '$StorageAccount'." -Command {
  az storage account show --name $StorageAccount --resource-group $ResourceGroup --query 'primaryEndpoints.web' --output tsv
}
$endpoint = ($endpoint | Out-String).Trim()

Write-Host "Deployed Azure Billing Dashboard to $endpoint"