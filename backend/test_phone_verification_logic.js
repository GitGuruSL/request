const database = require('./services/database');

// Helper function to check and update phone verification status
async function checkPhoneVerificationStatus(userId, phoneNumber) {
  try {
    // Check if user exists and get current phone status
    const userResult = await database.query(
      'SELECT phone, phone_verified FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return { phoneVerified: false, needsUpdate: false };
    }
    
    const user = userResult.rows[0];
    
    // If user phone is null but driver has phone number, update users table
    if (!user.phone && phoneNumber) {
      await database.query(
        'UPDATE users SET phone = $1, updated_at = NOW() WHERE id = $2',
        [phoneNumber, userId]
      );
      console.log(`📱 Updated user ${userId} phone to ${phoneNumber}`);
      return { phoneVerified: false, needsUpdate: true };
    }
    
    // If phone numbers match and user is verified, phone is verified
    if (user.phone === phoneNumber && user.phone_verified) {
      return { phoneVerified: true, needsUpdate: false };
    }
    
    // If phone numbers match but not verified, check OTP verification table
    if (user.phone === phoneNumber) {
      const otpResult = await database.query(
        'SELECT verified FROM phone_otp_verifications WHERE phone = $1 AND verified = true ORDER BY verified_at DESC LIMIT 1',
        [phoneNumber]
      );
      
      if (otpResult.rows.length > 0) {
        // Update user verification status
        await database.query(
          'UPDATE users SET phone_verified = true, updated_at = NOW() WHERE id = $1',
          [userId]
        );
        console.log(`✅ Auto-verified phone for user ${userId}`);
        return { phoneVerified: true, needsUpdate: true };
      }
    }
    
    return { phoneVerified: user.phone_verified || false, needsUpdate: false };
  } catch (error) {
    console.error('Error checking phone verification:', error);
    return { phoneVerified: false, needsUpdate: false };
  }
}

// Test the function
async function testPhoneVerification() {
  console.log('Testing phone verification logic...');
  
  const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
  const phoneNumber = '725743365';
  
  console.log(`\nBefore verification check:`);
  const userBefore = await database.query('SELECT phone, phone_verified FROM users WHERE id = $1', [userId]);
  console.log(JSON.stringify(userBefore.rows[0], null, 2));
  
  const result = await checkPhoneVerificationStatus(userId, phoneNumber);
  console.log(`\nPhone verification result:`, result);
  
  console.log(`\nAfter verification check:`);
  const userAfter = await database.query('SELECT phone, phone_verified FROM users WHERE id = $1', [userId]);
  console.log(JSON.stringify(userAfter.rows[0], null, 2));
}

testPhoneVerification().catch(console.error);
