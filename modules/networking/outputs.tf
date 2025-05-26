output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "avd_subnet_id" {
  description = "ID of the AVD subnet"
  value       = azurerm_subnet.avd.id
}

output "avd_subnet_name" {
  description = "Name of the AVD subnet"
  value       = azurerm_subnet.avd.name
}

output "storage_subnet_id" {
  description = "ID of the storage subnet"
  value       = azurerm_subnet.storage.id
}

output "storage_subnet_name" {
  description = "Name of the storage subnet"
  value       = azurerm_subnet.storage.name
}

output "avd_nsg_id" {
  description = "ID of the AVD network security group"
  value       = azurerm_network_security_group.avd.id
}

output "storage_nsg_id" {
  description = "ID of the storage network security group"
  value       = azurerm_network_security_group.storage.id
} 