const axios = require('axios');

async function testVehicleTypeAPI() {
  try {
    // First get a token
    const loginResponse = await axios.post('http://localhost:3001/api/auth/login', {
      email: 'superadmin@request.lk',
      password: 'admin123'
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Got token');
    
    // Then test the driver endpoint - using ID 7 from the data you showed
    const driverResponse = await axios.get('http://localhost:3001/api/driver-verifications/7', {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const driver = driverResponse.data.data;
    console.log('\n=== Vehicle Type Fields in API Response ===');
    console.log('vehicle_type_id:', driver.vehicle_type_id);
    console.log('vehicle_type_name:', driver.vehicle_type_name);
    console.log('vehicle_type_display_name:', driver.vehicle_type_display_name);
    console.log('vehicleType:', driver.vehicleType);
    console.log('vehicleTypeName:', driver.vehicleTypeName);
    
    console.log('\n=== Make/Model/Year ===');
    console.log('vehicle_make:', driver.vehicle_make);
    console.log('vehicle_model:', driver.vehicle_model);
    console.log('vehicle_year:', driver.vehicle_year);
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testVehicleTypeAPI();
