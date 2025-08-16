const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function analyzeVehicleRegistrations() {
  console.log('🔍 Analyzing vehicle registrations in Sri Lanka...\n');
  
  // Check driver verification collection
  try {
    console.log('📋 Checking driver_verification collection...');
    
    const driverQuery = query(
      collection(db, 'driver_verification'),
      where('country', '==', 'Sri Lanka')
    );
    const driverSnapshot = await getDocs(driverQuery);
    
    if (driverSnapshot.empty) {
      // Try with different country formats
      const formats = ['LK', 'sri lanka', 'Sri Lanka (LK)'];
      for (const format of formats) {
        const altQuery = query(collection(db, 'driver_verification'), where('country', '==', format));
        const altSnapshot = await getDocs(altQuery);
        if (!altSnapshot.empty) {
          console.log(`  ✅ Found ${altSnapshot.docs.length} drivers with country: "${format}"`);
          analyzeDocs(altSnapshot.docs);
          return;
        }
      }
      
      // Try with countryCode field
      const codeQuery = query(collection(db, 'driver_verification'), where('countryCode', '==', 'LK'));
      const codeSnapshot = await getDocs(codeQuery);
      if (!codeSnapshot.empty) {
        console.log(`  ✅ Found ${codeSnapshot.docs.length} drivers with countryCode: "LK"`);
        analyzeDocs(codeSnapshot.docs);
        return;
      }
      
      console.log('❌ No driver registrations found for Sri Lanka');
    } else {
      console.log(`  ✅ Found ${driverSnapshot.docs.length} drivers in Sri Lanka`);
      analyzeDocs(driverSnapshot.docs);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

function analyzeDocs(docs) {
  console.log('🚗 Analyzing registered vehicle types...\n');
  
  const vehicleTypeCounts = {};
  
  docs.forEach((doc, index) => {
    const data = doc.data();
    console.log(`Driver ${index + 1}:`);
    
    // Look for vehicle type information
    const vehicleFields = ['vehicleType', 'vehicle_type', 'selectedVehicleType', 'vehicleCategory'];
    let vehicleType = null;
    
    for (const field of vehicleFields) {
      if (data[field]) {
        vehicleType = data[field];
        console.log(`  Vehicle Type: ${vehicleType} (field: ${field})`);
        break;
      }
    }
    
    if (vehicleType) {
      vehicleTypeCounts[vehicleType] = (vehicleTypeCounts[vehicleType] || 0) + 1;
    } else {
      console.log('  ⚠️ No vehicle type found');
      // Show all fields to help identify the correct one
      console.log('  📄 Available fields:', Object.keys(data).join(', '));
    }
  });
  
  console.log('\n📊 Vehicle Type Registration Summary:');
  Object.entries(vehicleTypeCounts).forEach(([type, count]) => {
    console.log(`  ${type}: ${count} registered driver(s)`);
  });
  
  if (Object.keys(vehicleTypeCounts).length === 0) {
    console.log('  ❌ No vehicle types identified in driver registrations');
  }
}

analyzeVehicleRegistrations();
