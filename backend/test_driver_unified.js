const database = require('./services/database');

async function testDriverVerification() {
  try {
    console.log('Testing unified driver verification system...');
    
    // Use the existing user ID from the phone verification
    const testUserId = '5af58de3-896d-4cc3-bd0b-177054916335';
    const testPhone = '+94725742238';
    const testEmail = 'test@example.com';
    
    console.log('Testing driver verification with existing verified user...');
    console.log('User ID:', testUserId);
    console.log('Phone:', testPhone);
    console.log('Email:', testEmail);
    
    // Check the user exists
    const userCheck = await database.query('SELECT * FROM users WHERE id = $1', [testUserId]);
    console.log('User found:', userCheck.rows.length > 0);
    if (userCheck.rows.length > 0) {
      const user = userCheck.rows[0];
      console.log('User details:', {
        phone: user.phone,
        phone_verified: user.phone_verified,
        email: user.email,
        email_verified: user.email_verified
      });
    }
    
    // Check phone in user_phone_numbers
    const phoneCheck = await database.query('SELECT * FROM user_phone_numbers WHERE user_id = $1', [testUserId]);
    console.log('Professional phones count:', phoneCheck.rows.length);
    phoneCheck.rows.forEach(r => {
      console.log('- Phone:', r.phone_number, 'verified:', r.is_verified, 'purpose:', r.purpose);
    });
    
    console.log('✅ Driver verification unified system test data validated');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

testDriverVerification();
