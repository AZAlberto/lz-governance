# 1-bootstrap
# Establece la base de la Landing Zone.
# Incluye Storage Account para tfstate, jerarquía de Management Groups y RBAC base.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Management Group Hierarchy ---
resource "azurerm_management_group" "mg_root" {
  display_name = "LZ-Root"
  name         = "lz-root"
}

resource "azurerm_management_group" "mg_platform" {
  display_name               = "Platform"
  name                       = "lz-platform"
  parent_management_group_id = azurerm_management_group.mg_root.id
}

resource "azurerm_management_group" "mg_landingzones" {
  display_name               = "Landing Zones"
  name                       = "lz-landingzones"
  parent_management_group_id = azurerm_management_group.mg_root.id
}

# --- State Management (Optional for demo, recommended for prod) ---
resource "azurerm_resource_group" "rg_tfstate" {
  name     = "rg-terraform-state"
  location = "westeurope"
}

resource "azurerm_storage_account" "sa_tfstate" {
  name                     = "satfstatelzgov123"
  resource_group_name      = azurerm_resource_group.rg_tfstate.name
  location                 = azurerm_resource_group.rg_tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "sc_tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa_tfstate.name
  container_access_type = "private"
}
