const db = require('./services/database');

async function createCountryVehicleTypes() {
  try {
    console.log('Creating country_vehicle_types records for LK...');
    
    // Get first vehicle type
    const vehicles = await db.query('SELECT id, name FROM vehicle_types LIMIT 3');
    console.log('Available vehicles:', vehicles.rows);
    
    // Enable first 2 vehicle types for LK
    for (let i = 0; i < 2 && i < vehicles.rows.length; i++) {
      const vehicle = vehicles.rows[i];
      console.log('Enabling vehicle:', vehicle.name, 'for LK');
      await db.query(`
        INSERT INTO country_vehicle_types (vehicle_type_id, country_code, is_active)
        VALUES ($1, $2, $3)
        ON CONFLICT (vehicle_type_id, country_code)
        DO UPDATE SET is_active = EXCLUDED.is_active
      `, [vehicle.id, 'LK', true]);
    }
    
    console.log('✅ Country vehicle types created successfully');
    
    // Verify what we created
    const result = await db.query(`
      SELECT vt.name, cvt.country_code, cvt.is_active 
      FROM country_vehicle_types cvt 
      JOIN vehicle_types vt ON cvt.vehicle_type_id = vt.id 
      WHERE cvt.country_code = 'LK'
    `);
    console.log('Current LK vehicle types:');
    console.table(result.rows);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  process.exit(0);
}

createCountryVehicleTypes();
