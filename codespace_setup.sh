#!/bin/bash

# QuickBooks Integration - GitHub Codespace Setup
# This script configures the Codespace environment for Salesforce development

set -euo pipefail

echo "🚀 Setting up QuickBooks Salesforce Integration in Codespace"
echo "==========================================================="

# Function to print colored output
print_status() {
    echo -e "\033[1;34m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️  $1\033[0m"
}

# Check if running in Codespace
if [[ -z "${CODESPACE_NAME:-}" ]]; then
    print_warning "This script is optimized for GitHub Codespaces"
    print_warning "You can still run it in other environments, but some features may not work"
fi

print_status "Step 1: Installing Salesforce CLI..."

# Install Salesforce CLI if not already installed
if ! command -v sf &> /dev/null; then
    npm install -g @salesforce/cli
    print_success "Salesforce CLI installed"
else
    print_success "Salesforce CLI already installed"
fi

# Verify installation
SF_VERSION=$(sf --version)
echo "📦 $SF_VERSION"

print_status "Step 2: Configuring environment..."

# Create .sfdx directory if it doesn't exist
mkdir -p ~/.sfdx

# Set up git config if not already configured
if ! git config user.name &> /dev/null; then
    echo "🔧 Git configuration needed for deployment tracking"
    echo "Please enter your details:"
    read -p "Git username: " git_username
    read -p "Git email: " git_email
    
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    print_success "Git configured"
fi

print_status "Step 3: Verifying project structure..."

# Check project structure
if [[ ! -f "sfdx-project.json" ]]; then
    print_error "sfdx-project.json not found. Make sure you're in the project root."
    exit 1
fi

if [[ ! -d "force-app/main/default" ]]; then
    print_error "force-app directory structure not found."
    exit 1
fi

print_success "Project structure verified"

print_status "Step 4: Checking components..."

# Count components
APEX_CLASSES=$(find force-app/main/default/classes -name "*.cls" 2>/dev/null | wc -l)
TRIGGERS=$(find force-app/main/default/triggers -name "*.trigger" 2>/dev/null | wc -l)

echo "📊 Found $APEX_CLASSES Apex classes and $TRIGGERS triggers"

print_status "Step 5: Setting up authentication helpers..."

# Create authentication script
cat > auth_production.sh << 'EOF'
#!/bin/bash
echo "🔐 Authenticating with Salesforce Production Org"
echo "This will open a browser window for authentication..."
echo ""
echo "In Codespace, this will show a URL you can click to authenticate."
echo ""

sf org login web --alias ProductionOrg --instance-url https://login.salesforce.com

if sf org list | grep -q "ProductionOrg"; then
    echo "✅ Authentication successful!"
    sf org display --target-org ProductionOrg
else
    echo "❌ Authentication failed. Please try again."
    exit 1
fi
EOF

chmod +x auth_production.sh

# Create sandbox authentication script
cat > auth_sandbox.sh << 'EOF'
#!/bin/bash
echo "🔐 Authenticating with Salesforce Sandbox"
echo "This will open a browser window for authentication..."
echo ""

sf org login web --alias SandboxOrg --instance-url https://test.salesforce.com

if sf org list | grep -q "SandboxOrg"; then
    echo "✅ Sandbox authentication successful!"
    sf org display --target-org SandboxOrg
else
    echo "❌ Sandbox authentication failed. Please try again."
    exit 1
fi
EOF

chmod +x auth_sandbox.sh

print_success "Authentication helpers created"

print_status "Step 6: Creating Codespace-optimized deployment script..."

# Create Codespace deployment script
cat > deploy_codespace.sh << 'EOF'
#!/bin/bash

# QuickBooks Integration - Codespace Deployment Script
set -euo pipefail

PROD_ALIAS="ProductionOrg"
SANDBOX_ALIAS="SandboxOrg"
SOURCE_PATH="force-app/main/default"

print_status() {
    echo -e "\033[1;34m$1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

echo "🚀 QuickBooks Integration - Codespace Deployment"
echo "==============================================="

# Check authentication
print_status "Checking authentication..."

if sf org list | grep -q "$PROD_ALIAS"; then
    print_success "Production org authenticated"
    TARGET_ORG="$PROD_ALIAS"
    ENV_NAME="Production"
elif sf org list | grep -q "$SANDBOX_ALIAS"; then
    print_success "Sandbox org authenticated"
    TARGET_ORG="$SANDBOX_ALIAS"
    ENV_NAME="Sandbox"
else
    print_error "No authenticated orgs found!"
    echo ""
    echo "Please authenticate first:"
    echo "  For Production: ./auth_production.sh"
    echo "  For Sandbox:    ./auth_sandbox.sh"
    exit 1
fi

print_status "Deploying to $ENV_NAME..."

# Show what will be deployed
echo ""
echo "📦 Components to deploy:"
find $SOURCE_PATH -name "*.cls" -o -name "*.trigger" | while read file; do
    echo "   • $(basename "$file")"
done
echo ""

# Confirm deployment
if [[ "$ENV_NAME" == "Production" ]]; then
    echo "⚠️  You are about to deploy to PRODUCTION!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Validate first
print_status "Step 1: Validating deployment..."
if sf project deploy start --source-dir "$SOURCE_PATH" --target-org "$TARGET_ORG" --check-only --test-level RunLocalTests --wait 15; then
    print_success "Validation passed!"
else
    print_error "Validation failed! Check the errors above."
    exit 1
fi

# Deploy
print_status "Step 2: Deploying to $ENV_NAME..."
if sf project deploy start --source-dir "$SOURCE_PATH" --target-org "$TARGET_ORG" --test-level RunLocalTests --wait 15; then
    echo ""
    print_success "DEPLOYMENT SUCCESSFUL!"
    echo "======================="
    echo ""
    echo "✅ Deployed to: $ENV_NAME"
    echo "✅ Components: $(find $SOURCE_PATH -name "*.cls" -o -name "*.trigger" | wc -l) files"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure custom fields (see README)"
    echo "2. Set up Named Credential 'QuickBooks_NC'"
    echo "3. Test the integration"
else
    print_error "Deployment failed! Check the errors above."
    exit 1
fi
EOF

chmod +x deploy_codespace.sh

print_success "Codespace deployment script created"

print_status "Step 7: Creating quick commands..."

# Create package.json with npm scripts for easy commands
cat > package.json << 'EOF'
{
  "name": "quickbooks-salesforce-integration",
  "version": "1.0.0",
  "description": "QuickBooks Salesforce Integration for Codespace",
  "scripts": {
    "auth:prod": "./auth_production.sh",
    "auth:sandbox": "./auth_sandbox.sh",
    "deploy": "./deploy_codespace.sh",
    "validate:prod": "sf project deploy start --source-dir force-app/main/default --target-org ProductionOrg --check-only --test-level RunLocalTests",
    "validate:sandbox": "sf project deploy start --source-dir force-app/main/default --target-org SandboxOrg --check-only --test-level RunLocalTests",
    "test": "sf apex run test --target-org ProductionOrg --test-level RunLocalTests",
    "list-orgs": "sf org list",
    "help": "echo 'Available commands:\n  npm run auth:prod     - Authenticate with production\n  npm run auth:sandbox  - Authenticate with sandbox\n  npm run deploy        - Deploy to authenticated org\n  npm run validate:prod - Validate against production\n  npm run test          - Run all tests\n  npm run list-orgs     - List authenticated orgs'"
  },
  "keywords": ["salesforce", "quickbooks", "integration"],
  "author": "Generated by Codespace Setup",
  "license": "MIT"
}
EOF

print_success "NPM scripts configured"

print_status "Step 8: Final verification..."

# Run final checks
if sf --version &> /dev/null; then
    print_success "Salesforce CLI working"
else
    print_error "Salesforce CLI not working properly"
fi

if [[ -f "deploy_codespace.sh" && -x "deploy_codespace.sh" ]]; then
    print_success "Deployment script ready"
else
    print_error "Deployment script not properly created"
fi

echo ""
echo "🎉 CODESPACE SETUP COMPLETE!"
echo "============================"
echo ""
echo "🚀 Quick start commands:"
echo "  npm run help           - Show all available commands"
echo "  npm run auth:prod      - Authenticate with production"
echo "  npm run auth:sandbox   - Authenticate with sandbox"
echo "  npm run deploy         - Deploy to authenticated org"
echo ""
echo "📁 Files created:"
echo "  • auth_production.sh   - Production authentication"
echo "  • auth_sandbox.sh      - Sandbox authentication"
echo "  • deploy_codespace.sh  - Deployment script"
echo "  • package.json         - NPM commands"
echo ""
echo "📖 For detailed instructions, see:"
echo "  • CODESPACE_README.md"
echo "  • PRODUCTION_DEPLOYMENT_INSTRUCTIONS.md"
echo ""
print_success "Your Codespace is ready for Salesforce development!"