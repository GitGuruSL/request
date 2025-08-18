require('dotenv').config();
const axios = require('axios');

async function testProfileCompletion() {
  try {
    // First register a user
    console.log('1. Registering test user...');
    const registerResponse = await axios.post('http://localhost:3001/api/auth/register', {
      email: 'profiletest' + Date.now() + '@example.com',
      password: 'temp123',
      display_name: 'Test User'
    });
    
    console.log('Registration Status:', registerResponse.status);
    console.log('Registration Response:', JSON.stringify(registerResponse.data, null, 2));
    
    const token = registerResponse.data.token;
    console.log('Token:', token.substring(0, 20) + '...');
    
    // Now test profile completion
    console.log('\n2. Completing profile...');
    const profileResponse = await axios.put('http://localhost:3001/api/auth/profile', {
      first_name: 'John',
      last_name: 'Doe',
      display_name: 'John Doe',
      password: 'newpassword123'
    }, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('Profile Update Status:', profileResponse.status);
    console.log('Profile Update Response:', JSON.stringify(profileResponse.data, null, 2));
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testProfileCompletion();
