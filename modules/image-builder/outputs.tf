output "user_assigned_identity_id" {
  description = "ID of the user assigned identity for image builder"
  value       = azurerm_user_assigned_identity.image_builder.id
}

output "shared_image_gallery_id" {
  description = "ID of the shared image gallery"
  value       = azurerm_shared_image_gallery.main.id
}

output "shared_image_gallery_name" {
  description = "Name of the shared image gallery"
  value       = azurerm_shared_image_gallery.main.name
}

output "image_definition_id" {
  description = "ID of the image definition"
  value       = azurerm_shared_image.win11_multi_session.id
}

output "image_definition_name" {
  description = "Name of the image definition"
  value       = azurerm_shared_image.win11_multi_session.name
}

output "storage_account_name" {
  description = "Name of the image builder storage account"
  value       = azurerm_storage_account.image_builder.name
}

output "install_script_url" {
  description = "URL of the Notepad++ installation script"
  value       = azurerm_storage_blob.install_notepadpp.url
}

# For now, we'll use the image definition ID as the image version ID
# This will need to be updated once an actual image version is created
output "image_version_id" {
  description = "ID of the image definition (placeholder for image version)"
  value       = azurerm_shared_image.win11_multi_session.id
}

output "image_template_json_path" {
  description = "Path to the generated Image Builder template JSON file"
  value       = local_file.create_image_template.filename
} 