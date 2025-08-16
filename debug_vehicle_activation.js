const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, query, where } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function debugVehicleActivation() {
  console.log('🔍 Debugging Vehicle Activation for Ride Requests...\n');
  
  // 1. Check all global vehicle types
  console.log('📊 Global Vehicle Types (vehicle_types collection):');
  const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
  const allVehicles = {};
  vehicleTypesSnapshot.docs.forEach((doc, index) => {
    const data = doc.data();
    allVehicles[doc.id] = data;
    console.log(`${index + 1}. ${data.name} - Active: ${data.isActive}, Order: ${data.displayOrder} (ID: ${doc.id})`);
  });
  
  // 2. Check LK country vehicle activations
  console.log('\n🇱🇰 LK Country Vehicle Activations (country_vehicles collection):');
  const lkQuery = query(collection(db, 'country_vehicles'), where('countryCode', '==', 'LK'));
  const lkSnapshot = await getDocs(lkQuery);
  
  if (lkSnapshot.empty) {
    console.log('❌ No country vehicle activations found for LK');
  } else {
    lkSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log('LK Activation Record:', {
        id: doc.id,
        countryCode: data.countryCode,
        enabledVehicles: data.enabledVehicles,
        count: data.enabledVehicles?.length || 0
      });
      
      // Check if enabled vehicles exist in global vehicle types
      console.log('\n🔗 Matching Global Vehicles:');
      if (data.enabledVehicles) {
        data.enabledVehicles.forEach(vehicleId => {
          const globalVehicle = allVehicles[vehicleId];
          if (globalVehicle) {
            console.log(`  ✅ ${vehicleId}: ${globalVehicle.name} (Active: ${globalVehicle.isActive})`);
          } else {
            console.log(`  ❌ ${vehicleId}: NOT FOUND in global vehicle_types`);
          }
        });
      }
    });
  }
  
  // 3. Check the problematic case: missing Shared Ride
  console.log('\n🔍 Missing Vehicle Analysis:');
  const enabledIds = lkSnapshot.docs[0]?.data()?.enabledVehicles || [];
  const allVehicleIds = Object.keys(allVehicles);
  
  console.log('Enabled Vehicle IDs:', enabledIds);
  console.log('All Vehicle IDs:', allVehicleIds);
  
  const missingFromEnabled = allVehicleIds.filter(id => !enabledIds.includes(id));
  if (missingFromEnabled.length > 0) {
    console.log('\n❌ Vehicles NOT enabled for LK:');
    missingFromEnabled.forEach(id => {
      console.log(`  - ${id}: ${allVehicles[id].name} (Active: ${allVehicles[id].isActive})`);
    });
  }
  
  // 4. Summary & Solution
  console.log('\n📋 Summary:');
  console.log(`  - Total Global Vehicles: ${vehicleTypesSnapshot.docs.length}`);
  console.log(`  - LK Enabled Vehicles: ${enabledIds.length}`);
  console.log(`  - Missing Vehicles: ${missingFromEnabled.length}`);
  
  if (missingFromEnabled.length > 0) {
    console.log('\n🔧 Solution: Need to add missing vehicles to LK enabledVehicles array');
  }
}

debugVehicleActivation().catch(console.error);
