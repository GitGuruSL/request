const axios = require('axios');

async function testBusinessVerificationFlow() {
  // Safety guard to avoid accidental data changes
  if (process.env.ALLOW_TEST_SCRIPTS !== 'true') {
    console.error('Refusing to run test_unified_email_system: set ALLOW_TEST_SCRIPTS=true to enable.');
    process.exit(1);
  }
  const baseURL = 'http://localhost:3001';
  
  // Test data - using the verified user
  const userData = {
    email: 'rimaz.m.flyil@gmail.com',
    password: 'password123' // Replace with actual password if needed
  };
  
  const businessData = {
    business_name: 'Test Business Ltd',
    business_email: 'rimaz.m.flyil@gmail.com', // Same as login email
    business_phone: '+94771234567',
    business_address: '123 Test Street, Colombo',
    business_type: 'logistics',
    registration_number: 'REG123456',
    tax_number: 'TAX789012',
    country_code: 'LK',
    business_description: 'Test business for unified email verification'
  };
  
  try {
    console.log('🧪 Testing business verification flow with unified email system...\n');
    
    // Step 1: Login to get auth token
    console.log('1️⃣ Logging in...');
    const loginResponse = await axios.post(`${baseURL}/api/auth/login`, userData);
    
    console.log('📋 Login response:', JSON.stringify(loginResponse.data, null, 2));
    
    if (!loginResponse.data.success) {
      throw new Error('Login failed');
    }
    
    const token = loginResponse.data.data.token;
    const userId = loginResponse.data.data.user.id;
    console.log(`✅ Login successful - User ID: ${userId}`);
    
    // Step 2: Submit business verification
    console.log('\n2️⃣ Submitting business verification...');
    const headers = { Authorization: `Bearer ${token}` };
    
    const businessResponse = await axios.post(
      `${baseURL}/api/business-verifications`, 
      businessData, 
      { headers }
    );
    
    console.log('📋 Business verification response:');
    console.log(JSON.stringify(businessResponse.data, null, 2));
    
    // Check if email was auto-verified
    if (businessResponse.data.verification && businessResponse.data.verification.email) {
      const emailVerification = businessResponse.data.verification.email;
      
      if (emailVerification.emailVerified && !emailVerification.requiresManualVerification) {
        console.log('\n🎉 SUCCESS: Email was auto-verified (no OTP required)!');
        console.log(`📧 Verification source: ${emailVerification.verificationSource}`);
        console.log(`✅ The unified email system is working correctly!`);
      } else {
        console.log('\n❌ ISSUE: Email still requires manual verification');
        console.log('📧 Email verification details:', emailVerification);
      }
    }
    
    // Step 3: Check the business verification record
    console.log('\n3️⃣ Checking business verification record...');
    const getResponse = await axios.get(
      `${baseURL}/api/business-verifications/user/${userId}`, 
      { headers }
    );
    
    if (getResponse.data.success && getResponse.data.data) {
      const record = getResponse.data.data;
      console.log(`📋 Business record - Email verified: ${record.emailVerified}`);
      
      if (record.emailVerified) {
        console.log('✅ Email verification status correctly saved in database');
      } else {
        console.log('❌ Email verification status not saved correctly');
      }
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

// Run the test
testBusinessVerificationFlow();
