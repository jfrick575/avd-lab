# Random string for storage account naming
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
  
  # Force new suffix for lab environment
  keepers = {
    environment = "lab"
  }
}

# Storage Account for FSLogix
resource "azurerm_storage_account" "fslogix" {
  name                     = "stlab${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.fslogix_storage_tier
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable large file shares for FSLogix
  large_file_share_enabled = true

  # Allow public access during creation and management
  public_network_access_enabled = true

  # Enable Azure Files authentication
  azure_files_authentication {
    directory_type = "AADKERB"
  }

  tags = var.tags
}

# File Share for FSLogix Profiles
resource "azurerm_storage_share" "fslogix_profiles" {
  name                 = "fslogix-profiles"
  storage_account_name = azurerm_storage_account.fslogix.name
  quota                = var.fslogix_storage_size
  enabled_protocol     = "SMB"

  metadata = {
    environment = var.environment
    purpose     = "fslogix-profiles"
  }
}

# File Share for FSLogix ODFC (Office Data File Cache)
resource "azurerm_storage_share" "fslogix_odfc" {
  name                 = "fslogix-odfc"
  storage_account_name = azurerm_storage_account.fslogix.name
  quota                = var.fslogix_storage_size
  enabled_protocol     = "SMB"

  metadata = {
    environment = var.environment
    purpose     = "fslogix-odfc"
  }
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${azurerm_storage_account.fslogix.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.fslogix.name}"
    private_connection_resource_id = azurerm_storage_account.fslogix.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  tags = var.tags
} 