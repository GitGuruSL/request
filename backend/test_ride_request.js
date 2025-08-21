const axios = require('axios');

async function testRideRequestCreation() {
  try {
    console.log('🚗 Testing ride request creation...\n');

    // Test data for a ride request (matches what Flutter will send)
    const rideRequestData = {
      title: 'Ride: Colombo -> Kandy',
      description: 'Ride request for 2 passenger(s) from Colombo to Kandy',
      city_id: '72e9d78c-8f05-483a-ae63-e5c9aacfd9bf', // Kandy city from sample data
      location_address: 'Colombo',
      location_latitude: 6.9271,
      location_longitude: 79.8612,
      country_code: 'LK',
      metadata: {
        request_type: 'ride',
        pickup: {
          address: 'Colombo',
          lat: 6.9271,
          lng: 79.8612
        },
        destination: {
          address: 'Kandy',
          lat: 7.2906,
          lng: 80.6337
        },
        vehicle_type_id: 'some-vehicle-type-id',
        passengers: 2
      }
    };

    console.log('📤 Sending ride request data:');
    console.log(JSON.stringify(rideRequestData, null, 2));
    console.log('\n' + '='.repeat(50) + '\n');

    // Make the request to test endpoint
    const response = await axios.post('http://localhost:3002/test-ride-request', rideRequestData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ SUCCESS: Ride request validation passed!');
    console.log('📥 Response:', JSON.stringify(response.data, null, 2));

  } catch (error) {
    console.log('❌ ERROR with ride request:');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Response:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('Error:', error.message);
    }
  }
}

async function testRegularRequestCreation() {
  try {
    console.log('\n📦 Testing regular request creation (should require category)...\n');

    // Test data for a regular request (should fail without category_id)
    const regularRequestData = {
      title: 'Need a smartphone',
      description: 'Looking for a good quality smartphone',
      city_id: '72e9d78c-8f05-483a-ae63-e5c9aacfd9bf',
      location_address: 'Colombo',
      country_code: 'LK',
      metadata: {
        // No request_type: 'ride' so this should require category_id
        item_type: 'smartphone'
      }
    };

    console.log('📤 Sending regular request data (without category_id):');
    console.log(JSON.stringify(regularRequestData, null, 2));
    console.log('\n' + '='.repeat(50) + '\n');

    const response = await axios.post('http://localhost:3002/test-ride-request', regularRequestData, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('🤔 Unexpected: Regular request was created without category_id');
    console.log('📥 Response:', JSON.stringify(response.data, null, 2));

  } catch (error) {
    console.log('✅ EXPECTED: Regular request failed without category_id');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Response:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('Error:', error.message);
    }
  }
}

// Run both tests
async function runTests() {
  await testRideRequestCreation();
  await testRegularRequestCreation();
  console.log('\n🏁 Test completed!');
}

runTests().catch(console.error);
