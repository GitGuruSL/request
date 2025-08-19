const database = require('./services/database');

async function checkColumnTypes() {
  try {
    console.log('Checking column types...');
    
    const citiesResult = await database.query(`
      SELECT column_name, data_type, udt_name 
      FROM information_schema.columns 
      WHERE table_name = 'cities' AND column_name = 'id';
    `);
    console.log('Cities ID type:', citiesResult.rows);

    const vehicleTypesResult = await database.query(`
      SELECT column_name, data_type, udt_name 
      FROM information_schema.columns 
      WHERE table_name = 'vehicle_types' AND column_name = 'id';
    `);
    console.log('Vehicle types ID type:', vehicleTypesResult.rows);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

checkColumnTypes();
