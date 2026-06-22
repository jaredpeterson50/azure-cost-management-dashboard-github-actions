# Terraform Infrastructure

This directory describes the Azure Billing Dashboard infrastructure:

- Resource group for Azure Storage static website hosting
- Storage account configured for static website hosting
- Subscription budget with threshold notifications

Use `terraform.tfvars.example` as a placeholder template. Copy it to `terraform.tfvars` locally and replace placeholder values. Do not commit `terraform.tfvars`.

## First-Time Audit Flow

Install Terraform, then run:

```powershell
cd infra
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Only run `terraform apply` after reviewing the plan. The storage account has `prevent_destroy = true` so accidental teardown is blocked by default.

## Deploying App Content

Terraform manages infrastructure, not the compiled React assets. After Terraform creates the storage account, deploy app content with:

```powershell
powershell -ExecutionPolicy Bypass -File ..\scripts\deploy-static.ps1 `
  -ResourceGroup rg-azure-billing-dashboard `
  -StorageAccount <your-storage-account-name>
```

## Notes

- The storage account is configured for HTTPS-only traffic and TLS 1.2 in Terraform.
- Static website hosting must remain publicly reachable for the dashboard URL to work.
- Budget notifications are configured at 50%, 75%, and 90% of the demo monthly budget.
- The cost shutdown guard is handled by `scripts/stop-costly-resources.ps1`. Terraform can be extended later to move that guard into Azure Automation or Logic Apps.