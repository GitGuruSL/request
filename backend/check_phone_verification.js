const db = require('./services/database');

async function checkPhoneVerification() {
  try {
    console.log('Checking driver verification data for Mike Rose...');
    
    // Get driver verification data
    const driverResult = await db.query(
      "SELECT user_id, phone_number, full_name, email FROM driver_verifications WHERE full_name = 'Mike Rose'"
    );
    
    console.log('Driver verification data:');
    console.log(JSON.stringify(driverResult.rows, null, 2));
    
    if (driverResult.rows.length > 0) {
      const userId = driverResult.rows[0].user_id;
      
      // Get corresponding user data
      const userResult = await db.query(
        'SELECT id, phone, phone_verified FROM users WHERE id = $1',
        [userId]
      );
      
      console.log('\nCorresponding user data:');
      console.log(JSON.stringify(userResult.rows, null, 2));
      
      // Compare phone numbers
      const driverPhone = driverResult.rows[0].phone_number;
      const userPhone = userResult.rows[0]?.phone;
      const phoneVerified = userResult.rows[0]?.phone_verified;
      
      console.log('\nPhone verification analysis:');
      console.log(`Driver phone: ${driverPhone}`);
      console.log(`User phone: ${userPhone}`);
      console.log(`Phone verified: ${phoneVerified}`);
      console.log(`Phones match: ${driverPhone === userPhone}`);
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkPhoneVerification();
