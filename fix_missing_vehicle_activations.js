const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc, query, where } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fixMissingVehicleActivations() {
  console.log('🔧 Fixing Missing Vehicle Activations...\n');
  
  // 1. Get all active vehicle types
  const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
  const allActiveVehicles = vehicleTypesSnapshot.docs
    .filter(doc => doc.data().isActive === true)
    .map(doc => doc.id);
  
  console.log('📊 All Active Vehicle Types:');
  vehicleTypesSnapshot.docs.forEach(doc => {
    const data = doc.data();
    if (data.isActive) {
      console.log(`  ✅ ${doc.id}: ${data.name} (Order: ${data.displayOrder})`);
    }
  });
  
  // 2. Get LK country vehicles document
  const lkQuery = query(collection(db, 'country_vehicles'), where('countryCode', '==', 'LK'));
  const lkSnapshot = await getDocs(lkQuery);
  
  if (lkSnapshot.empty) {
    console.log('❌ No LK country vehicles document found');
    return;
  }
  
  const lkDoc = lkSnapshot.docs[0];
  const lkData = lkDoc.data();
  const currentEnabled = lkData.enabledVehicles || [];
  
  console.log(`\n🇱🇰 Current LK Enabled Vehicles: ${currentEnabled.length}`);
  console.log(`📋 All Active Vehicles: ${allActiveVehicles.length}`);
  
  // 3. Find missing vehicles
  const missingVehicles = allActiveVehicles.filter(id => !currentEnabled.includes(id));
  
  if (missingVehicles.length === 0) {
    console.log('✅ All active vehicles are already enabled for LK');
    return;
  }
  
  console.log(`\n❌ Missing Vehicles (${missingVehicles.length}):`);
  missingVehicles.forEach(id => {
    const vehicleData = vehicleTypesSnapshot.docs.find(doc => doc.id === id)?.data();
    console.log(`  - ${id}: ${vehicleData?.name || 'Unknown'}`);
  });
  
  // 4. Update LK document with all active vehicles
  const updatedEnabledVehicles = [...new Set([...currentEnabled, ...missingVehicles])];
  
  console.log(`\n🔄 Updating LK enabled vehicles...`);
  console.log(`  Before: ${currentEnabled.length} vehicles`);
  console.log(`  After: ${updatedEnabledVehicles.length} vehicles`);
  
  await updateDoc(doc(db, 'country_vehicles', lkDoc.id), {
    enabledVehicles: updatedEnabledVehicles,
    updatedAt: new Date(),
    updatedBy: 'auto-vehicle-sync',
    syncedAt: new Date(),
    totalActiveVehicles: updatedEnabledVehicles.length
  });
  
  console.log('✅ LK vehicle activations updated successfully!');
  
  // 5. Verify the update
  const verifySnapshot = await getDocs(lkQuery);
  const verifyData = verifySnapshot.docs[0].data();
  console.log(`\n✅ Verification: LK now has ${verifyData.enabledVehicles.length} enabled vehicles`);
  
  return {
    addedVehicles: missingVehicles.length,
    totalEnabled: updatedEnabledVehicles.length
  };
}

fixMissingVehicleActivations().catch(console.error);
