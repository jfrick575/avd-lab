# Azure Virtual Desktop (AVD) Terraform Infrastructure

This repository contains Terraform configurations to deploy a complete Azure Virtual Desktop environment with the following components:

## Architecture Overview

- **Virtual Network**: Dedicated VNet with subnets for AVD resources
- **Host Pool**: Windows 11 multi-session with 2 session hosts
- **Application Groups**: Desktop and RemoteApp groups
- **Storage**: Azure Files for FSLogix profiles
- **Security**: Key Vault for secrets, Entra ID integration
- **Monitoring**: Log Analytics workspace with AVD insights
- **Image Management**: Azure Image Builder with GitHub Actions automation
- **Scaling**: Scaling plans for cost optimization

## Prerequisites

1. Azure CLI installed and authenticated
2. Terraform >= 1.0 installed
3. Appropriate Azure permissions (Contributor + User Access Administrator)
4. GitHub repository with Actions enabled

## Deployment

### 1. Initialize Terraform Backend

```powershell
# Initialize backend storage
.\deploy.ps1 -InitBackend
```

### 2. Configure Variables

The script will automatically copy `terraform.tfvars.example` to `terraform.tfvars`:

```powershell
# Edit terraform.tfvars with your specific values
# The file will be created automatically on first run
```

### 3. Deploy Infrastructure

```powershell
# Plan the deployment
.\deploy.ps1 -Action plan

# Apply the infrastructure
.\deploy.ps1 -Action apply
```

### 4. Create Image Builder Template (Post-Deployment)

After the infrastructure is deployed, create the Image Builder template:

```powershell
# Get the resource group name from Terraform output
$rgName = terraform output -raw resource_group_name

# Create the Image Builder template
.\scripts\create-image-template.ps1 -ResourceGroupName $rgName -TemplateName "win11-avd-template"

# Build the first image
az image builder run --name "win11-avd-template" --resource-group $rgName
```

### 5. Update Session Hosts to Use Custom Image (Optional)

Once the custom image is built, you can update the session hosts:

1. Update `main.tf` to use the custom image:
   ```hcl
   custom_image_id = module.image_builder.image_version_id
   ```

2. Apply the changes:
   ```powershell
   .\deploy.ps1 -Action apply
   ```

## GitHub Actions

The repository includes GitHub Actions workflows for:
- **Infrastructure Validation**: Terraform plan on pull requests
- **Infrastructure Deployment**: Terraform apply on main branch
- **Image Building**: Monthly automated image updates with Notepad++ and Office 365

### GitHub Setup Required

1. **Create GitHub Secret `AZURE_CREDENTIALS`:**
   ```json
   {
     "clientId": "your-service-principal-id",
     "clientSecret": "your-service-principal-secret",
     "subscriptionId": "02b4788a-7fc7-4485-834f-a7547c61156b",
     "tenantId": "c831cf37-07c4-4845-91f6-9ee7b1c0a6c1"
   }
   ```

2. **Service Principal Permissions:**
   - Contributor on subscription
   - User Access Administrator (for RBAC assignments)

## Monitoring

- Log Analytics workspace with AVD insights enabled
- Azure Monitor Agent (AMA) on all session hosts
- Data Collection Rules (DCR) for performance and event logs

## Security

- All secrets stored in Azure Key Vault
- Entra ID authentication only
- Network Security Groups with minimal required access
- Local admin credentials auto-generated and stored securely

## Cost Optimization

- Scaling plans configured for business hours
- Standard storage tier for FSLogix
- Appropriate VM sizes for multi-session workloads

## Image Management

The solution includes Azure Image Builder setup for custom Windows 11 images:

1. **Shared Image Gallery**: Stores custom image versions
2. **Image Definition**: Windows 11 multi-session with Office 365
3. **Custom Software**: Notepad++ pre-installed
4. **Automated Builds**: Monthly updates via GitHub Actions

### Manual Image Building

```powershell
# Build image manually
az image builder run --name "win11-avd-template" --resource-group $rgName

# Check build status
az image builder show-runs --name "win11-avd-template" --resource-group $rgName
```

## Troubleshooting

### Common Issues

1. **Image Builder Template Creation**: 
   - Ensure Microsoft.VirtualMachineImages provider is registered
   - Check that the user assigned identity has proper permissions

2. **Session Host Deployment**:
   - Initially uses marketplace images
   - Switch to custom images after building them

3. **FSLogix Configuration**:
   - Ensure storage account has proper network access
   - Verify Entra ID authentication is configured

## Directory Structure

```
├── modules/
│   ├── networking/          # VNet, subnets, NSGs
│   ├── storage/            # Azure Files for FSLogix
│   ├── keyvault/           # Key Vault for secrets
│   ├── avd/                # AVD resources
│   ├── monitoring/         # Log Analytics and monitoring
│   └── image-builder/      # Image Builder infrastructure
├── scripts/                # Helper scripts
├── .github/workflows/      # GitHub Actions
├── terraform.tfvars.example
├── deploy.ps1             # Main deployment script
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

## Next Steps

1. **Push to GitHub**: Commit all files to your repository
2. **Set up GitHub secrets** for Azure authentication
3. **Run the deployment script** to create the infrastructure
4. **Create Image Builder template** using the provided script
5. **Add users** to the `AVD-Users-prod` Entra ID group
6. **Test connectivity** using the AVD client

The infrastructure follows Azure best practices with proper naming conventions, security configurations, and cost optimization features. 