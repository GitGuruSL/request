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

// Simulate the mobile app's filtering logic
async function simulateMobileAppFiltering() {
  console.log('🔍 Simulating Mobile App Country Filtering Logic...');
  
  const countryCode = 'LK';
  
  try {
    console.log(`\n📱 === MOBILE APP PERSPECTIVE (Country: ${countryCode}) ===\n`);
    
    // === SIMULATE getActiveCategories() ===
    console.log('📂 Categories that would appear in mobile app:');
    
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    
    // Get country-specific activations
    const countryActivationsSnapshot = await getDocs(query(
      collection(db, 'country_categories'),
      where('country', '==', countryCode)
    ));
    
    const countryActivations = {};
    countryActivationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      countryActivations[data.categoryId] = data.isActive ?? false;
    });
    
    // Filter active categories (mobile app logic)
    const visibleCategories = [];
    const hiddenCategories = [];
    
    categoriesSnapshot.docs.forEach(doc => {
      const categoryId = doc.id;
      const categoryData = doc.data();
      const isActive = countryActivations[categoryId] ?? false; // This is the key line
      
      const categoryInfo = {
        id: categoryId,
        type: categoryData.type || 'Unknown',
        isActive: isActive,
        hasActivationRecord: countryActivations.hasOwnProperty(categoryId)
      };
      
      if (isActive) {
        visibleCategories.push(categoryInfo);
        console.log(`  ✅ VISIBLE: ${categoryId} (${categoryInfo.type}) - isActive: ${isActive}`);
      } else {
        hiddenCategories.push(categoryInfo);
        console.log(`  ❌ HIDDEN: ${categoryId} (${categoryInfo.type}) - isActive: ${isActive} - hasRecord: ${categoryInfo.hasActivationRecord}`);
      }
    });
    
    // === SIMULATE getActiveProducts() ===
    console.log(`\n📦 Products that would appear in mobile app:`);
    
    // Get all products
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    
    // Get country-specific product activations
    const productActivationsSnapshot = await getDocs(query(
      collection(db, 'country_products'),
      where('country', '==', countryCode)
    ));
    
    const productActivations = {};
    productActivationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      productActivations[data.productId] = data.isActive ?? false;
    });
    
    // Filter active products (mobile app logic)
    const visibleProducts = [];
    const hiddenProducts = [];
    
    productsSnapshot.docs.forEach(doc => {
      const productId = doc.id;
      const productData = doc.data();
      const isActive = productActivations[productId] ?? false; // This is the key line
      
      const productInfo = {
        id: productId,
        name: productData.name || 'Unknown',
        isActive: isActive,
        hasActivationRecord: productActivations.hasOwnProperty(productId)
      };
      
      if (isActive) {
        visibleProducts.push(productInfo);
        console.log(`  ✅ VISIBLE: ${productInfo.name} (${productId}) - isActive: ${isActive}`);
      } else {
        hiddenProducts.push(productInfo);
        console.log(`  ❌ HIDDEN: ${productInfo.name} (${productId}) - isActive: ${isActive} - hasRecord: ${productInfo.hasActivationRecord}`);
      }
    });
    
    console.log(`\n📊 Mobile App Summary:`);
    console.log(`Categories: ${visibleCategories.length} visible, ${hiddenCategories.length} hidden`);
    console.log(`Products: ${visibleProducts.length} visible, ${hiddenProducts.length} hidden`);
    
    console.log(`\n🔧 Filtering Logic:`);
    console.log(`- Using strict filtering: countryActivations[id] ?? false`);
    console.log(`- Items WITHOUT activation records are HIDDEN`);
    console.log(`- Items with isActive: false are HIDDEN`);
    console.log(`- Items with isActive: true are VISIBLE`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the simulation
simulateMobileAppFiltering()
  .then(() => {
    console.log('\n✅ Mobile app filtering simulation completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Simulation failed:', error);
    process.exit(1);
  });
