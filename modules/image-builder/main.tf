# User Assigned Identity for Image Builder
resource "azurerm_user_assigned_identity" "image_builder" {
  name                = "id-${var.project_name}-${var.environment}-we-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Role assignment for Image Builder Identity - Contributor on Resource Group
resource "azurerm_role_assignment" "image_builder_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}

# Role assignment for Image Builder Identity - Storage Blob Data Reader (for downloading scripts)
resource "azurerm_role_assignment" "image_builder_storage" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}

# Shared Image Gallery
resource "azurerm_shared_image_gallery" "main" {
  name                = var.image_gallery_name
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Shared Image Gallery for AVD custom images"
  tags                = var.tags
}

# Image Definition
resource "azurerm_shared_image" "win11_multi_session" {
  name                = var.image_definition_name
  gallery_name        = azurerm_shared_image_gallery.main.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  hyper_v_generation  = "V2"

  identifier {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = "win11-22h2-avd-m365"
  }

  tags = var.tags
}

# Storage Account for Image Builder scripts and logs
resource "azurerm_storage_account" "image_builder" {
  name                     = "st${var.project_name}imgwe001"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = var.tags
}

# Container for Image Builder artifacts
resource "azurerm_storage_container" "image_builder" {
  name                  = "imagebuilder"
  storage_account_name  = azurerm_storage_account.image_builder.name
  container_access_type = "private"
}

# PowerShell script for Notepad++ installation
resource "azurerm_storage_blob" "install_notepadpp" {
  name                   = "install-notepadpp.ps1"
  storage_account_name   = azurerm_storage_account.image_builder.name
  storage_container_name = azurerm_storage_container.image_builder.name
  type                   = "Block"
  source_content = <<-EOT
    # Install Notepad++
    Write-Host "Starting Notepad++ installation..."
    
    # Create temp directory
    $tempDir = "C:\temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Force -Path $tempDir
    }
    
    # Download Notepad++
    $url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5.8/npp.8.5.8.Installer.x64.exe"
    $output = "$tempDir\npp-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
        Write-Host "Downloaded Notepad++ installer"
        
        # Install silently
        Start-Process -FilePath $output -ArgumentList '/S' -Wait -NoNewWindow
        Write-Host "Notepad++ installed successfully"
        
        # Clean up
        Remove-Item $output -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Error "Failed to install Notepad++: $_"
        exit 1
    }
    
    Write-Host "Notepad++ installation completed"
  EOT
}

# Note: Azure Image Builder templates are typically managed through Azure CLI or ARM templates
# For now, we'll create the infrastructure needed for Image Builder
# The actual image template will need to be created manually or through Azure CLI

# Output a script that can be used to create the Image Builder template
resource "local_file" "create_image_template" {
  filename = "${path.module}/create-image-template.json"
  content = jsonencode({
    "type" : "Microsoft.VirtualMachineImages/imageTemplates",
    "apiVersion" : "2022-02-14",
    "location" : var.location,
    "dependsOn" : [],
    "tags" : var.tags,
    "identity" : {
      "type" : "UserAssigned",
      "userAssignedIdentities" : {
        "${azurerm_user_assigned_identity.image_builder.id}" : {}
      }
    },
    "properties" : {
      "buildTimeoutInMinutes" : 120,
      "vmProfile" : {
        "vmSize" : "Standard_D4s_v3",
        "osDiskSizeGB" : 128
      },
      "source" : {
        "type" : "PlatformImage",
        "publisher" : "MicrosoftWindowsDesktop",
        "offer" : "office-365",
        "sku" : "win11-22h2-avd-m365",
        "version" : "latest"
      },
      "customize" : [
        {
          "type" : "PowerShell",
          "name" : "InstallNotepadPlusPlus",
          "scriptUri" : "${azurerm_storage_blob.install_notepadpp.url}"
        },
        {
          "type" : "WindowsRestart",
          "restartCheckCommand" : "echo 'Restarted successfully'",
          "restartTimeout" : "10m"
        },
        {
          "type" : "PowerShell",
          "name" : "OptimizeOS",
          "inline" : [
            "# Disable Windows Update during image creation",
            "Set-Service -Name wuauserv -StartupType Disabled",
            "# Clean up temp files",
            "Get-ChildItem -Path C:\\temp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"
          ]
        }
      ],
      "distribute" : [
        {
          "type" : "SharedImage",
          "galleryImageId" : azurerm_shared_image.win11_multi_session.id,
          "runOutputName" : "win11-avd-image",
          "artifactTags" : var.tags,
          "replicationRegions" : [var.location]
        }
      ]
    }
  })
} 