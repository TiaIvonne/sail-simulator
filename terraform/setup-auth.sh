#!/bin/bash
# Setup script for Azure authentication without browser access

echo "🔐 Azure Authentication Setup for Terraform"
echo "============================================"

echo ""
echo "Since you don't have browser access, we'll use service principal authentication."
echo "You have two options:"
echo ""

echo "OPTION 1: Use existing Azure CLI session (if you can login elsewhere)"
echo "----------------------------------------------------------------------"
echo "If you can login to Azure CLI on another machine or device:"
echo "1. Run: az login (on the other device)"
echo "2. Run: az account show --query '{subscriptionId:id, tenantId:tenantId}'"
echo "3. Create a service principal: az ad sp create-for-rbac --name terraform-sp --role Contributor"
echo "4. Copy the values here"
echo ""

echo "OPTION 2: Get values from Azure Portal"
echo "--------------------------------------"
echo "1. Go to Azure Portal → Azure Active Directory → App registrations"
echo "2. Click 'New registration'"
echo "3. Name: 'terraform-boat-racing'"
echo "4. Click 'Register'"
echo "5. Copy the 'Application (client) ID' and 'Directory (tenant) ID'"
echo "6. Go to 'Certificates & secrets' → 'New client secret'"
echo "7. Copy the secret value"
echo "8. Go to Subscriptions → Your subscription → Access control (IAM)"
echo "9. Add role assignment → Contributor → Select your app"
echo ""

echo "Once you have the values, create a file called 'azure-auth.env':"
echo ""
echo "# Save this as azure-auth.env"
echo "export ARM_SUBSCRIPTION_ID=\"your-subscription-id\""
echo "export ARM_CLIENT_ID=\"your-client-id\""
echo "export ARM_CLIENT_SECRET=\"your-client-secret\""
echo "export ARM_TENANT_ID=\"your-tenant-id\""
echo ""

echo "Then run:"
echo "source azure-auth.env"
echo "terraform plan"
echo ""

echo "Would you like me to create a template azure-auth.env file? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    cat > azure-auth.env << 'EOF'
# Azure Authentication Environment Variables
# Replace with your actual values

export ARM_SUBSCRIPTION_ID="your-subscription-id-here"
export ARM_CLIENT_ID="your-client-id-here" 
export ARM_CLIENT_SECRET="your-client-secret-here"
export ARM_TENANT_ID="your-tenant-id-here"

# After updating the values above, run:
# source azure-auth.env
# terraform plan
EOF
    echo "✅ Created azure-auth.env template file"
    echo "📝 Edit it with your actual Azure credentials"
else
    echo "👍 Okay, you can create the environment file manually"
fi
