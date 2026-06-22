output "static_site_url" {
  description = "Azure Storage static website endpoint."
  value       = azurerm_storage_account.dashboard.primary_web_endpoint
}

output "storage_account_name" {
  description = "Storage account hosting the static site."
  value       = azurerm_storage_account.dashboard.name
}

output "budget_name" {
  description = "Azure subscription budget name."
  value       = azurerm_consumption_budget_subscription.monthly_cost_guard.name
}