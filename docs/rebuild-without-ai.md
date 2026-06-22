# Rebuild the Azure Billing Dashboard Without AI

This walkthrough rebuilds the project from a clean folder using normal CLI tools. It avoids committing personal information and keeps Azure resources cheap.

## What Not to Show Publicly

Treat these as private or semi-private in a YouTube video, screenshots, commits, and logs:

- Email addresses: personally identifiable information. Use `you@example.com` in examples.
- Subscription ID: not a password, but it uniquely identifies your Azure subscription. Blur it or use `00000000-0000-0000-0000-000000000000` in public docs.
- Tenant ID and directory names: organization/account identifiers. Blur them.
- Storage account names and public URLs: not secret, but they reveal live infrastructure. Use demo names in public material.
- Cost data: may reveal usage patterns. Round or use mock values for videos.
- Access keys, SAS tokens, client secrets, refresh tokens: secrets. Never show or commit them.

## Prerequisites

Install tools:

```powershell
winget install OpenJS.NodeJS.LTS
winget install Hashicorp.Terraform
winget install Microsoft.AzureCLI
```

Sign in:

```powershell
az login
az account show --output table
az account set --subscription "<your-subscription-id-or-name>"
```

## Create the React App

```powershell
npm create vite@latest azure-billing-dashboard -- --template react-ts
cd azure-billing-dashboard
npm install
npm install -D vitest jsdom @testing-library/react @testing-library/jest-dom
```

Add scripts to `package.json`:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "test": "vitest run",
    "refresh:cost": "powershell -ExecutionPolicy Bypass -File scripts/refresh-azure-cost.ps1",
    "deploy:azure": "powershell -ExecutionPolicy Bypass -File scripts/deploy-static.ps1",
    "configure:budget-alerts": "powershell -ExecutionPolicy Bypass -File scripts/configure-budget-alerts.ps1",
    "stop:costly-resources": "powershell -ExecutionPolicy Bypass -File scripts/stop-costly-resources.ps1"
  }
}
```

## Build the Dashboard Locally

Create these app concepts:

- Budget target: `$2.60` for testing.
- Thresholds: `50`, `75`, and `90` percent.
- Spend source: load `/billing-data.json` at runtime.
- Fallback: local mock data when the JSON request fails.

Keep real Azure data in `public/billing-data.json` instead of bundling it into JavaScript. Do not include subscription IDs in the public JSON.

Run locally:

```powershell
npm run dev
```

## Query Azure Cost Management

Use Azure CLI auth and `az rest`; no API keys are needed.

```powershell
$subscriptionId = az account show --query id --output tsv
$bodyPath = "$env:TEMP\azure-cost-query.json"
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

az rest `
  --method post `
  --headers Content-Type=application/json `
  --uri "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2023-11-01" `
  --body "@$bodyPath" `
  --output json
```

## Deploy Cheap Static Hosting

Azure Storage static website hosting is enough for this dashboard.

```powershell
$resourceGroup = "rg-azure-billing-dashboard"
$location = "eastus"
$storageAccount = "azbilldash$((Get-Random -Minimum 100000 -Maximum 999999))"

az group create --name $resourceGroup --location $location
az storage account create `
  --name $storageAccount `
  --resource-group $resourceGroup `
  --location $location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --min-tls-version TLS1_2 `
  --https-only true

$key = az storage account keys list `
  --resource-group $resourceGroup `
  --account-name $storageAccount `
  --query "[0].value" `
  --output tsv

az storage blob service-properties update `
  --account-name $storageAccount `
  --account-key $key `
  --static-website `
  --index-document index.html `
  --404-document index.html

npm run build
az storage blob upload-batch `
  --account-name $storageAccount `
  --account-key $key `
  --destination '$web' `
  --source dist `
  --overwrite

az storage account show `
  --name $storageAccount `
  --resource-group $resourceGroup `
  --query "primaryEndpoints.web" `
  --output tsv
```

## Configure Budget Emails

Use Azure Budget notifications for email. Avoid direct browser email sending.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\configure-budget-alerts.ps1 `
  -ContactEmails you@example.com `
  -Amount 2.60
```

Azure Budget emails may lag behind Cost Management query results. For demos, lower the budget temporarily rather than creating compute just to spend money.

## Cost Guard Shutdown Pattern

Only stop resources that are explicitly safe to stop:

```powershell
az resource tag --ids "<resource-id>" --tags AutoShutdown=true
powershell -ExecutionPolicy Bypass -File scripts\stop-costly-resources.ps1 -DryRun
```

The guard supports deallocating VMs and VM scale sets, stopping Web Apps, stopping AKS clusters, and stopping container groups. It ignores untagged resources.

## Terraform Workflow

Copy the example variables file:

```powershell
cd infra
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Replace placeholders locally. Do not commit `terraform.tfvars`.

Run review commands:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply only after reviewing the plan:

```powershell
terraform apply
```

## Safety Checks

Run these before publishing or applying infrastructure:

```powershell
npm test
npm run build
terraform fmt -check
terraform validate
terraform plan
```

Recommended scanners:

```powershell
checkov -d infra
trivy config infra
gitleaks detect --source .
```

## Cleanup

To stop charges from demo resources:

```powershell
az group delete --name rg-azure-billing-dashboard --yes
az consumption budget delete --budget-name azure-billing-dashboard-monthly-budget
Unregister-ScheduledTask -TaskName AzureBillingCostGuard -Confirm:$false
```
