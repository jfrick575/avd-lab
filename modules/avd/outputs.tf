output "host_pool_id" {
  description = "ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.id
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.name
}

output "desktop_application_group_id" {
  description = "ID of the desktop application group"
  value       = azurerm_virtual_desktop_application_group.desktop.id
}

output "remoteapp_application_group_id" {
  description = "ID of the RemoteApp application group"
  value       = azurerm_virtual_desktop_application_group.remoteapp.id
}

output "workspace_id" {
  description = "ID of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.id
}

output "workspace_friendly_name" {
  description = "Friendly name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.friendly_name
}

output "scaling_plan_id" {
  description = "ID of the scaling plan"
  value       = azurerm_virtual_desktop_scaling_plan.main.id
}

output "session_host_names" {
  description = "Names of the session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].name
}

output "session_host_ids" {
  description = "IDs of the session hosts"
  value       = azurerm_windows_virtual_machine.session_host[*].id
}

output "avd_users_group_id" {
  description = "ID of the AVD users group"
  value       = azuread_group.avd_users.object_id
}

output "avd_users_group_name" {
  description = "Name of the AVD users group"
  value       = azuread_group.avd_users.display_name
} 