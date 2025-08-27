const db = require('./services/database');

(async () => {
  try {
    console.log('🔍 Checking sms_provider_configs table...');
    
    // Check existing configs for LK
    const result = await db.query('SELECT * FROM sms_provider_configs WHERE country_code = $1', ['LK']);
    console.log('📊 sms_provider_configs for LK:', result.rows.length, 'records');
    result.rows.forEach(row => {
      console.log(`   Provider: ${row.provider}, Active: ${row.is_active}, Config: ${JSON.stringify(row.config).substring(0, 100)}...`);
    });
    
    // Check table structure
    console.log('\n📋 Checking table structure...');
    const structure = await db.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'sms_provider_configs' 
      ORDER BY ordinal_position
    `);
    console.log('📝 sms_provider_configs columns:');
    structure.rows.forEach(col => {
      console.log(`   ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });

    // Check if hutch_mobile provider exists
    const hutchConfig = await db.query('SELECT * FROM sms_provider_configs WHERE country_code = $1 AND provider = $2', ['LK', 'hutch_mobile']);
    console.log('\n🏢 Hutch Mobile config exists:', hutchConfig.rows.length > 0);
    
    if (hutchConfig.rows.length > 0) {
      console.log('📱 Existing Hutch Mobile config:', hutchConfig.rows[0]);
    }
    
  } catch(e) {
    console.error('❌ Error:', e.message);
  } finally {
    process.exit(0);
  }
})();
