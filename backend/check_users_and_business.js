const database = require('./services/database');

async function checkUsers() {
  try {
    console.log('👥 Checking users in backend database...\n');
    
    const query = 'SELECT id, email, phone, display_name, is_active FROM users ORDER BY created_at DESC LIMIT 10';
    const result = await database.query(query);
    
    if (result.rows.length === 0) {
      console.log('❌ No users found in backend database!');
      console.log('\n🔍 This explains why the Flutter app can\'t authenticate with the backend.');
      console.log('💡 The Flutter app is likely still using Firebase Auth for login,');
      console.log('   but trying to call backend APIs for business verification.');
    } else {
      console.log(`✅ Found ${result.rows.length} users:`);
      result.rows.forEach((user, index) => {
        console.log(`\n${index + 1}. User ID: ${user.id}`);
        console.log(`   Email: ${user.email || 'N/A'}`);
        console.log(`   Phone: ${user.phone || 'N/A'}`);
        console.log(`   Display Name: ${user.display_name || 'N/A'}`);
        console.log(`   Active: ${user.is_active}`);
      });
    }
    
    // Also check if there are any business verifications
    console.log('\n🏢 Checking business verifications...');
    const businessQuery = 'SELECT user_id, business_name, status FROM business_verifications ORDER BY created_at DESC LIMIT 5';
    const businessResult = await database.query(businessQuery);
    
    if (businessResult.rows.length === 0) {
      console.log('❌ No business verifications found!');
    } else {
      console.log(`✅ Found ${businessResult.rows.length} business verifications:`);
      businessResult.rows.forEach((biz, index) => {
        console.log(`\n${index + 1}. User ID: ${biz.user_id}`);
        console.log(`   Business: ${biz.business_name}`);
        console.log(`   Status: ${biz.status}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Database error:', error);
  }
  
  process.exit(0);
}

checkUsers();
