# Data sources
data "azurerm_client_config" "current" {}

# Generate random password for local admin
resource "random_password" "local_admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}-we-001"
  location = var.location
  tags     = var.tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
  project_name            = var.project_name
  environment             = var.environment
  tags                    = var.tags
}

# Key Vault Module
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project_name        = var.project_name
  environment         = var.environment
  tenant_id           = var.tenant_id
  tags                = var.tags

  # Store local admin credentials
  local_admin_username = var.local_admin_username
  local_admin_password = random_password.local_admin_password.result
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.networking.storage_subnet_id
  fslogix_storage_size  = var.fslogix_storage_size
  fslogix_storage_tier  = var.fslogix_storage_tier
  tags                  = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  project_name                 = var.project_name
  environment                  = var.environment
  log_analytics_retention_days = var.log_analytics_retention_days
  tags                         = var.tags
}

# Image Builder Module
module "image_builder" {
  source = "./modules/image-builder"

  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.networking.avd_subnet_id
  image_template_name   = var.image_template_name
  image_gallery_name    = var.image_gallery_name
  image_definition_name = var.image_definition_name
  tags                  = var.tags
}

# AVD Module
module "avd" {
  source = "./modules/avd"

  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  project_name                  = var.project_name
  environment                   = var.environment
  subnet_id                     = module.networking.avd_subnet_id
  host_pool_name                = var.host_pool_name
  host_pool_type                = var.host_pool_type
  host_pool_load_balancer_type  = var.host_pool_load_balancer_type
  host_pool_max_sessions        = var.host_pool_max_sessions
  session_host_count            = var.session_host_count
  session_host_vm_size          = var.session_host_vm_size
  local_admin_username          = var.local_admin_username
  local_admin_password          = random_password.local_admin_password.result
  # Use marketplace image initially, switch to custom image later
  custom_image_id               = null
  log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id
  data_collection_rule_id       = module.monitoring.data_collection_rule_id
  fslogix_storage_account_name  = module.storage.storage_account_name
  fslogix_file_share_name       = module.storage.file_share_name
  tags                          = var.tags

  depends_on = [
    module.networking,
    module.keyvault,
    module.storage,
    module.monitoring,
    module.image_builder
  ]
} 