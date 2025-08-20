const db = require('./services/database');

async function checkBusinessVerificationsStructure() {
  
  try {
    const result = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'business_verifications' 
      ORDER BY ordinal_position
    `);
    
    console.log('business_verifications table structure:');
    result.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
  } catch (error) {
    console.error('Error checking table structure:', error);
  }
  
  process.exit(0);
}

checkBusinessVerificationsStructure();
