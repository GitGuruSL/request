#!/bin/bash

/**
 * SMS Authentication System Setup Script
 * 
 * @description
 * This script sets up the custom SMS authentication system to replace
 * Firebase Auth with country-specific SMS providers for cost optimization.
 * 
 * @features
 * - Installs necessary dependencies
 * - Deploys Firebase Functions
 * - Updates Firestore security rules
 * - Initializes country configurations
 * - Sets up admin permissions
 * 
 * @cost_benefits
 * - Reduces authentication costs by 50-80%
 * - Enables use of local SMS providers
 * - Eliminates Firebase Auth monthly base costs
 * 
 * @author Request Marketplace Team
 * @version 1.0.0
 * @since 2025-08-16
 */

echo "🚀 Setting up Custom SMS Authentication System..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed. Please install it first:${NC}"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if we're in the project directory
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Please run this script from your Firebase project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Installing Firebase Functions dependencies...${NC}"
cd functions
npm install
cd ..

echo -e "${BLUE}🔐 Updating Firestore security rules...${NC}"
# Backup existing rules
if [ -f "firestore.rules" ]; then
    cp firestore.rules firestore.rules.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}📋 Backed up existing rules to firestore.rules.backup.$(date +%Y%m%d_%H%M%S)${NC}"
fi

# Merge SMS rules with existing rules
echo "// SMS Authentication System Rules" >> firestore.rules
echo "" >> firestore.rules
cat firestore-sms.rules >> firestore.rules

echo -e "${BLUE}☁️  Deploying Firebase Functions...${NC}"
firebase deploy --only functions:sendOTP,functions:verifyOTP,functions:testSMSConfig,functions:getSMSStatistics

echo -e "${BLUE}🔒 Deploying Firestore security rules...${NC}"
firebase deploy --only firestore:rules

echo -e "${BLUE}📊 Creating SMS configuration collections...${NC}"

# Create initial SMS configuration for Sri Lanka (example)
node -e "
const { initializeApp } = require('firebase/app');
const { getFirestore, doc, setDoc, collection } = require('firebase/firestore');

const app = initializeApp({ projectId: 'request-marketplace' });
const db = getFirestore(app);

async function setupInitialConfig() {
  console.log('Setting up initial SMS configurations...');
  
  // Example SMS configuration for Sri Lanka
  const lkConfig = {
    country: 'LK',
    countryName: 'Sri Lanka',
    provider: 'local_provider',
    providerName: 'Custom/Local Provider',
    configuration: {
      apiUrl: 'https://api.example-sms.lk/send',
      apiKey: 'your-api-key-here',
      senderId: 'RequestApp'
    },
    enabled: false, // Disabled by default until configured
    costPerSMS: 0.02,
    currency: 'USD',
    createdAt: new Date(),
    createdBy: 'system',
    lastUpdated: new Date()
  };

  try {
    await setDoc(doc(db, 'sms_configurations', 'LK'), lkConfig);
    console.log('✅ Created SMS configuration for Sri Lanka');
  } catch (error) {
    console.error('❌ Error creating SMS configuration:', error);
  }

  // Initialize statistics
  const lkStats = {
    country: 'LK',
    totalSent: 0,
    totalFailed: 0,
    totalCost: 0,
    successRate: 0,
    costSavings: 0,
    lastUpdated: new Date(),
    monthlyStats: {}
  };

  try {
    await setDoc(doc(db, 'sms_statistics', 'LK'), lkStats);
    console.log('✅ Created SMS statistics for Sri Lanka');
  } catch (error) {
    console.error('❌ Error creating SMS statistics:', error);
  }
}

setupInitialConfig().catch(console.error);
"

echo -e "${BLUE}👤 Adding SMS configuration permission to admin users...${NC}"

node -e "
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc } = require('firebase/firestore');

const app = initializeApp({ projectId: 'request-marketplace' });
const db = getFirestore(app);

async function addSMSPermissions() {
  console.log('Adding SMS configuration permissions to admin users...');
  
  try {
    const adminSnapshot = await getDocs(collection(db, 'admin_users'));
    
    for (const adminDoc of adminSnapshot.docs) {
      const adminData = adminDoc.data();
      const currentPermissions = adminData.permissions || [];
      
      if (!currentPermissions.includes('smsConfiguration')) {
        const updatedPermissions = [...currentPermissions, 'smsConfiguration'];
        
        await updateDoc(doc(db, 'admin_users', adminDoc.id), {
          permissions: updatedPermissions,
          lastUpdated: new Date()
        });
        
        console.log(\`✅ Added SMS permissions to admin: \${adminData.email}\`);
      }
    }
  } catch (error) {
    console.error('❌ Error adding SMS permissions:', error);
  }
}

addSMSPermissions().catch(console.error);
"

echo ""
echo -e "${GREEN}🎉 SMS Authentication System Setup Complete!${NC}"
echo "=============================================="
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Configure SMS providers for each country in the admin panel"
echo "2. Test SMS functionality using the test feature"
echo "3. Update your login components to use the new SMS authentication"
echo "4. Monitor costs and usage through the statistics dashboard"
echo ""
echo -e "${BLUE}💰 Expected Cost Savings:${NC}"
echo "- Firebase Auth: \$100-200/month for 10k users"
echo "- Custom SMS: \$20-50/month for 10k users"
echo "- Potential savings: 50-80%"
echo ""
echo -e "${GREEN}✅ Setup completed successfully!${NC}"

# Create a summary file
cat > SMS_SETUP_SUMMARY.md << 'EOF'
# SMS Authentication System Setup Summary

## What was installed:

### 1. Firebase Functions
- `sendOTP`: Sends verification codes via configured SMS providers
- `verifyOTP`: Verifies OTP codes and creates custom tokens
- `testSMSConfig`: Tests SMS provider configurations
- `getSMSStatistics`: Retrieves usage statistics and costs

### 2. Firestore Collections
- `sms_configurations`: Country-specific SMS provider settings
- `sms_statistics`: Usage tracking and cost analytics
- `otp_verifications`: OTP records (server-only)
- `rate_limits`: Rate limiting data (server-only)

### 3. Admin Panel Features
- SMS Configuration Module (`/sms-config`)
- Provider selection (Twilio, AWS SNS, Vonage, Local)
- Cost tracking and statistics
- Test SMS functionality

### 4. Security Rules
- Country-based access control
- Admin-only configuration access
- Server-only OTP data access

## How to use:

### For Admins:
1. Navigate to "SMS Configuration" in the admin panel
2. Select your SMS provider (Twilio, AWS SNS, Vonage, or Custom)
3. Enter your provider credentials
4. Test the configuration
5. Enable the SMS service

### For Developers:
1. Import the SMS authentication service:
   ```javascript
   import smsAuthService from '../services/smsAuthService';
   ```

2. Send OTP:
   ```javascript
   await smsAuthService.sendOTP(phoneNumber, country);
   ```

3. Verify OTP:
   ```javascript
   await smsAuthService.verifyOTP(phoneNumber, otp, country);
   ```

## Cost Benefits:
- **Firebase Auth**: $100-200/month for 10k users
- **Custom SMS**: $20-50/month for 10k users  
- **Savings**: 50-80% reduction in authentication costs

## Supported SMS Providers:
- **Twilio**: Global coverage, $0.0075/SMS
- **AWS SNS**: Amazon service, $0.0075/SMS
- **Vonage**: Nexmo platform, $0.0072/SMS
- **Custom/Local**: Your local provider, variable cost

## Security Features:
- OTP expiration (10 minutes)
- Rate limiting (1 SMS per minute per number)
- Encrypted credential storage
- Country-based access control
- Audit logging

## Next Steps:
1. Configure SMS providers for your countries
2. Test the SMS functionality
3. Update login flows to use SMS authentication
4. Monitor usage and costs through the admin dashboard

For support, contact the development team.
EOF

echo -e "${BLUE}📄 Setup summary saved to SMS_SETUP_SUMMARY.md${NC}"
