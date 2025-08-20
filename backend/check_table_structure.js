const database = require('./services/database');

async function checkTableStructure() {
  try {
    console.log('🔍 Checking sms_configurations table structure...');
    
    const result = await database.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'sms_configurations'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 sms_configurations table columns:');
    result.rows.forEach(row => {
      console.log(`  ${row.column_name}: ${row.data_type} ${row.is_nullable === 'NO' ? 'NOT NULL' : ''} ${row.column_default ? `DEFAULT ${row.column_default}` : ''}`);
    });
    
    console.log('\n🔍 Checking admin_users table ID type...');
    const adminResult = await database.query(`
      SELECT column_name, data_type
      FROM information_schema.columns 
      WHERE table_name = 'admin_users' AND column_name = 'id'
    `);
    
    if (adminResult.rows.length > 0) {
      console.log(`admin_users.id: ${adminResult.rows[0].data_type}`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkTableStructure();
