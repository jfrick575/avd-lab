# Resource Group
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the main resource group"
  value       = azurerm_resource_group.main.location
}

# Networking
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "avd_subnet_id" {
  description = "ID of the AVD subnet"
  value       = module.networking.avd_subnet_id
}

output "storage_subnet_id" {
  description = "ID of the storage subnet"
  value       = module.networking.storage_subnet_id
}

# Key Vault
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.keyvault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

# Storage
output "storage_account_name" {
  description = "Name of the FSLogix storage account"
  value       = module.storage.storage_account_name
}

output "file_share_name" {
  description = "Name of the FSLogix file share"
  value       = module.storage.file_share_name
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "data_collection_rule_id" {
  description = "ID of the Data Collection Rule"
  value       = module.monitoring.data_collection_rule_id
}

# Image Builder
output "shared_image_gallery_name" {
  description = "Name of the Shared Image Gallery"
  value       = module.image_builder.shared_image_gallery_name
}

output "image_definition_id" {
  description = "ID of the image definition"
  value       = module.image_builder.image_definition_id
}

output "image_version_id" {
  description = "ID of the latest image version"
  value       = module.image_builder.image_version_id
}

# AVD
output "host_pool_id" {
  description = "ID of the AVD host pool"
  value       = module.avd.host_pool_id
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = module.avd.host_pool_name
}

output "desktop_application_group_id" {
  description = "ID of the desktop application group"
  value       = module.avd.desktop_application_group_id
}

output "workspace_id" {
  description = "ID of the AVD workspace"
  value       = module.avd.workspace_id
}

output "scaling_plan_id" {
  description = "ID of the scaling plan"
  value       = module.avd.scaling_plan_id
}

# Session Hosts
output "session_host_names" {
  description = "Names of the session hosts"
  value       = module.avd.session_host_names
}

# Access Information
output "workspace_friendly_name" {
  description = "Friendly name of the AVD workspace"
  value       = module.avd.workspace_friendly_name
}

output "feed_url" {
  description = "AVD feed URL for client connections"
  value       = "https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery"
} 