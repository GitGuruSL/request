const database = require('./services/database');

async function checkUserStatus() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    
    console.log('🔍 Checking user status...');
    const userResult = await database.query('SELECT id, email, role FROM users WHERE id = $1', [userId]);
    console.log('👤 User data:', userResult.rows[0]);
    
    console.log('\n🔍 Checking business verification...');
    const businessResult = await database.query('SELECT * FROM business_verifications WHERE user_id = $1', [userId]);
    if (businessResult.rows.length > 0) {
      console.log('🏢 Business verification exists:');
      console.log('- Status:', businessResult.rows[0].status);
      console.log('- Is Verified:', businessResult.rows[0].is_verified);
      console.log('- Phone Verified:', businessResult.rows[0].phone_verified);
      console.log('- Email Verified:', businessResult.rows[0].email_verified);
      console.log('- Business Name:', businessResult.rows[0].business_name);
      console.log('- Created:', businessResult.rows[0].created_at);
    } else {
      console.log('❌ No business verification found');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkUserStatus();
