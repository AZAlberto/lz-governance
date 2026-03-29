# 2-platform
# Configura Hub VNet, conectividad base y Log Analytics Workspace.

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

resource "azurerm_resource_group" "rg_platform" {
  name     = "rg-platform-networking"
  location = "westeurope"
}

# --- Hub VNet ---
resource "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet-hub-weu-001"
  location            = azurerm_resource_group.rg_platform.location
  resource_group_name = azurerm_resource_group.rg_platform.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg_platform.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "snet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_platform.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

# --- Log Analytics Workspace (Centralizado) ---
resource "azurerm_resource_group" "rg_management" {
  name     = "rg-platform-management"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "law_central" {
  name                = "law-central-lz-gov"
  location            = azurerm_resource_group.rg_management.location
  resource_group_name = azurerm_resource_group.rg_management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
