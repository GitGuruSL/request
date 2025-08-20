const axios = require('axios');

async function testAPIResponse() {
  try {
    const response = await axios.get('http://localhost:3001/api/business-verifications');
    console.log('=== API Response ===');
    console.log(JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testAPIResponse();
