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

async function checkExistingData() {
  console.log('🔍 Checking existing country activation data...');
  
  try {
    // Check existing country_categories
    const countryCategories = await getDocs(collection(db, 'country_categories'));
    console.log(`📂 Country Categories: ${countryCategories.docs.length} documents`);
    
    const countriesFromCategories = new Set();
    countryCategories.docs.forEach(doc => {
      const data = doc.data();
      countriesFromCategories.add(data.country);
      console.log(`  - ${doc.id}: country=${data.country}, categoryId=${data.categoryId}, isActive=${data.isActive}`);
    });
    
    // Check existing country_products
    const countryProducts = await getDocs(collection(db, 'country_products'));
    console.log(`\n📦 Country Products: ${countryProducts.docs.length} documents`);
    
    const countriesFromProducts = new Set();
    countryProducts.docs.forEach(doc => {
      const data = doc.data();
      countriesFromProducts.add(data.country);
      console.log(`  - ${doc.id}: country=${data.country}, productId=${data.productId}, isActive=${data.isActive}`);
    });
    
    // Get all unique country codes
    const allCountries = new Set([...countriesFromCategories, ...countriesFromProducts]);
    console.log(`\n🌍 Found countries in use: ${Array.from(allCountries).join(', ')}`);
    
    // Check all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    console.log(`\n📂 All Categories: ${categoriesSnapshot.docs.length} documents`);
    categoriesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${doc.id}: ${data.name} (type: ${data.type})`);
    });
    
    // Check all products
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    console.log(`\n📦 All Master Products: ${productsSnapshot.docs.length} documents`);
    productsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${doc.id}: ${data.name}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the check
checkExistingData()
  .then(() => {
    console.log('\n✅ Data check completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Data check failed:', error);
    process.exit(1);
  });
