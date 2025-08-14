const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixDriverStatus() {
  try {
    const driverId = 'G68WKHAnd8WuIlYlx8iHBO6urDy2'; // Rose Mary's driver ID
    
    const driverRef = db.collection('new_driver_verifications').doc(driverId);
    
    // Update the status from "approve" to "approved"
    await driverRef.update({
      status: 'approved',
      isVerified: true,
      updatedAt: admin.firestore.Timestamp.now()
    });
    
    console.log('✅ Successfully updated driver status to "approved"');
    
    // Verify the update
    const updatedDoc = await driverRef.get();
    const data = updatedDoc.data();
    console.log(`Status: ${data.status}`);
    console.log(`isVerified: ${data.isVerified}`);
    
  } catch (error) {
    console.error('❌ Error updating driver status:', error);
  } finally {
    process.exit();
  }
}

fixDriverStatus();
