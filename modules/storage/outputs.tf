output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.fslogix.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.fslogix.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.fslogix.primary_access_key
  sensitive   = true
}

output "file_share_name" {
  description = "Name of the FSLogix profiles file share"
  value       = azurerm_storage_share.fslogix_profiles.name
}

output "file_share_url" {
  description = "URL of the FSLogix profiles file share"
  value       = azurerm_storage_share.fslogix_profiles.url
}

output "odfc_file_share_name" {
  description = "Name of the FSLogix ODFC file share"
  value       = azurerm_storage_share.fslogix_odfc.name
}

output "odfc_file_share_url" {
  description = "URL of the FSLogix ODFC file share"
  value       = azurerm_storage_share.fslogix_odfc.url
}

output "private_endpoint_id" {
  description = "ID of the storage private endpoint"
  value       = azurerm_private_endpoint.storage.id
} 