const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

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

async function checkDatabase() {
  console.log('🔍 Checking database collections...');
  
  try {
    // Check countries collection
    const countriesSnapshot = await getDocs(collection(db, 'countries'));
    console.log(`📊 Countries collection: ${countriesSnapshot.docs.length} documents`);
    
    if (countriesSnapshot.docs.length > 0) {
      countriesSnapshot.docs.forEach(doc => {
        console.log(`  - ${doc.id}: ${JSON.stringify(doc.data())}`);
      });
    }
    
    // Check categories collection
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    console.log(`📂 Categories collection: ${categoriesSnapshot.docs.length} documents`);
    
    // Check products collection
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    console.log(`📦 Master Products collection: ${productsSnapshot.docs.length} documents`);
    
    // Check existing country_categories
    const countryCategories = await getDocs(collection(db, 'country_categories'));
    console.log(`🏁 Country Categories collection: ${countryCategories.docs.length} documents`);
    
    // Check existing country_products
    const countryProducts = await getDocs(collection(db, 'country_products'));
    console.log(`🏁 Country Products collection: ${countryProducts.docs.length} documents`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the check
checkDatabase()
  .then(() => {
    console.log('\n✅ Database check completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Database check failed:', error);
    process.exit(1);
  });
