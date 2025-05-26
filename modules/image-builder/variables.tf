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
  description = "ID of the subnet for image builder"
  type        = string
}

variable "image_template_name" {
  description = "Name of the image template"
  type        = string
}

variable "image_gallery_name" {
  description = "Name of the shared image gallery"
  type        = string
}

variable "image_definition_name" {
  description = "Name of the image definition"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 