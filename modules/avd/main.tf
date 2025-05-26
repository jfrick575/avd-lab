# Data sources
data "azurerm_client_config" "current" {}

# Create Entra ID group for AVD users
resource "azuread_group" "avd_users" {
  display_name     = "AVD-Users-${var.environment}"
  description      = "Users with access to Azure Virtual Desktop environment"
  security_enabled = true
}

# Host Pool
resource "azurerm_virtual_desktop_host_pool" "main" {
  name                = var.host_pool_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type                     = var.host_pool_type
  maximum_sessions_allowed = var.host_pool_max_sessions
  load_balancer_type       = var.host_pool_load_balancer_type

  friendly_name = "AVD Host Pool - ${var.environment}"
  description   = "Host pool for Azure Virtual Desktop environment"

  tags = var.tags
}

# Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = "dag-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.main.id
  friendly_name = "Desktop Application Group"
  description   = "Desktop application group for full desktop access"

  tags = var.tags
}

# RemoteApp Application Group
resource "azurerm_virtual_desktop_application_group" "remoteapp" {
  name                = "rag-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  type          = "RemoteApp"
  host_pool_id  = azurerm_virtual_desktop_host_pool.main.id
  friendly_name = "RemoteApp Application Group"
  description   = "RemoteApp application group for published applications"

  tags = var.tags
}

# Workspace
resource "azurerm_virtual_desktop_workspace" "main" {
  name                = "ws-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  friendly_name = "AVD Workspace - ${var.environment}"
  description   = "Azure Virtual Desktop workspace"

  tags = var.tags
}

# Associate Application Groups with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "desktop" {
  workspace_id         = azurerm_virtual_desktop_workspace.main.id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "remoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.main.id
  application_group_id = azurerm_virtual_desktop_application_group.remoteapp.id
}

# Role assignment for AVD users group to Desktop Application Group
resource "azurerm_role_assignment" "desktop_virtualization_user" {
  scope                = azurerm_virtual_desktop_application_group.desktop.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_group.avd_users.object_id
}

# Network Interface for Session Hosts
resource "azurerm_network_interface" "session_host" {
  count               = var.session_host_count
  name                = "nic-${var.project_name}-${var.environment}-we-${format("%03d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Session Host Virtual Machines
resource "azurerm_windows_virtual_machine" "session_host" {
  count               = var.session_host_count
  name                = "vm-${var.project_name}-${var.environment}-we-${format("%03d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.session_host_vm_size
  admin_username      = var.local_admin_username
  admin_password      = var.local_admin_password

  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Use custom image if provided, otherwise use marketplace image
  dynamic "source_image_reference" {
    for_each = var.custom_image_id == null ? [1] : []
    content {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "office-365"
      sku       = "win11-22h2-avd-m365"
      version   = "latest"
    }
  }

  source_image_id = var.custom_image_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Join VMs to Entra ID
resource "azurerm_virtual_machine_extension" "aad_join" {
  count                = var.session_host_count
  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"

  tags = var.tags
}

# Install Azure Monitor Agent
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  count                = var.session_host_count
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"

  tags = var.tags

  depends_on = [azurerm_virtual_machine_extension.aad_join]
}

# Associate VMs with Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "session_host" {
  count                   = var.session_host_count
  name                    = "dcra-${azurerm_windows_virtual_machine.session_host[count.index].name}"
  target_resource_id      = azurerm_windows_virtual_machine.session_host[count.index].id
  data_collection_rule_id = var.data_collection_rule_id

  depends_on = [azurerm_virtual_machine_extension.azure_monitor_agent]
}

# AVD Agent Extension
resource "azurerm_virtual_machine_extension" "avd_agent" {
  count                = var.session_host_count
  name                 = "Microsoft.PowerShell.DSC"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName          = azurerm_virtual_desktop_host_pool.main.name
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.main.token
      aadJoin               = true
    }
  })

  tags = var.tags

  depends_on = [azurerm_virtual_machine_extension.aad_join]
}

# Host Pool Registration Info
resource "azurerm_virtual_desktop_host_pool_registration_info" "main" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.main.id
  expiration_date = timeadd(timestamp(), "48h")
}

# FSLogix Configuration Extension
resource "azurerm_virtual_machine_extension" "fslogix_config" {
  count                = var.session_host_count
  name                 = "FSLogixConfiguration"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"& { New-Item -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Force; Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'Enabled' -Value 1; Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VHDLocations' -Value '\\\\${var.fslogix_storage_account_name}.file.core.windows.net\\${var.fslogix_file_share_name}'; New-Item -Path 'HKLM:\\SOFTWARE\\FSLogix\\ODFC' -Force; Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\ODFC' -Name 'Enabled' -Value 1; Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\ODFC' -Name 'VHDLocations' -Value '\\\\${var.fslogix_storage_account_name}.file.core.windows.net\\fslogix-odfc' }\""
  })

  tags = var.tags

  depends_on = [azurerm_virtual_machine_extension.avd_agent]
}

# Scaling Plan
resource "azurerm_virtual_desktop_scaling_plan" "main" {
  name                = "sp-${var.project_name}-${var.environment}-we-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "AVD Scaling Plan"
  description         = "Scaling plan for cost optimization"
  time_zone           = "W. Europe Standard Time"

  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "08:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 50
    ramp_up_capacity_threshold_percent   = 80
    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "DepthFirst"
    ramp_down_start_time                 = "17:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 25
    ramp_down_capacity_threshold_percent = 50
    ramp_down_force_logoff_users         = false
    ramp_down_stop_hosts_when            = "ZeroSessions"
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "You will be logged off in 30 min. Make sure to save your work."
    off_peak_start_time                  = "18:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.main.id
    scaling_plan_enabled = true
  }

  tags = var.tags
} 