const axios = require('axios');

async function testBusinessAPI() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    const response = await axios.get(`http://localhost:3001/api/business-verifications/user/${userId}`);
    
    console.log('🏢 Business Verification API Response:');
    console.log('Status:', response.status);
    console.log('Success:', response.data.success);
    console.log('Data:', JSON.stringify(response.data, null, 2));
    
    if (response.data.data) {
      console.log('\n📋 Business Details:');
      console.log('- Status:', response.data.data.status);
      console.log('- Is Verified:', response.data.data.is_verified);
      console.log('- Phone Verified:', response.data.data.phone_verified);
      console.log('- Email Verified:', response.data.data.email_verified);
      console.log('- Business Name:', response.data.data.business_name);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ API Error:', error.response?.data || error.message);
    process.exit(1);
  }
}

testBusinessAPI();
