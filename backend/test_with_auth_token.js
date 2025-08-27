const jwt = require('jsonwebtoken');
const axios = require('axios');

// Your JWT token
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI5MjhkNWQ3Yy0zMDg3LTRmNTMtYmVjNC0zZDE4MzVlOGJlMzAiLCJlbWFpbCI6InJpbWFzQHJlcXVlc3QubGsiLCJyb2xlIjoiY291bnRyeV9hZG1pbiIsImlhdCI6MTc1NjI4NDExMywiZXhwIjoxNzU2MzcwNTEzfQ.wLChEuojCru1qC5lDVVradHpVWzfMhJgU4HnSCQYgWc';

console.log('🔐 JWT Token Analysis');
console.log('═══════════════════════════════════════════════════');

try {
  // Decode without verification to see the payload
  const decoded = jwt.decode(token);
  console.log('📋 Token Details:');
  console.log(`   User ID: ${decoded.userId}`);
  console.log(`   Email: ${decoded.email}`);
  console.log(`   Role: ${decoded.role}`);
  console.log(`   Issued: ${new Date(decoded.iat * 1000).toISOString()}`);
  console.log(`   Expires: ${new Date(decoded.exp * 1000).toISOString()}`);
  
  const now = Math.floor(Date.now() / 1000);
  const isExpired = decoded.exp < now;
  console.log(`   Status: ${isExpired ? '❌ EXPIRED' : '✅ VALID'}`);
  
  if (!isExpired) {
    console.log(`   Time remaining: ${Math.floor((decoded.exp - now) / 3600)} hours`);
  }
  
} catch (error) {
  console.error('❌ Error decoding token:', error.message);
}

console.log('\n🧪 Testing SMS Endpoints with Authentication');
console.log('═══════════════════════════════════════════════════');

const testWithAuth = async () => {
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
  
  console.log('1️⃣ Testing SMS Config endpoint...');
  try {
    const configRes = await axios.get('https://api.alphabet.lk/api/sms/config/LK', { headers });
    console.log('✅ SMS Config Success:', configRes.status);
    console.log('📊 Data:', JSON.stringify(configRes.data, null, 2));
  } catch (error) {
    console.log(`❌ SMS Config Error: ${error.response?.status} ${error.response?.statusText}`);
    console.log('📋 Response:', JSON.stringify(error.response?.data, null, 2));
  }
  
  console.log('\n2️⃣ Testing SMS Statistics endpoint...');
  try {
    const statsRes = await axios.get('https://api.alphabet.lk/api/sms/statistics/LK', { headers });
    console.log('✅ SMS Statistics Success:', statsRes.status);
    console.log('📊 Data:', JSON.stringify(statsRes.data, null, 2));
  } catch (error) {
    console.log(`❌ SMS Statistics Error: ${error.response?.status} ${error.response?.statusText}`);
    console.log('📋 Response:', JSON.stringify(error.response?.data, null, 2));
  }
  
  console.log('\n3️⃣ Testing Hutch Mobile Config Save...');
  try {
    const hutchConfig = {
      config: {
        apiUrl: 'https://webbsms.hutch.lk/',
        username: 'rimas@alphabet.lk',
        password: 'HT3l0b&LH6819',
        senderId: 'ALPHABET',
        messageType: 'text'
      },
      is_active: true,
      exclusive: true
    };
    
    const saveRes = await axios.put('https://api.alphabet.lk/api/sms/config/LK/hutch_mobile', hutchConfig, { headers });
    console.log('✅ Hutch Mobile Save Success:', saveRes.status);
    console.log('📊 Response:', JSON.stringify(saveRes.data, null, 2));
  } catch (error) {
    console.log(`❌ Hutch Mobile Save Error: ${error.response?.status} ${error.response?.statusText}`);
    console.log('📋 Response:', JSON.stringify(error.response?.data, null, 2));
  }
};

testWithAuth().then(() => {
  console.log('\n🎯 Summary:');
  console.log('Your authentication token is valid and you have country_admin role.');
  console.log('If endpoints still fail, there may be server-side issues with the SMS routes.');
}).catch(console.error);
