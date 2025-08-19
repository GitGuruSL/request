const api = require('axios');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI4ZDNjYzg2My0xOTJiLTQ4YmQtYTA3Mi05OTQ5MDdmYjk1YTciLCJlbWFpbCI6InRlc3QtY291bnRyeS1hZG1pbkBleGFtcGxlLmNvbSIsInJvbGUiOiJjb3VudHJ5X2FkbWluIiwiaWF0IjoxNzU1NjMxODcxLCJleHAiOjE3NTU3MTgyNzF9.pAfq-wQ9Ge1NuPPLjSeyc5W6sSuuBqmiCSB0foiDBAk';

async function testVehicleTypes() {
  try {
    console.log('Testing /api/vehicle-types endpoint...');
    const response = await api.get('http://localhost:3001/api/vehicle-types', {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('✅ Response received:', response.status);
    console.log('Vehicle types:', response.data.data.length, 'items');
    response.data.data.forEach(v => {
      console.log(`  - ${v.name}: isActive=${v.isActive}, countryEnabled=${v.countryEnabled}`);
    });

    // Test toggle endpoint
    console.log('\nTesting toggle endpoint...');
    const carId = response.data.data.find(v => v.name === 'Car')?.id;
    if (carId) {
      const toggleResponse = await api.post(`http://localhost:3001/api/vehicle-types/${carId}/toggle-country`, 
        { isActive: true },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      console.log('✅ Toggle response:', toggleResponse.status, toggleResponse.data.message);
    }

  } catch (error) {
    console.error('❌ Error:', error.response?.status, error.response?.data || error.message);
  }
  process.exit(0);
}

testVehicleTypes();
