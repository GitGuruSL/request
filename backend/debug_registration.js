const dbService = require('./services/database');
const jwt = require('jsonwebtoken');

async function debugRegistration() {
  try {
    console.log('🔍 Starting registration debug...');
    
    const emailOrPhone = 'cyber.sec.expert@outlook.com';
    const isEmail = true;
    
    // Check if user already exists
    console.log('🔍 Checking if user exists...');
    const existingUserResult = await dbService.query(
      'SELECT * FROM users WHERE (email = $1 OR phone = $1)',
      [emailOrPhone]
    );
    
    console.log(`🔍 Found ${existingUserResult.rows.length} existing users`);
    
    if (existingUserResult.rows.length > 0) {
      const user = existingUserResult.rows[0];
      console.log(`🔍 Existing user found: ${user.id}`);
      console.log(`🔍 User data:`, {
        id: user.id,
        email: user.email,
        phone: user.phone,
        first_name: user.first_name,
        last_name: user.last_name,
        display_name: user.display_name
      });
      
      // Test JWT token generation
      console.log('🔍 Testing JWT token generation...');
      const JWT_SECRET = process.env.JWT_SECRET;
      console.log('🔍 JWT_SECRET exists:', !!JWT_SECRET);
      
      if (JWT_SECRET) {
        const tokenPayload = {
          id: user.id,
          email: user.email,
          phone: user.phone,
          role: user.role
        };
        
        const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '7d' });
        const refreshToken = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '30d' });
        
        console.log('🔍 JWT tokens generated successfully');
        console.log('🔍 Token length:', token.length);
        console.log('🔍 Refresh token length:', refreshToken.length);
        
        // Test refresh token insertion
        console.log('🔍 Testing refresh token insertion...');
        const refreshResult = await dbService.query(
          `INSERT INTO user_refresh_tokens (user_id, token, expires_at, created_at)
           VALUES ($1, $2, NOW() + INTERVAL '30 days', NOW()) RETURNING id`,
          [user.id, refreshToken]
        );
        
        console.log('🔍 Refresh token inserted successfully:', refreshResult.rows[0]);
      }
    } else {
      console.log('🔍 No existing user found, would create new user');
    }
    
    console.log('✅ Debug completed successfully');
    
  } catch (error) {
    console.error('❌ Debug error:', error);
    console.error('❌ Error stack:', error.stack);
  } finally {
    process.exit(0);
  }
}

debugRegistration();
