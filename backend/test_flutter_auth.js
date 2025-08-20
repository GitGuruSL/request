// Test Flutter app authentication status
const axios = require('axios');

async function testFlutterAuth() {
  console.log('🔐 Testing Flutter Authentication Status...\n');
  
  try {
    // Test if we can access a protected endpoint
    console.log('1. Testing protected endpoint without auth...');
    const response1 = await axios.get('http://localhost:3001/api/business-verifications/user/5af58de3-896d-4cc3-bd0b-177054916335');
    console.log('❌ This should have failed (no auth)');
  } catch (error) {
    if (error.response?.status === 401) {
      console.log('✅ Correctly returned 401: No token provided');
    } else {
      console.log('❌ Unexpected error:', error.response?.status, error.response?.data);
    }
  }
  
  console.log('\n2. Testing user login to get token...');
  try {
    // Try to login the test user
    const loginResponse = await axios.post('http://localhost:3001/api/flutter/auth/login', {
      email: 'rimaz.m.flyil@gmail.com',
      password: 'password123'
    });
    
    if (loginResponse.data.success) {
      const token = loginResponse.data.token;
      console.log('✅ Login successful!');
      console.log('📄 Token received:', token ? 'Yes' : 'No');
      
      if (token) {
        console.log('\n3. Testing protected endpoint with token...');
        const response3 = await axios.get(
          'http://localhost:3001/api/business-verifications/user/5af58de3-896d-4cc3-bd0b-177054916335',
          {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          }
        );
        
        console.log('✅ Protected endpoint works with token!');
        console.log('📊 Business verification data:');
        console.log('- Success:', response3.data.success);
        if (response3.data.data) {
          console.log('- Status:', response3.data.data.status);
          console.log('- Phone Verified:', response3.data.data.phone_verified);
          console.log('- Email Verified:', response3.data.data.email_verified);
          console.log('- Business Name:', response3.data.data.business_name);
        }
      }
    } else {
      console.log('❌ Login failed:', loginResponse.data);
    }
    
  } catch (error) {
    console.error('❌ Login error:', error.response?.data || error.message);
  }
  
  process.exit(0);
}

testFlutterAuth();
