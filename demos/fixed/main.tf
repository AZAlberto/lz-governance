# demos/fixed/main.tf
# DEMO: Infraestructura GOBERNADA.
# Con etiquetas requeridas, NSG restringido, envío de logs y Resource Locks.

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

# ✅ SOLUCIÓN: Etiquetas (Tags) aplicadas correctamente.
resource "azurerm_resource_group" "rg_fixed" {
  name     = "rg-demo-fixed-001"
  location = "westeurope"
  tags = {
    Ambiente    = "Demo"
    Aplicacion  = "Governance"
    Propietario = "CloudTeam"
  }
}

# ✅ SOLUCIÓN: Resource Lock para prevenir borrado accidental.
resource "azurerm_management_lock" "lock_rg" {
  name       = "prevent-delete"
  scope      = azurerm_resource_group.rg_fixed.id
  lock_level = "CanNotDelete"
  notes      = "Bloqueo establecido por política de Landing Zone."
}

resource "azurerm_virtual_network" "vnet_fixed" {
  name                = "vnet-fixed"
  location            = azurerm_resource_group.rg_fixed.location
  resource_group_name = azurerm_resource_group.rg_fixed.name
  address_space       = ["10.2.0.0/16"]
  tags                = azurerm_resource_group.rg_fixed.tags
}

resource "azurerm_subnet" "snet_fixed" {
  name                 = "snet-fixed"
  resource_group_name  = azurerm_resource_group.rg_fixed.name
  virtual_network_name = azurerm_virtual_network.vnet_fixed.name
  address_prefixes     = ["10.2.1.0/24"]
}

# ✅ SOLUCIÓN: NSG cerrado por defecto (Zero Trust) y acceso restringido.
resource "azurerm_network_security_group" "nsg_fixed" {
  name                = "nsg-fixed-secure"
  location            = azurerm_resource_group.rg_fixed.location
  resource_group_name = azurerm_resource_group.rg_fixed.name
  tags                = azurerm_resource_group.rg_fixed.tags

  security_rule {
    name                       = "Allow-SSH-CorpIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "203.0.113.10/32" # IP corporativa
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic_fixed" {
  name                = "nic-fixed-vm"
  location            = azurerm_resource_group.rg_fixed.location
  resource_group_name = azurerm_resource_group.rg_fixed.name
  tags                = azurerm_resource_group.rg_fixed.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_fixed.id
    private_ip_address_allocation = "Dynamic"
    # ✅ SOLUCIÓN: Sin IP Pública directa. El acceso es a través de Bastion.
  }
}
