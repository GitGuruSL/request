const DatabaseService = require('./services/database');

async function testWithCorrectUserId() {
  try {
    console.log('🔍 Testing refresh token insert with correct user ID...');
    
    // Use the correct current user ID
    const correctUserId = '02b8426f-5ef6-4755-a5a6-c017c713966e';
    const testToken = 'test_refresh_token_correct_user';
    
    console.log('📝 Query to execute:');
    console.log(`INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, created_at)`);
    console.log(`VALUES ($1, $2, NOW() + INTERVAL '30 days', NOW())`);
    console.log(`Parameters: [${correctUserId}, ${testToken}]`);
    
    // Try the insert
    const result = await DatabaseService.query(
      `INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, created_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days', NOW())`,
      [correctUserId, testToken]
    );
    
    console.log('✅ Insert successful!');
    console.log('📊 Result:', result);
    
    // Clean up the test record
    await DatabaseService.query(
      `DELETE FROM user_refresh_tokens WHERE user_id = $1 AND token_hash = $2`,
      [correctUserId, testToken]
    );
    
    console.log('🧹 Test record cleaned up');
    
  } catch (error) {
    console.error('❌ Error testing insert:', error.message);
    console.error('❌ SQL Error Code:', error.code);
    console.error('❌ Error details:', error);
  } finally {
    process.exit();
  }
}

testWithCorrectUserId();
