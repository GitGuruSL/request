const db = require('./services/database');

async function checkTable() {
  try {
    console.log('Checking country_vehicle_types table structure...');
    const result = await db.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'country_vehicle_types' 
      ORDER BY ordinal_position
    `);
    console.log('Columns:');
    console.table(result.rows);
    
    console.log('Checking constraints...');
    const constraints = await db.query(`
      SELECT constraint_name, constraint_type 
      FROM information_schema.table_constraints 
      WHERE table_name = 'country_vehicle_types'
    `);
    console.log('Constraints:');
    console.table(constraints.rows);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  process.exit(0);
}

checkTable();
