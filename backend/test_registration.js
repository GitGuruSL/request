require('dotenv').config();
const axios = require('axios');

async function testRegistration() {
  try {
    // Safety guard to avoid accidental data creation
    if (process.env.ALLOW_TEST_SCRIPTS !== 'true') {
      console.error('Refusing to run test_registration: set ALLOW_TEST_SCRIPTS=true to enable.');
      process.exit(1);
    }
    console.log('Testing user registration...');
    
    const response = await axios.post('http://localhost:3001/api/auth/register', {
      email: 'newtest' + Date.now() + '@example.com',
      password: 'test123',
      display_name: 'Test User',
      first_name: 'Test',
      last_name: 'User'
    });
    
    console.log('Status:', response.status);
    console.log('Response data:');
    console.log(JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testRegistration();
