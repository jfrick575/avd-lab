# Azure Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "02b4788a-7fc7-4485-834f-a7547c61156b"
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = "c831cf37-07c4-4845-91f6-9ee7b1c0a6c1"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "avd"
}

# Networking Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnets"
  type = object({
    avd_subnet     = string
    storage_subnet = string
  })
  default = {
    avd_subnet     = "10.0.1.0/24"
    storage_subnet = "10.0.2.0/24"
  }
}

# AVD Configuration
variable "host_pool_name" {
  description = "Name of the AVD host pool"
  type        = string
  default     = "hp-avd-prod-we-001"
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
  default     = "localadmin"
}

# Storage Configuration
variable "fslogix_storage_size" {
  description = "Size of FSLogix storage in GB"
  type        = number
  default     = 10
}

variable "fslogix_storage_tier" {
  description = "Storage tier for FSLogix"
  type        = string
  default     = "Standard"
}

# Monitoring Configuration
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# Image Builder Configuration
variable "image_template_name" {
  description = "Name of the image template"
  type        = string
  default     = "win11-avd-template"
}

variable "image_gallery_name" {
  description = "Name of the shared image gallery"
  type        = string
  default     = "sig_avd_prod_we_001"
}

variable "image_definition_name" {
  description = "Name of the image definition"
  type        = string
  default     = "win11-multi-session"
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "AVD"
    ManagedBy   = "Terraform"
    Owner       = "IT-Team"
  }
} 