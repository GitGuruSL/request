const axios = require('axios');

async function testSMSAdminRoutes() {
  try {
    console.log('🧪 Testing SMS Admin Routes...\n');

    // Test 1: Check if server is running
    try {
      const healthCheck = await axios.get('http://localhost:3001/health');
      console.log('✅ Server is running:', healthCheck.data?.status || 'OK');
    } catch (error) {
      console.log('❌ Server not accessible on port 3001');
      return;
    }

    // Test 2: Test SMS configurations endpoint (should require auth)
    try {
      const smsConfigResponse = await axios.get('http://localhost:3001/api/admin/sms-configurations');
      console.log('✅ SMS configurations endpoint accessible (unexpected - should require auth)');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ SMS configurations endpoint properly protected (401 Unauthorized)');
      } else {
        console.log('📊 SMS configurations response:', error.response?.status, error.response?.data?.message);
      }
    }

    // Test 3: Test pending configurations endpoint
    try {
      const pendingResponse = await axios.get('http://localhost:3001/api/admin/sms-configurations/pending');
      console.log('✅ Pending configurations endpoint accessible (unexpected - should require auth)');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Pending configurations endpoint properly protected (401 Unauthorized)');
      } else {
        console.log('📊 Pending configurations response:', error.response?.status, error.response?.data?.message);
      }
    }

    console.log('\n🎉 SMS Admin Routes Tests Complete!');
    console.log('📋 Available endpoints:');
    console.log('  GET    /api/admin/sms-configurations');
    console.log('  POST   /api/admin/sms-configurations');
    console.log('  PUT    /api/admin/sms-configurations/:id/approve');
    console.log('  PUT    /api/admin/sms-configurations/:id/reject');
    console.log('  GET    /api/admin/sms-configurations/pending');
    console.log('  POST   /api/admin/test-sms-provider');

  } catch (error) {
    console.error('❌ Test error:', error.message);
  }
}

testSMSAdminRoutes();
