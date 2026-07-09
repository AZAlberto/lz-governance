# Azure Policy: Virtual Machine Denial

Este directorio contiene las definiciones y asignaciones de políticas de Azure para **prohibir la creación de máquinas virtuales** en la Landing Zone.

## Contenido

### 1. `deny-vm-creation-policy.tf`
Define tres políticas personalizadas de Azure:
- **deny-vm-creation**: Deniega máquinas virtuales Windows
- **deny-linux-vm-creation**: Deniega máquinas virtuales Linux
- **deny-all-vm-creation**: Deniega la creación de cualquier máquina virtual (más restrictiva)

### 2. `policy-assignment.tf`
Asigna las políticas de negación al nivel de Management Group:
- Aplicación de políticas en el grupo "Landing Zones"
- Soporte para exenciones temporales
- Validación de cumplimiento

### 3. `mcp-server-integration.tf`
Integra el servidor MCP de Azure para:
- Evaluación remota de políticas
- Monitoreo de cumplimiento en Log Analytics
- Modo de enforcement configurable (Audit/Deny)

## Cómo desplegar

### Paso 1: Crear las definiciones de política
```bash
cd src/policies
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

### Paso 2: Asignar la política a Management Groups
```bash
terraform apply -var="landing_zone_mg_id=/providers/Microsoft.Management/managementGroups/lz-landingzones"
```

### Paso 3: Verificar cumplimiento
Consulta el portal de Azure:
- **Policy** → **Compliance** → Busca "Deny VM Creation"
- Verifica que los recursos no cumplen sean tratados como esperado

## Variables principales

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `management_group_id` | ID del Management Group | Requerido |
| `landing_zone_mg_id` | ID del MG de Landing Zones | `/providers/Microsoft.Management/managementGroups/lz-landingzones` |
| `policy_enabled` | Habilitar/deshabilitar política | `true` |
| `enforcement_mode` | Modo de cumplimiento (Audit/Deny) | `Deny` |
| `expires_on` | Fecha de expiración de exención | Configurable |

## Exenciones de política

Para **excepcionar** un workload específico del bloqueo de VMs:

```hcl
resource "azurerm_management_group_policy_exemption" "custom_exemption" {
  name                 = "vm-exemption-myapp"
  management_group_id  = var.landing_zone_mg_id
  policy_assignment_id = azurerm_management_group_policy_assignment.deny_vm_at_mg_level[0].id
  exemption_category   = "Waiver"
  display_name         = "VM Creation Exemption for MyApp"
  expires_on           = "2026-09-09T23:59:59Z"
}
```

## Monitoreo

Las políticas envían logs a Log Analytics. Consulta:

```kusto
AzureDiagnostics
| where ResourceType == "POLICYDEFINITIONS"
| where OperationName contains "VM"
| summarize Violations = dcount(ResourceId) by bin(TimeGenerated, 1d)
| render timechart
```

## Rollback

Para deshabilitar la política sin eliminarla:

```bash
terraform apply -var="policy_enabled=false"
```

Para eliminar completamente:

```bash
terraform destroy
```

## Referencias

- [Azure Policy Definition Structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)
- [Azure Policy Effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Terraform azurerm Provider - Policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition)
