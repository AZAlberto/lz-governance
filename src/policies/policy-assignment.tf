# Policy Assignment: Applying VM Denial Policies to Management Groups and Landing Zones

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
variable "landing_zone_mg_id" {
  description = "Management Group ID for Landing Zones"
  type        = string
  default     = "/providers/Microsoft.Management/managementGroups/lz-landingzones"
}

variable "policy_enabled" {
  description = "Enable or disable the policy assignment"
  type        = bool
  default     = true
}

# --- Data Source: Reference Custom Policy Definition ---
data "azurerm_policy_definition" "deny_all_vm" {
  name = "deny-all-vm-creation"
}

# --- Policy Assignment at Management Group Level ---
resource "azurerm_management_group_policy_assignment" "deny_vm_at_mg_level" {
  count                = var.policy_enabled ? 1 : 0
  name                 = "deny-vm-creation-assignment"
  policy_definition_id = data.azurerm_policy_definition.deny_all_vm.id
  management_group_id  = var.landing_zone_mg_id

  description = "Assignment of VM denial policy at the Landing Zones Management Group level"
  display_name = "Deny VM Creation - Landing Zones"

  # Enable enforcement
  not_scopes = []
}

# --- Policy Assignment with Exemptions ---
resource "azurerm_management_group_policy_assignment" "deny_vm_with_exemptions" {
  count                = var.policy_enabled ? 1 : 0
  name                 = "deny-vm-creation-exemptions"
  policy_definition_id = data.azurerm_policy_definition.deny_all_vm.id
  management_group_id  = var.landing_zone_mg_id

  description = "Assignment of VM denial policy with exemption support"
  display_name = "Deny VM Creation - Exemptions Allowed"
}

# --- Policy Exemption Example: Allow specific workloads ---
resource "azurerm_management_group_policy_exemption" "vm_exemption_example" {
  name                            = "vm-creation-exemption-legacy-workload"
  management_group_id             = var.landing_zone_mg_id
  policy_assignment_id            = azurerm_management_group_policy_assignment.deny_vm_with_exemptions[0].id
  exemption_category              = "Waiver"
  display_name                    = "VM Creation Exemption for Legacy Workload"
  description                     = "Temporary exemption for legacy workload migration (30 days)"
  expires_on                      = "2026-08-09T23:59:59Z" # Adjust as needed
}

# --- Outputs ---
output "policy_assignment_id" {
  description = "ID of the policy assignment"
  value       = try(azurerm_management_group_policy_assignment.deny_vm_at_mg_level[0].id, null)
}

output "exemption_id" {
  description = "ID of the policy exemption"
  value       = azurerm_management_group_policy_exemption.vm_exemption_example.id
}
