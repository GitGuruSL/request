// Test database connection and check OTP tokens table
const { Pool } = require('pg');

const pool = new Pool({
  host: 'requestdb.cq70gkkamvcs.us-east-1.rds.amazonaws.com',
  port: 5432,
  database: 'request',
  user: 'requestadmindb',
  password: 'RequestMarketplace2024!',
  ssl: {
    rejectUnauthorized: false
  }
});

async function testConnection() {
  try {
    console.log('🔄 Testing database connection...');
    
    // Test basic connection
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Database connection successful!');
    console.log(`🕐 Current time: ${result.rows[0].now}`);
    
    // Check if OTP tokens table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'otp_tokens'
      );
    `);
    
    if (tableCheck.rows[0].exists) {
      console.log('✅ OTP tokens table exists!');
      
      // Get table structure
      const structure = await pool.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_name = 'otp_tokens'
        ORDER BY ordinal_position
      `);
      
      console.log('\n📋 OTP Tokens Table Structure:');
      structure.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
      });
    } else {
      console.log('❌ OTP tokens table does not exist. Running migration...');
      
      // Run the migration
      const migrationSQL = `
        CREATE TABLE IF NOT EXISTS otp_tokens (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email_or_phone VARCHAR(255) NOT NULL,
            otp_code VARCHAR(6) NOT NULL,
            token_hash VARCHAR(64) NOT NULL,
            purpose VARCHAR(50) DEFAULT 'registration',
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            used BOOLEAN DEFAULT FALSE,
            attempts INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_otp_tokens_email_token ON otp_tokens(email_or_phone, token_hash);
        CREATE INDEX IF NOT EXISTS idx_otp_tokens_expires ON otp_tokens(expires_at) WHERE used = FALSE;
      `;
      
      await pool.query(migrationSQL);
      console.log('✅ OTP tokens table created successfully!');
    }
    
    // Test existing tables
    const tablesResult = await pool.query(`
      SELECT table_name, 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    
    console.log('\n📊 All Database Tables:');
    tablesResult.rows.forEach(row => {
      console.log(`  - ${row.table_name} (${row.column_count} columns)`);
    });
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  } finally {
    await pool.end();
  }
}

testConnection();
