#!/bin/bash

# Package Sample Application for CodeDeploy
# This script creates a deployable ZIP file for CodeDeploy

set -e

echo "📦 Packaging sample application for CodeDeploy..."

# Change to the deployment assets directory
cd "$(dirname "$0")"

# Create deployment package directory
PACKAGE_DIR="auditstage-deployment-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$PACKAGE_DIR"

echo "📋 Copying deployment files..."

# Copy appspec.yml
cp appspec.yml "$PACKAGE_DIR/"

# Copy scripts directory
cp -r scripts "$PACKAGE_DIR/"

# Copy sample application
cp -r sample-app "$PACKAGE_DIR/"

# Create deployment package ZIP
ZIP_FILE="$PACKAGE_DIR.zip"
echo "🗜️  Creating ZIP package: $ZIP_FILE"
zip -r "$ZIP_FILE" "$PACKAGE_DIR/"

# Clean up temporary directory
rm -rf "$PACKAGE_DIR"

echo "✅ Package created successfully: $ZIP_FILE"
echo ""
echo "📊 Package contents:"
echo "├── appspec.yml (CodeDeploy configuration)"
echo "├── scripts/ (Deployment lifecycle hooks)"
echo "│   ├── install_dependencies.sh"
echo "│   ├── setup_permissions.sh"
echo "│   ├── start_application.sh"
echo "│   ├── stop_application.sh"
echo "│   └── validate_service.sh"
echo "└── sample-app/ (Node.js application)"
echo "    ├── package.json"
echo "    ├── index.js"
echo "    └── README.md"
echo ""
echo "🚀 Upload this ZIP file to S3 and use with CodeDeploy!"
echo ""
echo "💡 Usage with AWS CLI:"
echo "aws s3 cp $ZIP_FILE s3://your-codedeploy-bucket/"
echo "aws deploy create-deployment \\"
echo "  --application-name auditstage-app \\"
echo "  --deployment-group-name auditstage-deployment-group \\"
echo "  --s3-location bucket=your-codedeploy-bucket,key=$ZIP_FILE,bundleType=zip"
