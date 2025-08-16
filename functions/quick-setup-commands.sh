#!/bin/bash

# Quick AWS SES Setup Commands
# Replace the values below with your actual AWS credentials

echo "🚀 Quick AWS SES Setup Commands"
echo "================================"
echo ""
echo "Copy and paste these commands one by one, replacing with your actual values:"
echo ""

echo "# 1. Set AWS Access Key ID"
echo 'firebase functions:config:set aws.access_key_id="YOUR_AWS_ACCESS_KEY_ID"'
echo ""

echo "# 2. Set AWS Secret Access Key"
echo 'firebase functions:config:set aws.secret_access_key="YOUR_AWS_SECRET_ACCESS_KEY"'
echo ""

echo "# 3. Set AWS Region (most common is us-east-1)"
echo 'firebase functions:config:set aws.region="us-east-1"'
echo ""

echo "# 4. Set your verified sender email"
echo 'firebase functions:config:set aws.ses_from_email="noreply@yourdomain.com"'
echo ""

echo "# 5. Set your sender name"
echo 'firebase functions:config:set aws.ses_from_name="Request Marketplace"'
echo ""

echo "# 6. Deploy the functions"
echo 'firebase deploy --only functions'
echo ""

echo "# 7. Test the configuration"
echo 'node test-auth-system.js'
echo ""

echo "📝 Important:"
echo "- Get your AWS credentials from AWS IAM Console"
echo "- Make sure your sender email is verified in AWS SES"
echo "- For production, verify your domain in AWS SES"
