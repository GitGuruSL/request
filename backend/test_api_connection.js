const axios = require('axios');

async function testBusinessAPIWithoutAuth() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    
    // Test without auth first to see the error
    console.log('🔍 Testing business verification API...');
    console.log(`URL: http://localhost:3001/api/business-verifications/user/${userId}`);
    
    try {
      const response = await axios.get(`http://localhost:3001/api/business-verifications/user/${userId}`);
      console.log('✅ Success:', response.data);
    } catch (error) {
      console.log('❌ Auth required. Error:', error.response?.status, error.response?.data);
    }
    
    // Test the test endpoint (no auth required)
    console.log('\n🧪 Testing test endpoint...');
    try {
      const testResponse = await axios.get('http://localhost:3001/api/business-verifications/test');
      console.log('✅ Test endpoint works:', testResponse.data);
    } catch (error) {
      console.log('❌ Test endpoint failed:', error.response?.data || error.message);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
    process.exit(1);
  }
}

testBusinessAPIWithoutAuth();
