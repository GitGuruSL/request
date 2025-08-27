/**
 * Test script to verify unified phone verification system
 * This will test the unified verification across all three tables
 */
const { checkUnifiedPhoneVerification } = require('./utils/unifiedVerification');

async function testUnifiedVerification() {
  console.log('🧪 Testing Unified Phone Verification System...\n');

  // Test cases
  const testCases = [
    {
      userId: '5af58de3-896d-4cc3-bd0b-177054916335', // Replace with actual user ID
      phone: '+94725742238',
      description: 'Test phone number with +94 format'
    },
    {
      userId: '5af58de3-896d-4cc3-bd0b-177054916335',
      phone: '0725742238',
      description: 'Test phone number with 0 prefix'
    },
    {
      userId: '5af58de3-896d-4cc3-bd0b-177054916335',
      phone: '725742238',
      description: 'Test phone number without prefix'
    }
  ];

  for (const testCase of testCases) {
    console.log(`📱 Testing: ${testCase.description}`);
    console.log(`   User ID: ${testCase.userId}`);
    console.log(`   Phone: ${testCase.phone}`);
    
    try {
      const result = await checkUnifiedPhoneVerification(testCase.userId, testCase.phone);
      
      console.log(`   ✅ Result:`);
      console.log(`      Phone Verified: ${result.phoneVerified}`);
      console.log(`      Source: ${result.verificationSource || 'None'}`);
      console.log(`      Requires Manual: ${result.requiresManualVerification}`);
      console.log(`      Checked Tables: ${JSON.stringify(result.checkedTables)}`);
      if (result.verifiedPhone) {
        console.log(`      Verified Phone: ${result.verifiedPhone}`);
      }
      
    } catch (error) {
      console.log(`   ❌ Error: ${error.message}`);
    }
    
    console.log(''); // Empty line for readability
  }
}

// Run the test
testUnifiedVerification()
  .then(() => {
    console.log('🎉 Unified verification test completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Test failed:', error);
    process.exit(1);
  });
