const axios = require('axios');

async function testDriverVerificationAPI() {
  try {
    console.log('🧪 Testing Driver Verification API...');
    
    // Test if the API is accessible
    const response = await axios.get('http://localhost:3001/api/driver-verifications/test');
    console.log('✅ API Test Response:', response.data);
    
  } catch (error) {
    if (error.response) {
      console.log('📊 API Response Status:', error.response.status);
      console.log('📊 API Response Data:', error.response.data);
    } else {
      console.error('❌ API Test Error:', error.message);
    }
  }
}

testDriverVerificationAPI();
