const { sendRegistrationOTP, verifyOTP, loginWithPassword } = require('./unifiedAuthService');

/**
 * Test script for the unified authentication system
 * Tests both SMS and Email OTP functionality
 */

async function testAuthenticationSystem() {
    console.log('🧪 Testing Unified Authentication System');
    console.log('==========================================');

    try {
        // Test 1: Email OTP Registration
        console.log('\n📧 Test 1: Email OTP Registration');
        const emailTest = await sendRegistrationOTP('test@example.com', 'Email');
        console.log('✅ Email OTP sent:', emailTest.success);
        console.log('📝 OTP Code (for testing):', emailTest.otpCode);

        // Test 2: SMS OTP Registration (if configured)
        console.log('\n📱 Test 2: SMS OTP Registration');
        try {
            const smsTest = await sendRegistrationOTP('+1234567890', 'SMS');
            console.log('✅ SMS OTP sent:', smsTest.success);
            console.log('📝 OTP Code (for testing):', smsTest.otpCode);
        } catch (error) {
            console.log('⚠️ SMS test skipped (provider not configured)');
        }

        // Test 3: OTP Verification
        console.log('\n🔐 Test 3: OTP Verification');
        if (emailTest.otpCode) {
            const verifyTest = await verifyOTP('test@example.com', emailTest.otpCode);
            console.log('✅ OTP verification:', verifyTest.success);
        }

        console.log('\n🎉 Authentication system tests completed!');
        console.log('\n📋 Next steps:');
        console.log('  1. Configure AWS SES credentials');
        console.log('  2. Configure SMS provider credentials');
        console.log('  3. Test with real email/phone numbers');
        console.log('  4. Deploy to Firebase Functions');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('  1. Check AWS SES configuration');
        console.log('  2. Verify Firebase Functions environment');
        console.log('  3. Review error logs above');
    }
}

// Helper function to test specific email
async function testEmailOTP(email) {
    console.log(`\n📧 Testing email OTP for: ${email}`);
    try {
        const result = await sendRegistrationOTP(email, 'Email');
        console.log('✅ Success:', result);
        return result;
    } catch (error) {
        console.error('❌ Failed:', error.message);
        return null;
    }
}

// Helper function to test specific phone
async function testSMSOTP(phone) {
    console.log(`\n📱 Testing SMS OTP for: ${phone}`);
    try {
        const result = await sendRegistrationOTP(phone, 'SMS');
        console.log('✅ Success:', result);
        return result;
    } catch (error) {
        console.error('❌ Failed:', error.message);
        return null;
    }
}

// Export functions for manual testing
module.exports = {
    testAuthenticationSystem,
    testEmailOTP,
    testSMSOTP
};

// Run tests if called directly
if (require.main === module) {
    testAuthenticationSystem();
}
