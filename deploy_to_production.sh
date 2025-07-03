#!/bin/bash

# QuickBooks Integration - Production Deployment Script
# Run this after authenticating with: sf org login web --alias ProductionOrg

set -euo pipefail

PROD_ALIAS="ProductionOrg"
SOURCE_PATH="force-app/main/default"

echo "🚀 QuickBooks Integration - Production Deployment"
echo "================================================="

# Check if org is authenticated
echo "🔍 Checking authentication..."
if ! sf org list | grep -q "$PROD_ALIAS"; then
    echo "❌ Production org not authenticated!"
    echo "Please run: sf org login web --alias ProductionOrg"
    exit 1
fi

echo "✅ Production org authenticated"

# Validate deployment first
echo ""
echo "🔍 Step 1: Validating deployment..."
echo "This will run all tests without deploying..."

if sf project deploy start --source-dir "$SOURCE_PATH" --target-org "$PROD_ALIAS" --check-only --test-level RunLocalTests --wait 10; then
    echo "✅ Validation successful!"
else
    echo "❌ Validation failed! Please check the errors above."
    exit 1
fi

# Ask for confirmation before deploying
echo ""
read -p "🚀 Validation passed! Deploy to production? (y/N): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy to production
echo ""
echo "🚀 Step 2: Deploying to production..."
echo "This will deploy all components and run tests..."

if sf project deploy start --source-dir "$SOURCE_PATH" --target-org "$PROD_ALIAS" --test-level RunLocalTests --wait 10; then
    echo ""
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "========================"
    echo ""
    echo "✅ Components deployed:"
    echo "   • 6 Apex classes (QuickBooks integration logic)"
    echo "   • 2 Triggers (Account and Invoice sync)"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Configure custom fields (see PRODUCTION_DEPLOYMENT_INSTRUCTIONS.md)"
    echo "2. Set up Named Credential 'QuickBooks_NC'"
    echo "3. Create and assign permission sets"
    echo "4. Test the integration"
    echo ""
    echo "🔗 Full guide: PRODUCTION_DEPLOYMENT_INSTRUCTIONS.md"
else
    echo "❌ Deployment failed! Please check the errors above."
    exit 1
fi