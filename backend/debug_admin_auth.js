console.log('🔐 Testing Admin Portal Authentication Flow...\n');

// Simulate the exact API calls the admin portal makes
const testAuthenticatedAPICall = async () => {
  const axios = require('axios');
  
  // Check if we can access the endpoints without auth (should be 401)
  console.log('1️⃣ Testing endpoints without authentication...');
  try {
    const configRes = await axios.get('https://api.alphabet.lk/api/sms/config/LK');
    console.log('❌ Unexpected success - endpoint should require auth');
  } catch (error) {
    console.log(`✅ SMS Config endpoint: ${error.response?.status} ${error.response?.statusText}`);
  }
  
  try {
    const statsRes = await axios.get('https://api.alphabet.lk/api/sms/statistics/LK');
    console.log('❌ Unexpected success - endpoint should require auth');
  } catch (error) {
    console.log(`✅ SMS Statistics endpoint: ${error.response?.status} ${error.response?.statusText}`);
  }
  
  console.log('\n2️⃣ Admin Portal Authentication Status:');
  console.log('❗ The admin portal needs proper authentication to access SMS endpoints');
  console.log('📋 To fix this:');
  console.log('   1. Make sure you are logged into the admin portal');
  console.log('   2. Check browser localStorage for accessToken');
  console.log('   3. If no token, login again with admin credentials');
  console.log('   4. If token exists but getting 401, token may be expired');
  
  console.log('\n3️⃣ Quick Debug Steps:');
  console.log('   • Open browser DevTools (F12)');
  console.log('   • Go to Application → Local Storage → http://localhost:5173');
  console.log('   • Check if "accessToken" exists');
  console.log('   • If missing or expired, login again');
  
  console.log('\n4️⃣ Alternative: Test with deploy-package endpoint');
  console.log('   • The SMS config might be accessible via deploy-package routes');
  console.log('   • Check if the deployed server has different authentication setup');
};

testAuthenticatedAPICall();
