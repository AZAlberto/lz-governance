# demos/broken/main.tf
# DEMO: Infraestructura CAÓTICA.
# Sin etiquetas, NSG abierto al mundo (0.0.0.0/0), sin diagnostic settings.

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

resource "azurerm_resource_group" "rg_chaos" {
  name     = "rg-demo-caos-001"
  location = "westeurope"
  # ❌ PROBLEMA: Faltan etiquetas (Tags) para tracking y facturación.
}

resource "azurerm_virtual_network" "vnet_chaos" {
  name                = "vnet-caos"
  location            = azurerm_resource_group.rg_chaos.location
  resource_group_name = azurerm_resource_group.rg_chaos.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "snet_chaos" {
  name                 = "snet-caos"
  resource_group_name  = azurerm_resource_group.rg_chaos.name
  virtual_network_name = azurerm_virtual_network.vnet_chaos.name
  address_prefixes     = ["192.168.1.0/24"]
}

# ❌ PROBLEMA: NSG Abierto al mundo en puerto 22 (y 3389)
resource "azurerm_network_security_group" "nsg_chaos" {
  name                = "nsg-open-to-world"
  location            = azurerm_resource_group.rg_chaos.location
  resource_group_name = azurerm_resource_group.rg_chaos.name

  security_rule {
    name                       = "Allow-SSH-Any"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }
}

# ❌ PROBLEMA: IP Pública exponiendo directamente un recurso.
resource "azurerm_public_ip" "pip_chaos" {
  name                = "pip-caos-vm"
  location            = azurerm_resource_group.rg_chaos.location
  resource_group_name = azurerm_resource_group.rg_chaos.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic_chaos" {
  name                = "nic-caos-vm"
  location            = azurerm_resource_group.rg_chaos.location
  resource_group_name = azurerm_resource_group.rg_chaos.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet_chaos.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_chaos.id
  }
}
