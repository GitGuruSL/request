const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fixCountryVehiclesStructure() {
  console.log('🔧 Fixing country vehicles structure for Flutter app...\n');
  
  // Get country_vehicles collection
  const countryVehiclesSnapshot = await getDocs(collection(db, 'country_vehicles'));
  
  for (const docRef of countryVehiclesSnapshot.docs) {
    const data = docRef.data();
    console.log(`Updating document: ${docRef.id}`);
    console.log(`Current data:`, data);
    
    // Update the structure to match Flutter expectations
    const updatedData = {
      countryCode: data.countryCode || 'LK', // Ensure countryCode exists
      enabledVehicles: data.enabledVehicles || data.activeVehicleTypes || [], // Use enabledVehicles
      country: data.countryCode || 'LK', // Keep country field for admin panel
      updatedAt: new Date(),
      updatedBy: 'flutter-compatibility-fix'
    };
    
    // Remove old field if it exists
    if (data.activeVehicleTypes) {
      console.log(`Moving activeVehicleTypes to enabledVehicles`);
    }
    
    await updateDoc(doc(db, 'country_vehicles', docRef.id), updatedData);
    console.log(`✅ Updated ${docRef.id} with correct structure\n`);
  }
  
  console.log('🎉 Country vehicles structure updated successfully!');
}

fixCountryVehiclesStructure().catch(console.error);
