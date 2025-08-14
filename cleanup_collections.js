const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    projectId: 'request-marketplace'
  });
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error);
  console.log('💡 Make sure you are logged in to Firebase CLI: firebase login');
  process.exit(1);
}

const db = admin.firestore();

// Function to delete all documents in a collection
async function deleteCollection(collectionName) {
  console.log(`🗑️ Deleting all documents in ${collectionName} collection...`);
  
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  if (snapshot.empty) {
    console.log(`✅ No documents found in ${collectionName} collection`);
    return 0;
  }

  console.log(`📊 Found ${snapshot.docs.length} document(s) in ${collectionName}`);

  const batch = db.batch();
  let deleteCount = 0;

  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
    deleteCount++;
    console.log(`🗑️ Will delete ${collectionName} document: ${doc.id}`);
  });

  if (deleteCount > 0) {
    console.log(`🚀 Committing batch delete for ${deleteCount} document(s)...`);
    await batch.commit();
    console.log(`✅ Successfully deleted ${deleteCount} document(s) from ${collectionName}`);
  }

  return deleteCount;
}

// Main cleanup function
async function cleanupCollections() {
  try {
    console.log('🧹 Starting cleanup of requests and responses collections...\n');

    const requestsDeleted = await deleteCollection('requests');
    console.log(''); // Empty line for readability

    const responsesDeleted = await deleteCollection('responses');
    console.log(''); // Empty line for readability

    // Optional: Also clean price_listings if you want
    // const priceListingsDeleted = await deleteCollection('price_listings');
    // console.log(''); // Empty line for readability

    console.log('🎉 Cleanup completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Requests deleted: ${requestsDeleted}`);
    console.log(`   - Responses deleted: ${responsesDeleted}`);
    // console.log(`   - Price listings deleted: ${priceListingsDeleted}`);
    
    console.log('\n📝 Next Steps:');
    console.log('1. All new requests/responses will automatically include country information');
    console.log('2. Users can now create fresh requests with proper country support');
    console.log('3. Test creating new requests/responses through the mobile app');

  } catch (error) {
    console.error('❌ Cleanup failed:', error);
    throw error;
  }
}

// Run the cleanup
cleanupCollections()
  .then(() => {
    console.log('✅ Cleanup completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Cleanup failed:', error);
    process.exit(1);
  });
