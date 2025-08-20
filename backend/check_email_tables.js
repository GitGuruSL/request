const database = require('./services/database');

async function checkEmailTables() {
  try {
    console.log('🔍 Checking email verification tables...');
    
    // Check if tables exist
    const tablesResult = await database.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user_email_addresses', 'email_otp_verifications')
    `);
    
    console.log('📋 Existing email tables:', tablesResult.rows.map(r => r.table_name));
    
    // Check user_email_addresses structure if it exists
    if (tablesResult.rows.some(r => r.table_name === 'user_email_addresses')) {
      const structureResult = await database.query(`
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'user_email_addresses' 
        ORDER BY ordinal_position
      `);
      
      console.log('\n📧 user_email_addresses structure:');
      structureResult.rows.forEach(row => {
        console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    }
    
    // Check email_otp_verifications structure if it exists
    if (tablesResult.rows.some(r => r.table_name === 'email_otp_verifications')) {
      const otpStructureResult = await database.query(`
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'email_otp_verifications' 
        ORDER BY ordinal_position
      `);
      
      console.log('\n🔑 email_otp_verifications structure:');
      otpStructureResult.rows.forEach(row => {
        console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

checkEmailTables();
