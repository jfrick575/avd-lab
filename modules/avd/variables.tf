variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for session hosts"
  type        = string
}

variable "host_pool_name" {
  description = "Name of the AVD host pool"
  type        = string
}

variable "host_pool_type" {
  description = "Type of host pool"
  type        = string
  default     = "Pooled"
}

variable "host_pool_load_balancer_type" {
  description = "Load balancer type for host pool"
  type        = string
  default     = "BreadthFirst"
}

variable "host_pool_max_sessions" {
  description = "Maximum sessions per session host"
  type        = number
  default     = 10
}

variable "session_host_count" {
  description = "Number of session hosts to deploy"
  type        = number
  default     = 2
}

variable "session_host_vm_size" {
  description = "VM size for session hosts"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "local_admin_username" {
  description = "Local administrator username"
  type        = string
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
}

variable "custom_image_id" {
  description = "ID of the custom image to use for session hosts (optional)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "data_collection_rule_id" {
  description = "ID of the Data Collection Rule"
  type        = string
}

variable "fslogix_storage_account_name" {
  description = "Name of the FSLogix storage account"
  type        = string
}

variable "fslogix_file_share_name" {
  description = "Name of the FSLogix file share"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 