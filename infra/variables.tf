variable "subscription_id" {
  description = "Azure subscription ID that hosts the dashboard and budget. Prefer TF_VAR_subscription_id or terraform.tfvars; do not hard-code this in shared files."
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Resource group for the static dashboard."
  type        = string
  default     = "rg-azure-billing-dashboard"
}

variable "location" {
  description = "Azure region for dashboard resources."
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for static website hosting."
  type        = string
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "demo"
}

variable "budget_name" {
  description = "Subscription budget name."
  type        = string
  default     = "azure-billing-dashboard-monthly-budget"
}

variable "monthly_budget_amount" {
  description = "Monthly cost budget amount in USD."
  type        = number
  default     = 2.6
}

variable "budget_thresholds" {
  description = "Actual spend percentage thresholds for budget notifications."
  type        = list(number)
  default     = [50, 75, 90]
}

variable "budget_contact_emails" {
  description = "Email recipients for Azure Budget notifications. Put real emails only in local terraform.tfvars or environment-specific CI secrets."
  type        = list(string)
  sensitive   = true
}

variable "budget_start_date" {
  description = "Budget start date in RFC3339 format."
  type        = string
}

variable "budget_end_date" {
  description = "Budget end date in RFC3339 format."
  type        = string
}

variable "tags" {
  description = "Extra tags to apply to supported resources."
  type        = map(string)
  default     = {}
}