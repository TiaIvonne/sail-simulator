# Simple Terraform Setup for Boat Racing Project

This is a **student-friendly**, single-file Terraform configuration that creates your entire Azure lambda architecture in one go!

## 🚀 Quick Start (5 minutes)

### 1. Prerequisites
```bash
# Install Terraform (if not already installed)
brew install terraform

# Install Azure CLI (if not already installed)  
brew install azure-cli

# Login to Azure
az login
```

### 2. Configure Your Settings
```bash
cd terraform

# IMPORTANT: Update your password in terraform.tfvars
# Change "YourSecurePassword123!" to something secure!
nano terraform.tfvars
```

### 3. Deploy Everything
```bash
terraform init
terraform plan
terraform apply
```

That's it! 🎉

## 📋 What Gets Created

- **Resource Group** - Contains everything
- **Event Hub** - For real-time data ingestion
- **SQL Database** - For data storage (Basic tier, ~$5/month)
- **Stream Analytics Job** - For data processing
- **Storage Account** - For Stream Analytics checkpoints
- **Firewall Rules** - Allow Grafana Cloud access

## 🔧 After Deployment

### 1. Update Your Python Simulator
```bash
# Get the connection string
terraform output event_hub_connection_string

# Update race_simulator.py with the new values
```

### 2. Set Up Database Schema
```bash
# Get database details
terraform output sql_server_name
terraform output sql_database_name

# Run your setup_database.sql script
```

### 3. Start Stream Analytics Job
- Go to Azure Portal
- Find your Stream Analytics job
- Click "Start"

### 4. Update Grafana
- Use the new SQL server name from terraform output
- Same database name and credentials

## 💰 Cost Estimate
- **Total**: ~$15-25/month
- **SQL Database**: ~$5/month (Basic tier)
- **Event Hub**: ~$10/month (Standard tier)
- **Stream Analytics**: ~$10/month (1 SU)
- **Storage**: <$1/month

## 🗑️ Clean Up
To delete everything:
```bash
terraform destroy
```

## 🔧 Customization

Want to change something? Edit `main.tf`:

```hcl
# Change region
variable "location" {
  default = "West Europe"  # Change this
}

# Change SQL password
variable "sql_admin_password" {
  default = "YourNewPassword123!"  # Change this
}
```

## 📊 Outputs

After deployment, get important values:
```bash
terraform output deployment_summary
terraform output sql_server_name
terraform output event_hub_name
```

## 🆘 Troubleshooting

**Problem**: `terraform apply` fails  
**Solution**: Make sure you're logged into Azure (`az login`)

**Problem**: SQL Database connection fails  
**Solution**: Check firewall rules in Azure Portal

**Problem**: Stream Analytics job won't start  
**Solution**: Check that input/output connections are valid

---

**This replaces all your manual Azure Portal clicking with code!** 🏆
