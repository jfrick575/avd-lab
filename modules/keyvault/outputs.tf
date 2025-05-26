output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "local_admin_username_secret_id" {
  description = "ID of the local admin username secret"
  value       = azurerm_key_vault_secret.local_admin_username.id
}

output "local_admin_password_secret_id" {
  description = "ID of the local admin password secret"
  value       = azurerm_key_vault_secret.local_admin_password.id
} 