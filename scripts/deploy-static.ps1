param(
  [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
  [string]$StorageAccount = $env:AZURE_STORAGE_ACCOUNT
)

$ErrorActionPreference = "Stop"

if (-not $ResourceGroup) {
  throw "Resource group is required. Pass -ResourceGroup or set AZURE_RESOURCE_GROUP."
}

if (-not $StorageAccount) {
  throw "Storage account is required. Pass -StorageAccount or set AZURE_STORAGE_ACCOUNT."
}

npm run refresh:cost
npm run build

$key = az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query '[0].value' --output tsv
az storage blob service-properties update --account-name $StorageAccount --account-key $key --static-website --index-document index.html --404-document index.html --output none
az storage blob upload-batch --account-name $StorageAccount --account-key $key --destination '$web' --source dist --overwrite --output none
$endpoint = az storage account show --name $StorageAccount --resource-group $ResourceGroup --query 'primaryEndpoints.web' --output tsv
Write-Host "Deployed Azure Billing Dashboard to $endpoint"