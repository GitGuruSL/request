const axios = require('axios');

async function testDriverVerificationFlow() {
  // Safety guard to avoid accidental data changes
  if (process.env.ALLOW_TEST_SCRIPTS !== 'true') {
    console.error('Refusing to run test_driver_email_verification: set ALLOW_TEST_SCRIPTS=true to enable.');
    process.exit(1);
  }
  const baseURL = 'http://localhost:3001';
  
  // Test data - using the verified user
  const userData = {
    email: 'rimaz.m.flyil@gmail.com',
    password: 'password123'
  };
  
  const driverData = {
    userId: null, // Will be set after login
    fullName: 'Mike Rose',
    dateOfBirth: '1990-01-01',
    gender: 'male',
    nicNumber: 'NIC987654321',
    phoneNumber: '+94771234567',
    email: 'rimaz.m.flyil@gmail.com', // Same as login email
    licenseNumber: 'DL123456789',
    vehicleTypeId: null,
    vehicleTypeName: 'car',
    countryCode: 'LK',
    cityId: null,
    cityName: 'Colombo'
  };
  
  try {
    console.log('🧪 Testing driver verification flow with unified email system...\n');
    
    // Step 1: Login to get auth token
    console.log('1️⃣ Logging in...');
    const loginResponse = await axios.post(`${baseURL}/api/auth/login`, userData);
    
    if (!loginResponse.data.success) {
      throw new Error('Login failed');
    }
    
    const token = loginResponse.data.data.token;
    const userId = loginResponse.data.data.user.id;
    console.log(`✅ Login successful - User ID: ${userId}`);
    
    // Step 2: Submit driver verification
    console.log('\n2️⃣ Submitting driver verification...');
    const headers = { Authorization: `Bearer ${token}` };
    
    // Set the userId in the driver data
    driverData.userId = userId;
    
    const driverResponse = await axios.post(
      `${baseURL}/api/driver-verifications`, 
      driverData, 
      { headers }
    );
    
    console.log('📋 Driver verification response:');
    console.log(JSON.stringify(driverResponse.data, null, 2));
    
    // Check if email was auto-verified
    if (driverResponse.data.data) {
      const data = driverResponse.data.data;
      const emailVerified = data.emailVerified || data.email_verified;
      const requiresEmailVerification = data.requiresEmailVerification;
      const emailVerificationSource = data.emailVerificationSource || data.email_verification_source;
      
      if (emailVerified && !requiresEmailVerification) {
        console.log('\n🎉 SUCCESS: Email was auto-verified (no OTP required)!');
        console.log(`📧 Verification source: ${emailVerificationSource}`);
        console.log(`✅ The unified email system is working for driver verification!`);
      } else {
        console.log('\n❌ ISSUE: Email still requires manual verification');
        console.log('📧 Email verification details:', { emailVerified, requiresEmailVerification, emailVerificationSource });
      }
    }
    
    // Step 3: Check the driver verification record
    console.log('\n3️⃣ Checking driver verification record...');
    const getResponse = await axios.get(
      `${baseURL}/api/driver-verifications/user/${userId}`, 
      { headers }
    );
    
    if (getResponse.data.success && getResponse.data.data) {
      const record = getResponse.data.data;
      console.log(`📋 Driver record - Email verified: ${record.emailVerified || record.email_verified}`);
      
      if (record.emailVerified || record.email_verified) {
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
testDriverVerificationFlow();
