# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}-we-001"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# AVD Subnet
resource "azurerm_subnet" "avd" {
  name                 = "snet-${var.project_name}-${var.environment}-we-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes.avd_subnet]
}

# Storage Subnet
resource "azurerm_subnet" "storage" {
  name                 = "snet-storage-${var.project_name}-${var.environment}-we-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefixes.storage_subnet]

  service_endpoints = ["Microsoft.Storage"]
}

# Network Security Group for AVD Subnet
resource "azurerm_network_security_group" "avd" {
  name                = "nsg-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow RDP from anywhere (you may want to restrict this)
  security_rule {
    name                       = "AllowRDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow WinRM for management
  security_rule {
    name                       = "AllowWinRM"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985-5986"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow HTTP/HTTPS outbound
  security_rule {
    name                       = "AllowHTTPOutbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Azure services outbound
  security_rule {
    name                       = "AllowAzureServicesOutbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

# Network Security Group for Storage Subnet
resource "azurerm_network_security_group" "storage" {
  name                = "nsg-storage-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow SMB from AVD subnet
  security_rule {
    name                       = "AllowSMBFromAVD"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = var.subnet_address_prefixes.avd_subnet
    destination_address_prefix = "*"
  }

  # Allow HTTPS from AVD subnet
  security_rule {
    name                       = "AllowHTTPSFromAVD"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_address_prefixes.avd_subnet
    destination_address_prefix = "*"
  }
}

# Associate NSG with AVD Subnet
resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}

# Associate NSG with Storage Subnet
resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.storage.id
  network_security_group_id = azurerm_network_security_group.storage.id
} 