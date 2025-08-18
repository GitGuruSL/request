const DatabaseService = require('./services/database');

async function checkAllTables() {
  try {
    console.log('🔍 Checking all tables in database...');
    
    // Get all table names
    const tables = await DatabaseService.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);
    
    console.log('📋 All tables:');
    tables.rows.forEach(table => {
      console.log(`  - ${table.table_name}`);
    });
    
    // Check specifically for refresh token related tables
    const refreshTables = await DatabaseService.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE '%refresh%'
      ORDER BY table_name;
    `);
    
    console.log('🔄 Refresh token related tables:');
    refreshTables.rows.forEach(table => {
      console.log(`  - ${table.table_name}`);
    });
    
  } catch (error) {
    console.error('❌ Error checking tables:', error.message);
    console.error('❌ Error details:', error);
  } finally {
    process.exit();
  }
}

checkAllTables();
