const db = require('./services/database');

async function checkPhoneNumberSystem() {
  try {
    // Check user_phone_numbers table structure
    console.log('=== user_phone_numbers table structure ===');
    const structureResult = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'user_phone_numbers' 
      ORDER BY ordinal_position
    `);
    
    structureResult.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
    // Check existing phone numbers
    console.log('\n=== user_phone_numbers data ===');
    const dataResult = await db.query('SELECT * FROM user_phone_numbers ORDER BY created_at DESC LIMIT 5');
    console.log('Found', dataResult.rows.length, 'phone number records');
    dataResult.rows.forEach((row, index) => {
      console.log(`Record ${index + 1}:`, JSON.stringify(row, null, 2));
    });
    
    // Check phone verifications table too
    console.log('\n=== phone_verifications table ===');
    const phoneVerResult = await db.query('SELECT * FROM phone_verifications ORDER BY created_at DESC LIMIT 3');
    console.log('Found', phoneVerResult.rows.length, 'phone verification records');
    phoneVerResult.rows.forEach((row, index) => {
      console.log(`Phone Ver ${index + 1}:`, JSON.stringify(row, null, 2));
    });
    
  } catch (error) {
    console.error('Error:', error);
  }
  process.exit(0);
}

checkPhoneNumberSystem();
