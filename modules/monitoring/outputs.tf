output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_key" {
  description = "Primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "data_collection_endpoint_id" {
  description = "ID of the Data Collection Endpoint"
  value       = azurerm_monitor_data_collection_endpoint.main.id
}

output "data_collection_rule_id" {
  description = "ID of the Data Collection Rule"
  value       = azurerm_monitor_data_collection_rule.avd.id
}

output "avd_insights_solution_id" {
  description = "ID of the AVD Insights solution"
  value       = azurerm_log_analytics_solution.avd_insights.id
} 