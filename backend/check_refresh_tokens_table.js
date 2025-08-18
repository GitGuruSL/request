const DatabaseService = require('./services/database');

async function checkRefreshTokensTable() {
  try {
    console.log('🔍 Checking user_refresh_tokens table structure...');
    
    // Check if table exists and get its structure
    const tableInfo = await DatabaseService.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'user_refresh_tokens'
      ORDER BY ordinal_position;
    `);
    
    console.log('📋 Table columns:');
    tableInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Also check if table exists at all
    const tableExists = await DatabaseService.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'user_refresh_tokens'
      );
    `);
    
    console.log(`🏗️ Table exists: ${tableExists.rows[0].exists}`);
    
  } catch (error) {
    console.error('❌ Error checking table:', error.message);
    console.error('❌ Error details:', error);
  } finally {
    process.exit();
  }
}

checkRefreshTokensTable();
