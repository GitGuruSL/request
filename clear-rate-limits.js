const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

async function clearRateLimits() {
  try {
    console.log('🧹 Clearing rate limits...');
    
    const rateLimitsRef = db.collection('rate_limits');
    const snapshot = await rateLimitsRef.get();
    
    if (snapshot.empty) {
      console.log('✅ No rate limits found to clear');
      return;
    }
    
    console.log(`📊 Found ${snapshot.size} rate limit documents to delete`);
    
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log('✅ Successfully cleared all rate limits');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error clearing rate limits:', error);
    process.exit(1);
  }
}

clearRateLimits();
