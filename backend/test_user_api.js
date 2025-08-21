const axios = require('axios');

// Test the user API endpoint to check verification status
async function testUserAPI() {
  try {
    const userId = 'ee9776a6-afde-4256-9374-aab0c24e4a70';
    
    // First, let's check what the database returns directly
    const database = require('./services/database');
    const result = await database.query('SELECT * FROM users WHERE id = $1', [userId]);
    
    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('🗃️ Direct database query result:');
      console.log('email_verified:', user.email_verified, typeof user.email_verified);
      console.log('phone_verified:', user.phone_verified, typeof user.phone_verified);
      console.log('email:', user.email);
      console.log('phone:', user.phone);
      
      // Remove sensitive fields like in the API
      delete user.password_hash;
      delete user.firebase_uid;
      
      console.log('\n📋 Clean user data (as API would return):');
      console.log(JSON.stringify(user, null, 2));
    } else {
      console.log('❌ User not found in database');
    }
    
  } catch (error) {
    console.error('❌ Error testing user API:', error);
  }
}

testUserAPI();
