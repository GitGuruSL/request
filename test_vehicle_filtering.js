const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testVehicleFiltering() {
  console.log('🧪 Testing vehicle filtering logic step by step...\n');
  
  const countryCode = 'LK';
  console.log(`Testing for country code: ${countryCode}`);
  
  try {
    // Test 1: Country vehicles configuration
    console.log('\n📋 Test 1: Getting country vehicle configuration');
    const countryVehiclesQuery = query(
      collection(db, 'country_vehicles'),
      where('countryCode', '==', countryCode)
    );
    const countrySnapshot = await getDocs(countryVehiclesQuery);
    
    if (countrySnapshot.empty) {
      console.log('❌ FAIL: No country vehicle config found');
      return;
    }
    
    const countryData = countrySnapshot.docs[0].data();
    const enabledVehicleIds = countryData.enabledVehicles || [];
    console.log(`✅ PASS: Found config with ${enabledVehicleIds.length} enabled vehicles`);
    console.log(`   Enabled vehicle IDs: ${enabledVehicleIds.join(', ')}`);
    
    // Test 2: Driver verification data
    console.log('\n👥 Test 2: Getting driver verification data');
    const driversQuery = query(
      collection(db, 'new_driver_verifications'),
      where('country', '==', countryCode),
      where('status', '==', 'approved'),
      where('availability', '==', true),
      where('isActive', '==', true)
    );
    const driversSnapshot = await getDocs(driversQuery);
    
    console.log(`✅ PASS: Found ${driversSnapshot.docs.length} approved/active drivers`);
    
    if (driversSnapshot.docs.length > 0) {
      const driverCounts = {};
      driversSnapshot.docs.forEach(doc => {
        const vehicleType = doc.data().vehicleType;
        driverCounts[vehicleType] = (driverCounts[vehicleType] || 0) + 1;
      });
      console.log('   Driver counts by vehicle type:');
      Object.entries(driverCounts).forEach(([vehicleId, count]) => {
        console.log(`     ${vehicleId}: ${count} drivers`);
      });
    }
    
    // Test 3: Vehicle types collection
    console.log('\n🚗 Test 3: Getting vehicle type names');
    const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
    const vehicleNames = {};
    vehicleTypesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      vehicleNames[doc.id] = data.name;
    });
    
    console.log(`✅ PASS: Found ${vehicleTypesSnapshot.docs.length} vehicle types`);
    enabledVehicleIds.forEach(id => {
      console.log(`   ${id}: ${vehicleNames[id] || 'Unknown'}`);
    });
    
    // Test 4: Two-level filtering result
    console.log('\n🎯 Test 4: Two-level filtering result');
    const driverCounts = {};
    driversSnapshot.docs.forEach(doc => {
      const vehicleType = doc.data().vehicleType;
      driverCounts[vehicleType] = (driverCounts[vehicleType] || 0) + 1;
    });
    
    const availableVehicles = enabledVehicleIds.filter(id => driverCounts[id] > 0);
    
    console.log(`✅ RESULT: ${availableVehicles.length} vehicle types will show in Flutter app`);
    if (availableVehicles.length > 0) {
      availableVehicles.forEach(id => {
        console.log(`   ${vehicleNames[id]}: ${driverCounts[id]} drivers available`);
      });
    } else {
      console.log('   No vehicles available (no registered drivers)');
    }
    
    console.log('\n🔧 Summary:');
    console.log(`✅ Country config: Found`);
    console.log(`✅ Enabled vehicles: ${enabledVehicleIds.length}`);
    console.log(`✅ Active drivers: ${driversSnapshot.docs.length}`);
    console.log(`✅ Available vehicles: ${availableVehicles.length}`);
    
    if (availableVehicles.length === 0 && enabledVehicleIds.length > 0) {
      console.log('\n⚠️ Issue: Vehicles are enabled but no drivers are registered');
      console.log('   This could be why Flutter app shows empty vehicle list');
    }
    
  } catch (error) {
    console.error('❌ Test failed with error:', error);
  }
}

testVehicleFiltering().catch(console.error);
