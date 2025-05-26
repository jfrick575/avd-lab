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
  name                     = "st${var.project_name}img${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = var.tags
}

# Random string for storage account naming
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
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
        # Set TLS version for secure download
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        Write-Host "Downloading Notepad++ from: $url"
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -TimeoutSec 300
        Write-Host "Downloaded Notepad++ installer successfully"
        
        # Verify file was downloaded
        if (-not (Test-Path $output)) {
            throw "Installer file not found after download"
        }
        
        # Install silently
        Write-Host "Installing Notepad++ silently..."
        $process = Start-Process -FilePath $output -ArgumentList '/S' -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Notepad++ installed successfully"
        } else {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
        
                 # Verify installation
         $nppPath = "$${env:ProgramFiles}\Notepad++\notepad++.exe"
        if (Test-Path $nppPath) {
            Write-Host "Notepad++ installation verified at: $nppPath"
        } else {
            Write-Warning "Notepad++ executable not found at expected location"
        }
        
        # Clean up
        Remove-Item $output -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup completed"
        
    } catch {
        Write-Error "Failed to install Notepad++: $_"
        # Clean up on error
        Remove-Item $output -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    Write-Host "Notepad++ installation completed successfully"
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
      "buildTimeoutInMinutes" : 240,
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
          "name" : "PrepareForSysprep",
          "inline" : [
            "# Wait for any pending operations to complete",
            "Start-Sleep -Seconds 30",
            "# Stop and disable Windows Update service temporarily",
            "Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue",
            "Set-Service -Name wuauserv -StartupType Disabled",
            "# Clear Windows Update cache",
            "Remove-Item -Path 'C:\\Windows\\SoftwareDistribution\\Download\\*' -Recurse -Force -ErrorAction SilentlyContinue",
            "# Clean up temp files and logs",
            "Get-ChildItem -Path C:\\temp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
            "Get-ChildItem -Path C:\\Windows\\Temp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
            "# Clear event logs to reduce image size",
            "wevtutil el | ForEach-Object { wevtutil cl $_ }",
            "# Defragment the disk",
            "Optimize-Volume -DriveLetter C -Defrag -Verbose",
            "# Run disk cleanup",
            "Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:1' -Wait -NoNewWindow -ErrorAction SilentlyContinue"
          ]
        },
        {
          "type" : "WindowsRestart",
          "restartCheckCommand" : "echo 'Final restart before sysprep'",
          "restartTimeout" : "15m"
        },
        {
          "type" : "PowerShell",
          "name" : "FinalSysprepPrep",
          "inline" : [
            "# Final preparations for sysprep",
            "Write-Host 'Starting final sysprep preparations...'",
            "# Ensure Windows Update service is stopped",
            "Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue",
            "# Wait for system to stabilize",
            "Start-Sleep -Seconds 60",
            "# Re-enable Windows Update service for the final image",
            "Set-Service -Name wuauserv -StartupType Manual",
            "Write-Host 'Sysprep preparations complete'"
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