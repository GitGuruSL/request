const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs, doc, updateDoc } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function addMissingSharedRide() {
  console.log('🚗 Adding missing Shared Ride to Sri Lanka...\n');
  
  // Get Sri Lanka vehicles document
  const lkQuery = query(collection(db, 'country_vehicles'), where('countryCode', '==', 'LK'));
  const lkSnapshot = await getDocs(lkQuery);
  
  if (lkSnapshot.empty) {
    console.log('❌ No LK vehicle document found');
    return;
  }
  
  const lkDoc = lkSnapshot.docs[0];
  const currentData = lkDoc.data();
  
  console.log('Current enabled vehicles:', currentData.enabledVehicles);
  
  // Add Shared Ride ID if not already present
  const sharedRideId = 'lYnHRWWgQ55YVbxD03XC';
  const updatedVehicles = [...currentData.enabledVehicles];
  
  if (!updatedVehicles.includes(sharedRideId)) {
    updatedVehicles.push(sharedRideId);
    
    await updateDoc(doc(db, 'country_vehicles', lkDoc.id), {
      enabledVehicles: updatedVehicles,
      updatedAt: new Date(),
      updatedBy: 'shared-ride-fix'
    });
    
    console.log('✅ Added Shared Ride to Sri Lanka vehicles');
    console.log('Updated enabled vehicles:', updatedVehicles);
    console.log('Total vehicles:', updatedVehicles.length);
  } else {
    console.log('ℹ️ Shared Ride already enabled for Sri Lanka');
  }
}

addMissingSharedRide().catch(console.error);
