# MCP Server Integration for Azure Policy Management
# This configuration enables Azure policy enforcement through MCP (Model Context Protocol) server

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

# --- Variables for MCP Integration ---
variable "mcp_server_endpoint" {
  description = "MCP Server endpoint for policy evaluation"
  type        = string
  default     = "https://management.azure.com"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for policy compliance monitoring"
  type        = string
}

variable "enforcement_mode" {
  description = "Policy enforcement mode (Audit or Deny)"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Audit", "Deny"], var.enforcement_mode)
    error_message = "Enforcement mode must be either 'Audit' or 'Deny'."
  }
}

# --- Diagnostic Settings for Policy Compliance ---
resource "azurerm_monitor_diagnostic_setting" "policy_compliance_logs" {
  name                       = "policy-compliance-diagnostics"
  target_resource_id         = var.log_analytics_workspace_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Policy"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 90
    }
  }
}

# --- Policy Compliance Query Workbook (for monitoring) ---
locals {
  policy_compliance_query = <<-EOQ
    AzureDiagnostics
    | where ResourceType == "POLICYDEFINITIONS"
    | where OperationName contains "VM"
    | summarize ComplianceCount = dcount(ResourceId) by bin(TimeGenerated, 1d), ComplianceState
    | render barchart
  EOQ
}

# --- Outputs ---
output "mcp_server_endpoint" {
  description = "MCP Server endpoint being used"
  value       = var.mcp_server_endpoint
}

output "policy_enforcement_mode" {
  description = "Current policy enforcement mode"
  value       = var.enforcement_mode
}

output "compliance_monitoring_enabled" {
  description = "Whether compliance monitoring is enabled"
  value       = azurerm_monitor_diagnostic_setting.policy_compliance_logs.enabled_log_names
}
