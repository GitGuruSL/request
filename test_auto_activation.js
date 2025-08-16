const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, serverTimestamp } = require('firebase/firestore');

const firebaseConfig = { 
  projectId: 'request-marketplace'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testAutoActivationSystem() {
  console.log('🧪 Testing auto-activation system...\n');
  
  try {
    console.log('Creating a test vehicle type to trigger auto-activation...');
    
    // Add a test vehicle type (this should trigger the Cloud Function)
    const testVehicle = {
      name: 'Test Auto Vehicle',
      icon: 'TestIcon',
      displayOrder: 999,
      isActive: true,
      passengerCapacity: 2,
      description: 'Test vehicle for auto-activation system',
      createdAt: serverTimestamp(),
      createdBy: 'auto-activation-test'
    };
    
    const docRef = await addDoc(collection(db, 'vehicle_types'), testVehicle);
    console.log(`✅ Test vehicle created with ID: ${docRef.id}`);
    console.log('🔔 This should trigger the auto-activation Cloud Function');
    console.log('📋 Check Firebase Functions logs to see if it activated for all countries');
    
    console.log('\n⚠️ REMEMBER TO DELETE THIS TEST VEHICLE AFTER TESTING!');
    console.log(`💡 Delete command: firebase firestore:delete vehicle_types/${docRef.id}`);
    
  } catch (error) {
    console.error('❌ Error testing auto-activation:', error);
  }
}

// Uncomment the line below to run the test
// testAutoActivationSystem();

console.log('🔧 Auto-activation test script ready');
console.log('📝 Uncomment the last line in this file to run the test');
console.log('⚠️ Make sure Cloud Functions are deployed first!');
