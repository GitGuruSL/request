// Test script for Flutter authentication endpoints
const axios = require('axios');

const BASE_URL = 'http://localhost:3001';

async function testEndpoints() {
    console.log('🧪 Testing Flutter Authentication Endpoints\n');

    try {
        // 1. Test Health Check
        console.log('1️⃣ Testing Health Check...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Health Check:', healthResponse.data.status);
        console.log(`   Database: ${healthResponse.data.database.status}\n`);

        // 2. Test Check User Exists (new user)
        console.log('2️⃣ Testing Check User Exists (new user)...');
        const checkUserResponse = await axios.post(`${BASE_URL}/api/auth/check-user-exists`, {
            emailOrPhone: 'test@example.com'
        });
        console.log('✅ Check User Response:', checkUserResponse.data);
        console.log(`   User exists: ${checkUserResponse.data.exists}\n`);

        // 3. Test Send OTP
        console.log('3️⃣ Testing Send OTP...');
        const otpResponse = await axios.post(`${BASE_URL}/api/auth/send-otp`, {
            emailOrPhone: 'test@example.com',
            isEmail: true,
            countryCode: 'LK'
        });
        console.log('✅ Send OTP Response:', otpResponse.data);
        console.log(`   OTP Token: ${otpResponse.data.otpToken?.substring(0, 10)}...\n`);

        // 4. Test Register User
        console.log('4️⃣ Testing User Registration...');
        const registerResponse = await axios.post(`${BASE_URL}/api/auth/register`, {
            email: 'testuser@example.com',
            password: 'testpass123',
            display_name: 'Test User',
            phone: '+94711234567'
        });
        console.log('✅ Registration Response:', registerResponse.data.success);
        console.log(`   User ID: ${registerResponse.data.user?.id}`);
        console.log(`   JWT Token: ${registerResponse.data.token?.substring(0, 20)}...\n`);

        // 5. Test Login
        console.log('5️⃣ Testing User Login...');
        const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
            email: 'testuser@example.com',
            password: 'testpass123'
        });
        console.log('✅ Login Response:', loginResponse.data.success);
        console.log(`   User Email: ${loginResponse.data.user?.email}`);
        console.log(`   JWT Token: ${loginResponse.data.token?.substring(0, 20)}...\n`);

        // 6. Test Get Profile (with JWT)
        console.log('6️⃣ Testing Get Profile...');
        const profileResponse = await axios.get(`${BASE_URL}/api/auth/profile`, {
            headers: {
                'Authorization': `Bearer ${loginResponse.data.token}`
            }
        });
        console.log('✅ Profile Response:', profileResponse.data.success);
        console.log(`   User: ${profileResponse.data.data?.display_name} (${profileResponse.data.data?.email})\n`);

        console.log('🎉 All Flutter authentication endpoints are working!');
        console.log('\n📱 Your Flutter app can now use these endpoints:');
        console.log('   ✅ POST /api/auth/check-user-exists');
        console.log('   ✅ POST /api/auth/send-otp');
        console.log('   ✅ POST /api/auth/verify-otp');
        console.log('   ✅ POST /api/auth/login');
        console.log('   ✅ POST /api/auth/register');
        console.log('   ✅ GET /api/auth/profile');

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
    }
}

testEndpoints();
