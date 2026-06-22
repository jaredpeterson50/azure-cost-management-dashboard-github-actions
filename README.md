# Azure Billing Dashboard

A low-cost Azure billing dashboard built with React, Vite, TypeScript, Azure CLI Cost Management data, Azure Storage static website hosting, Terraform, and Azure Budget alerts.

The project is designed for rebuild practice and public learning material. It avoids committing personal Azure identifiers, secrets, real emails, Terraform state, or live cost data.

## What It Does

- Shows month-to-date Azure spend against a configurable monthly budget.
- Displays 50%, 75%, and 90% budget thresholds.
- Loads static billing data from `public/billing-data.json`.
- Refreshes real Azure Cost Management data locally through Azure CLI with `az rest`.
- Deploys the compiled static site to Azure Storage static website hosting.
- Defines infrastructure in Terraform under `infra/`.
- Includes a guarded shutdown script that only stops resources tagged `AutoShutdown=true`.

## Quick Start

```powershell
npm install
npm test
npm run build
npm run dev
```

## Azure Workflow

Sign in first:

```powershell
az login
az account show --output table
```

Refresh local billing data:

```powershell
npm run refresh:cost
```

Deploy to an existing Azure Storage static website:

```powershell
$env:AZURE_RESOURCE_GROUP = "rg-azure-billing-dashboard"
$env:AZURE_STORAGE_ACCOUNT = "<your-storage-account-name>"
npm run deploy:azure
```

Configure Azure Budget email alerts:

```powershell
npm run configure:budget-alerts -- -ContactEmails you@example.com -Amount 2.60
```

Run the guarded shutdown check in dry-run mode:

```powershell
npm run stop:costly-resources -- -DryRun
```

Only resources tagged `AutoShutdown=true` are eligible for stopping.

## Terraform

Terraform files live in `infra/`.

```powershell
cd infra
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Do not commit `terraform.tfvars` or Terraform state.

## Public Demo Privacy

Before publishing screenshots, video, or a public repo:

- Replace emails with `you@example.com`.
- Replace subscription IDs with `00000000-0000-0000-0000-000000000000`.
- Blur tenant IDs, account names, and Azure Portal profile details.
- Never show storage keys, SAS tokens, client secrets, `.env`, `.tfvars`, or `.azure` profile files.
- Use mock or rounded cost data unless exact cost is intentionally part of the demo.

See [docs/privacy-checklist.md](docs/privacy-checklist.md) for the full checklist.

## Rebuild Guide

See [docs/rebuild-without-ai.md](docs/rebuild-without-ai.md) for a step-by-step walkthrough that someone can follow on their own machine without AI.

## Cleanup

```powershell
az group delete --name rg-azure-billing-dashboard --yes
az consumption budget delete --budget-name azure-billing-dashboard-monthly-budget
Unregister-ScheduledTask -TaskName AzureBillingCostGuard -Confirm:$false
```

## License

No license has been selected yet. Add one before encouraging public reuse.
