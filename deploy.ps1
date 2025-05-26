# AVD Terraform Deployment Script
# This script helps deploy the AVD infrastructure using Terraform

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "plan",
    
    [Parameter(Mandatory=$false)]
    [switch]$InitBackend = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== Azure Virtual Desktop Terraform Deployment ===" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Yellow

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    exit 1
}

# Check if Terraform is installed
try {
    $tfVersion = terraform version -json | ConvertFrom-Json
    Write-Host "Terraform version: $($tfVersion.terraform_version)" -ForegroundColor Green
} catch {
    Write-Error "Terraform is not installed or not in PATH. Please install Terraform first."
    exit 1
}

# Check if logged into Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
} catch {
    Write-Error "Not logged into Azure. Please run 'az login' first."
    exit 1
}

# Initialize backend if requested
if ($InitBackend) {
    Write-Host "Initializing Terraform backend storage..." -ForegroundColor Yellow
    
    $resourceGroup = "rg-avd-terraform-state-we"
    $storageAccount = "stavdterraformwe001"
    $containerName = "tfstate"
    $location = "West Europe"
    
    # Create resource group
    Write-Host "Creating resource group: $resourceGroup"
    az group create --name $resourceGroup --location $location
    
    # Create storage account
    Write-Host "Creating storage account: $storageAccount"
    az storage account create `
        --name $storageAccount `
        --resource-group $resourceGroup `
        --location $location `
        --sku Standard_LRS `
        --encryption-services blob
    
    # Create container
    Write-Host "Creating storage container: $containerName"
    az storage container create `
        --name $containerName `
        --account-name $storageAccount
    
    Write-Host "Backend storage initialized successfully!" -ForegroundColor Green
}

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    if (Test-Path "terraform.tfvars.example") {
        Write-Host "terraform.tfvars not found. Copying from example..." -ForegroundColor Yellow
        Copy-Item "terraform.tfvars.example" "terraform.tfvars"
        Write-Host "Please edit terraform.tfvars with your specific values before continuing." -ForegroundColor Red
        exit 1
    } else {
        Write-Error "terraform.tfvars.example not found. Please create terraform.tfvars file."
        exit 1
    }
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Validate Terraform configuration
Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
terraform validate

# Format check
Write-Host "Checking Terraform formatting..." -ForegroundColor Yellow
terraform fmt -check

# Execute the requested action
switch ($Action.ToLower()) {
    "plan" {
        Write-Host "Running Terraform plan..." -ForegroundColor Yellow
        terraform plan -out=tfplan
    }
    "apply" {
        if ($Force) {
            Write-Host "Applying Terraform configuration (auto-approve)..." -ForegroundColor Yellow
            terraform apply -auto-approve
        } else {
            Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
            if (Test-Path "tfplan") {
                terraform apply tfplan
            } else {
                terraform apply
            }
        }
    }
    "destroy" {
        if ($Force) {
            Write-Host "Destroying Terraform infrastructure (auto-approve)..." -ForegroundColor Red
            terraform destroy -auto-approve
        } else {
            Write-Host "Destroying Terraform infrastructure..." -ForegroundColor Red
            terraform destroy
        }
    }
    "output" {
        Write-Host "Showing Terraform outputs..." -ForegroundColor Yellow
        terraform output
    }
    default {
        Write-Error "Invalid action: $Action. Valid actions are: plan, apply, destroy, output"
        exit 1
    }
}

Write-Host "=== Deployment Complete ===" -ForegroundColor Green 