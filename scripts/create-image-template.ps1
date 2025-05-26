# Create Azure Image Builder Template
# This script creates an Azure Image Builder template using the generated JSON

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    
    [Parameter(Mandatory=$false)]
    [string]$JsonFilePath = "modules\image-builder\create-image-template.json"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Creating Azure Image Builder Template ===" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Template Name: $TemplateName" -ForegroundColor Yellow
Write-Host "JSON File: $JsonFilePath" -ForegroundColor Yellow

# Check if JSON file exists
if (-not (Test-Path $JsonFilePath)) {
    Write-Error "JSON template file not found: $JsonFilePath"
    Write-Host "Please run 'terraform apply' first to generate the template file."
    exit 1
}

# Check if logged into Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Error "Not logged into Azure. Please run 'az login' first."
    exit 1
}

# Register the Microsoft.VirtualMachineImages provider if not already registered
Write-Host "Checking Azure Image Builder provider registration..." -ForegroundColor Yellow
$provider = az provider show --namespace Microsoft.VirtualMachineImages --query "registrationState" -o tsv

if ($provider -ne "Registered") {
    Write-Host "Registering Microsoft.VirtualMachineImages provider..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.VirtualMachineImages
    
    # Wait for registration to complete
    do {
        Start-Sleep -Seconds 10
        $provider = az provider show --namespace Microsoft.VirtualMachineImages --query "registrationState" -o tsv
        Write-Host "Provider status: $provider"
    } while ($provider -eq "Registering")
    
    if ($provider -ne "Registered") {
        Write-Error "Failed to register Microsoft.VirtualMachineImages provider"
        exit 1
    }
}

Write-Host "Provider is registered: $provider" -ForegroundColor Green

# Check if template already exists
$existingTemplate = az image builder show --name $TemplateName --resource-group $ResourceGroupName 2>$null

if ($existingTemplate) {
    Write-Host "Image Builder template '$TemplateName' already exists." -ForegroundColor Yellow
    $response = Read-Host "Do you want to delete and recreate it? (y/N)"
    
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "Deleting existing template..." -ForegroundColor Yellow
        az image builder delete --name $TemplateName --resource-group $ResourceGroupName --yes
        Start-Sleep -Seconds 10
    } else {
        Write-Host "Keeping existing template. Exiting." -ForegroundColor Yellow
        exit 0
    }
}

# Create the Image Builder template
Write-Host "Creating Image Builder template..." -ForegroundColor Yellow

try {
    az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file $JsonFilePath `
        --parameters imageTemplateName=$TemplateName
    
    Write-Host "Image Builder template created successfully!" -ForegroundColor Green
    
    # Show template details
    Write-Host "Template details:" -ForegroundColor Yellow
    az image builder show --name $TemplateName --resource-group $ResourceGroupName --output table
    
} catch {
    Write-Error "Failed to create Image Builder template: $_"
    exit 1
}

Write-Host "=== Image Builder Template Creation Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "To build the image, run:" -ForegroundColor Cyan
Write-Host "az image builder run --name $TemplateName --resource-group $ResourceGroupName" -ForegroundColor White
Write-Host ""
Write-Host "To check build status, run:" -ForegroundColor Cyan
Write-Host "az image builder show-runs --name $TemplateName --resource-group $ResourceGroupName" -ForegroundColor White 