#!/bin/bash

# AWS SES Firebase Functions Setup Script
# This script helps configure AWS SES with Firebase Functions

set -e

echo "🚀 AWS SES Configuration Setup for Firebase Functions"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Please run this script from the functions directory"
    echo "Usage: cd functions && bash ../setup-aws-ses.sh"
    exit 1
fi

echo ""
echo "📧 This script will configure AWS SES for your Firebase Functions"
echo "You'll need:"
echo "  - AWS Access Key ID"
echo "  - AWS Secret Access Key"
echo "  - AWS Region (default: us-east-1)"
echo "  - Verified sender email address"
echo ""

# Prompt for AWS credentials
read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
read -p "Enter AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter sender email address: " SES_FROM_EMAIL
read -p "Enter sender name [Request Marketplace]: " SES_FROM_NAME
SES_FROM_NAME=${SES_FROM_NAME:-"Request Marketplace"}

echo ""
echo "🔧 Configuring Firebase Functions environment..."

# Set Firebase Functions config
firebase functions:config:set aws.access_key_id="$AWS_ACCESS_KEY_ID"
firebase functions:config:set aws.secret_access_key="$AWS_SECRET_ACCESS_KEY"
firebase functions:config:set aws.region="$AWS_REGION"
firebase functions:config:set aws.ses_from_email="$SES_FROM_EMAIL"
firebase functions:config:set aws.ses_from_name="$SES_FROM_NAME"

echo ""
echo "✅ Configuration set successfully!"
echo ""
echo "📝 Next steps:"
echo "  1. Verify your sender email in AWS SES Console"
echo "  2. Run: firebase deploy --only functions"
echo "  3. Test the email functionality"
echo ""
echo "🔍 To view current configuration:"
echo "  firebase functions:config:get"
echo ""
echo "📊 To test email sending:"
echo "  Use the Firebase Functions emulator or console"
echo ""

# Create local .env file for development
echo "🔧 Creating local .env file for development..."
cat > .env << EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
SES_FROM_EMAIL=$SES_FROM_EMAIL
SES_FROM_NAME=$SES_FROM_NAME
EOF

echo "✅ Local .env file created for development"
echo ""
echo "⚠️  Security Note:"
echo "  - Never commit .env file to version control"
echo "  - Rotate AWS keys regularly"
echo "  - Use least privilege IAM policies"
echo ""
echo "🎉 AWS SES setup complete!"
echo "📖 See AWS_SES_CONFIGURATION.md for detailed documentation"
