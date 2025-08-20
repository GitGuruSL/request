const database = require('./services/database');

async function checkUserVerification() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    
    // Check user verification status
    const userResult = await database.query(
      'SELECT id, email, email_verified, phone, phone_verified FROM users WHERE id = $1',
      [userId]
    );
    
    console.log('=== USER VERIFICATION STATUS ===');
    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      console.log('User ID:', user.id);
      console.log('Email:', user.email);
      console.log('Email Verified:', user.email_verified);
      console.log('Phone:', user.phone);
      console.log('Phone Verified:', user.phone_verified);
    } else {
      console.log('User not found');
    }
    
    // Check driver verification data
    const driverResult = await database.query(
      'SELECT email, phone_number FROM driver_verifications WHERE user_id = $1',
      [userId]
    );
    
    console.log('\n=== DRIVER VERIFICATION DATA ===');
    if (driverResult.rows.length > 0) {
      const driver = driverResult.rows[0];
      console.log('Driver Email:', driver.email);
      console.log('Driver Phone:', driver.phone_number);
    } else {
      console.log('Driver verification not found');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error checking user verification:', error);
    process.exit(1);
  }
}

checkUserVerification();
