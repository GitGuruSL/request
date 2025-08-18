const DatabaseService = require('./services/database');

async function testRefreshTokenInsert() {
  try {
    console.log('🔍 Testing refresh token insert...');
    
    // Test the exact query structure
    const testUserId = 'ea630046-4959-4d56-a5a5-b2ebbcea4a32';
    const testToken = 'test_refresh_token_12345';
    
    console.log('📝 Query to execute:');
    console.log(`INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, created_at)`);
    console.log(`VALUES ($1, $2, NOW() + INTERVAL '30 days', NOW())`);
    console.log(`Parameters: [${testUserId}, ${testToken}]`);
    
    // Try the insert
    const result = await DatabaseService.query(
      `INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, created_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days', NOW())`,
      [testUserId, testToken]
    );
    
    console.log('✅ Insert successful!');
    console.log('📊 Result:', result);
    
    // Clean up the test record
    await DatabaseService.query(
      `DELETE FROM user_refresh_tokens WHERE user_id = $1 AND token_hash = $2`,
      [testUserId, testToken]
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

testRefreshTokenInsert();
