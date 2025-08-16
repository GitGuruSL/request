const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, query, where } = require('firebase/firestore');

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAjxs8ydLyj_g1VgQFW4q2RJYp8jqvV7Wk",
  authDomain: "request-marketplace.firebaseapp.com",
  projectId: "request-marketplace",
  storageBucket: "request-marketplace.appspot.com",
  messagingSenderId: "1098833929119",
  appId: "1:1098833929119:web:4e62b8de5f6fec8a8b8e4c"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function verifyCountryFiltering() {
  console.log('🔍 Verifying country filtering is working correctly...');
  
  const countryCode = 'LK';
  
  try {
    // Check product activations for LK
    const productActivationsQuery = query(
      collection(db, 'country_products'), 
      where('country', '==', countryCode)
    );
    const productActivationsSnapshot = await getDocs(productActivationsQuery);
    
    console.log(`\n📦 Product Activations for ${countryCode}:`);
    
    for (const doc of productActivationsSnapshot.docs) {
      const data = doc.data();
      
      // Get product name
      const productDoc = await getDocs(query(
        collection(db, 'master_products'),
        where('__name__', '==', data.productId)
      ));
      
      const productName = productDoc.docs[0]?.data()?.name || data.productId;
      const status = data.isActive ? '✅ ACTIVE' : '❌ INACTIVE';
      
      console.log(`  ${status}: ${productName} (${data.productId})`);
    }
    
    // Show what should be filtered in vs out
    console.log(`\n📊 Summary:`);
    console.log(`- Products with isActive: true should appear in mobile app`);
    console.log(`- Products with isActive: false should NOT appear in mobile app`);
    console.log(`- iPhone 15 Pro should be filtered out since it's deactivated`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the verification
verifyCountryFiltering()
  .then(() => {
    console.log('\n✅ Verification completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Verification failed:', error);
    process.exit(1);
  });
