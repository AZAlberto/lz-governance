# 3-landing-zone
# Despliega una LZ "Spoke" conectada al Hub, con políticas aplicadas (e.g. Tags obligatorios).

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

# --- Workload Resource Group ---
resource "azurerm_resource_group" "rg_workload" {
  name     = "rg-workload-app-001"
  location = "westeurope"
  tags = {
    Ambiente   = "Produccion"
    Aplicacion = "App001"
  }
}

# --- Spoke VNet ---
resource "azurerm_virtual_network" "vnet_spoke" {
  name                = "vnet-spoke-app-001"
  location            = azurerm_resource_group.rg_workload.location
  resource_group_name = azurerm_resource_group.rg_workload.name
  address_space       = ["10.1.0.0/16"]
}

# --- Policy Assignment (Ejemplo: Requerir Tag 'Ambiente') ---
resource "azurerm_resource_group_policy_assignment" "require_tag_ambiente" {
  name              = "require-tag-ambiente"
  resource_group_id = azurerm_resource_group.rg_workload.id
  # Built-in Policy: "Require a tag on resources"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  parameters           = <<PARAMETERS
{
  "tagName": {
    "value": "Ambiente"
  }
}
PARAMETERS
}
