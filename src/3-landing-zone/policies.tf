# Landing Zone - Policy Assignments
# Applies VM denial policies at the workload level

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

# --- Reference to Deny VM Policy ---
data "azurerm_policy_definition" "deny_vm" {
  name = "deny-all-vm-creation"
}

# --- Resource Group Policy Assignment ---
resource "azurerm_resource_group_policy_assignment" "deny_vm_in_rg" {
  name              = "deny-vm-in-workload-rg"
  resource_group_id = azurerm_resource_group.rg_workload.id
  policy_definition_id = data.azurerm_policy_definition.deny_vm.id

  display_name = "Deny Virtual Machine Creation in Workload RG"
  description  = "Prevents VM creation in this workload resource group"
}

# --- Output ---
output "vm_denial_policy_assignment_id" {
  description = "ID of the VM denial policy assignment"
  value       = azurerm_resource_group_policy_assignment.deny_vm_in_rg.id
}
