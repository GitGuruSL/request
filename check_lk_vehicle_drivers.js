const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function checkRegisteredVehiclesForLK() {
  console.log('🚗 Checking registered vehicles in Sri Lanka with two-level filtering...\n');
  
  try {
    // Step 1: Get country-enabled vehicle types for LK
    console.log('📋 Step 1: Getting country-enabled vehicle types for LK');
    const countryVehiclesQuery = query(
      collection(db, 'country_vehicles'), 
      where('countryCode', '==', 'LK')
    );
    const countrySnapshot = await getDocs(countryVehiclesQuery);
    
    if (countrySnapshot.empty) {
      console.log('❌ No country vehicle config found for LK');
      return;
    }
    
    const enabledVehicleIds = countrySnapshot.docs[0].data().enabledVehicles || [];
    console.log(`✅ LK has ${enabledVehicleIds.length} enabled vehicle types`);
    
    // Step 2: Get all approved drivers in LK
    console.log('\n👥 Step 2: Getting approved drivers in LK');
    const driversQuery = query(
      collection(db, 'new_driver_verifications'),
      where('country', '==', 'LK'),
      where('status', '==', 'approved'),
      where('availability', '==', true),
      where('isActive', '==', true)
    );
    const driversSnapshot = await getDocs(driversQuery);
    
    console.log(`✅ Found ${driversSnapshot.docs.length} approved drivers in LK`);
    
    // Step 3: Count vehicles by type
    console.log('\n🔢 Step 3: Counting registered vehicles by type');
    const vehicleTypeCounts = {};
    const registeredVehicleTypes = new Set();
    
    driversSnapshot.docs.forEach(doc => {
      const driverData = doc.data();
      const vehicleType = driverData.vehicleType;
      
      if (vehicleType) {
        vehicleTypeCounts[vehicleType] = (vehicleTypeCounts[vehicleType] || 0) + 1;
        registeredVehicleTypes.add(vehicleType);
      }
    });
    
    console.log('Vehicle registration counts:');
    for (const [vehicleTypeId, count] of Object.entries(vehicleTypeCounts)) {
      console.log(`  ${vehicleTypeId}: ${count} drivers`);
    }
    
    // Step 4: Get vehicle type names
    console.log('\n📝 Step 4: Getting vehicle type details');
    const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
    const vehicleTypeNames = {};
    
    vehicleTypesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      vehicleTypeNames[doc.id] = {
        name: data.name,
        displayOrder: data.displayOrder || 1,
        passengerCapacity: data.passengerCapacity || 1
      };
    });
    
    // Step 5: Apply two-level filtering
    console.log('\n🎯 Step 5: Applying two-level filtering');
    console.log('Filter 1 (Country Enabled): Check which vehicles are enabled for LK ✅');
    console.log('Filter 2 (Has Registered Drivers): Check which have approved drivers ✅');
    
    const availableVehicleTypes = enabledVehicleIds
      .filter(vehicleId => registeredVehicleTypes.has(vehicleId))  // Second filter: has drivers
      .map(vehicleId => ({
        id: vehicleId,
        ...vehicleTypeNames[vehicleId],
        driverCount: vehicleTypeCounts[vehicleId] || 0
      }))
      .sort((a, b) => a.displayOrder - b.displayOrder);
    
    console.log('\n📱 FINAL RESULT - Vehicle types to show in mobile app:');
    if (availableVehicleTypes.length === 0) {
      console.log('❌ No vehicle types available (no registered drivers)');
    } else {
      availableVehicleTypes.forEach((vehicle, index) => {
        console.log(`  ${index + 1}. ${vehicle.name} (${vehicle.driverCount} drivers available)`);
      });
    }
    
    // Step 6: Show filtered out vehicles
    console.log('\n⚠️ Vehicle types enabled but without drivers:');
    const enabledButNoDrivers = enabledVehicleIds
      .filter(vehicleId => !registeredVehicleTypes.has(vehicleId))
      .map(vehicleId => vehicleTypeNames[vehicleId]?.name || vehicleId);
    
    if (enabledButNoDrivers.length > 0) {
      enabledButNoDrivers.forEach(name => {
        console.log(`  - ${name} (0 drivers)`);
      });
      console.log('\n💡 These vehicle types won\'t appear in mobile app until drivers register');
    } else {
      console.log('  None - all enabled vehicle types have drivers! ✅');
    }
    
    console.log('\n🔧 Summary:');
    console.log(`  • ${enabledVehicleIds.length} vehicle types enabled for LK`);
    console.log(`  • ${registeredVehicleTypes.size} vehicle types have registered drivers`);
    console.log(`  • ${availableVehicleTypes.length} vehicle types will show in mobile app`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkRegisteredVehiclesForLK().catch(console.error);
