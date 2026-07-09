# Azure Policy: Deny Virtual Machine Creation
# This policy prevents the creation of Virtual Machines across the Landing Zone
# ensuring governance and cost control through Azure Policy definitions

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

# --- Variables ---
variable "management_group_id" {
  description = "The ID of the Management Group where the policy will be assigned"
  type        = string
}

variable "policy_display_name" {
  description = "Display name for the policy"
  type        = string
  default     = "Deny Virtual Machine Creation"
}

variable "policy_description" {
  description = "Description of the policy"
  type        = string
  default     = "Denies the creation of Virtual Machines to enforce governance and cost control"
}

variable "exclusion_tags" {
  description = "Tags for resources that should be excluded from this policy"
  type        = map(string)
  default = {
    "PolicyExemption" = "Approved"
  }
}

# --- Custom Policy Definition ---
resource "azurerm_policy_definition" "deny_vm_creation" {
  name                = "deny-vm-creation"
  display_name        = var.policy_display_name
  description         = var.policy_description
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = var.management_group_id

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          in     = ["Microsoft.Compute/virtualMachines"]
        },
        {
          field  = "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration"
          exists = true
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# --- Alternative: Deny Linux VMs ---
resource "azurerm_policy_definition" "deny_linux_vm_creation" {
  name                = "deny-linux-vm-creation"
  display_name        = "Deny Linux Virtual Machine Creation"
  description         = "Denies the creation of Linux Virtual Machines"
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = var.management_group_id

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          field  = "Microsoft.Compute/virtualMachines/osProfile.linuxConfiguration"
          exists = true
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# --- Comprehensive Policy: Deny All VM Creation ---
resource "azurerm_policy_definition" "deny_all_vm_creation" {
  name                = "deny-all-vm-creation"
  display_name        = "Deny All Virtual Machine Creation"
  description         = "Denies the creation of any Virtual Machine type"
  policy_type         = "Custom"
  mode                = "All"
  management_group_id = var.management_group_id

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Compute/virtualMachines"
    }
    then = {
      effect = "Deny"
    }
  })
}

# --- Outputs ---
output "deny_vm_policy_id" {
  description = "ID of the Deny VM Creation policy"
  value       = azurerm_policy_definition.deny_vm_creation.id
}

output "deny_linux_vm_policy_id" {
  description = "ID of the Deny Linux VM Creation policy"
  value       = azurerm_policy_definition.deny_linux_vm_creation.id
}

output "deny_all_vm_policy_id" {
  description = "ID of the Deny All VM Creation policy"
  value       = azurerm_policy_definition.deny_all_vm_creation.id
}
