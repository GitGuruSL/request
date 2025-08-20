const dbService = require('./services/database');

async function checkVehicleTypes() {
  try {
    console.log('=== Available vehicle types ===');
    const vehicleTypes = await dbService.query('SELECT id, name, description, is_active FROM vehicle_types ORDER BY name');
    console.log(vehicleTypes.rows);
    
    console.log('\n=== Driver 7 vehicle data ===');
    const query = `
      SELECT 
        dv.id,
        dv.vehicle_type_id,
        dv.vehicle_model,
        dv.vehicle_year,
        dv.vehicle_color,
        vt.name as vehicle_type_display_name
      FROM driver_verifications dv
      LEFT JOIN vehicle_types vt ON dv.vehicle_type_id = vt.id
      WHERE dv.id = 7
    `;
    const driver = await dbService.query(query);
    console.log('Driver data:', driver.rows[0]);
    
    if (driver.rows[0]?.vehicle_type_id) {
      console.log('\n=== Looking up vehicle type details ===');
      const typeDetails = await dbService.query('SELECT * FROM vehicle_types WHERE id = $1', [driver.rows[0].vehicle_type_id]);
      console.log('Vehicle type details:', typeDetails.rows[0]);
    } else {
      console.log('\n=== Vehicle type is NULL or empty ===');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

checkVehicleTypes();
