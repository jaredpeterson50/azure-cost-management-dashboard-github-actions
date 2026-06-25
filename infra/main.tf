terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  common_tags = merge(var.tags, {
    Project     = "azure-billing-dashboard"
    ManagedBy   = "terraform"
    Environment = var.environment
  })
}

resource "azurerm_resource_group" "dashboard" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "dashboard" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.dashboard.name
  location                 = azurerm_resource_group.dashboard.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  static_website {
    index_document     = "index.html"
    error_404_document = "index.html"
  }
  tags = local.common_tags
}

resource "azurerm_consumption_budget_subscription" "monthly_cost_guard" {
  name            = var.budget_name
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  dynamic "notification" {
    for_each = toset(var.budget_thresholds)

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_emails = var.budget_contact_emails
    }
  }
}