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

async function debugMissingData() {
  console.log('🔍 Debugging missing subcategories and products...');
  
  const countryCode = 'LK';
  
  try {
    // Check subcategories
    console.log('\n📁 SUBCATEGORIES ANALYSIS:');
    const subcategoriesSnapshot = await getDocs(collection(db, 'subcategories'));
    const subcategoryActivationsSnapshot = await getDocs(query(
      collection(db, 'country_subcategories'),
      where('country', '==', countryCode)
    ));
    
    console.log(`Total subcategories: ${subcategoriesSnapshot.docs.length}`);
    console.log(`Subcategory activations for LK: ${subcategoryActivationsSnapshot.docs.length}`);
    
    const activatedSubcategoryIds = new Set(
      subcategoryActivationsSnapshot.docs.map(doc => doc.data().subcategoryId)
    );
    
    const activeSubcategories = subcategoryActivationsSnapshot.docs.filter(doc => 
      doc.data().isActive ?? false
    ).length;
    
    console.log(`Active subcategories: ${activeSubcategories}`);
    console.log(`Subcategories without activation records: ${subcategoriesSnapshot.docs.length - subcategoryActivationsSnapshot.docs.length}`);
    
    // Check products
    console.log('\n📦 PRODUCTS ANALYSIS:');
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    const productActivationsSnapshot = await getDocs(query(
      collection(db, 'country_products'),
      where('country', '==', countryCode)
    ));
    
    console.log(`Total products: ${productsSnapshot.docs.length}`);
    console.log(`Product activations for LK: ${productActivationsSnapshot.docs.length}`);
    
    const activatedProductIds = new Set(
      productActivationsSnapshot.docs.map(doc => doc.data().productId)
    );
    
    const activeProducts = productActivationsSnapshot.docs.filter(doc => 
      doc.data().isActive ?? false
    ).length;
    
    console.log(`Active products: ${activeProducts}`);
    console.log(`Products without activation records: ${productsSnapshot.docs.length - productActivationsSnapshot.docs.length}`);
    
    // List products without activation records
    const productsWithoutActivation = [];
    productsSnapshot.docs.forEach(doc => {
      if (!activatedProductIds.has(doc.id)) {
        productsWithoutActivation.push({
          id: doc.id,
          name: doc.data().name || 'Unknown'
        });
      }
    });
    
    if (productsWithoutActivation.length > 0) {
      console.log('\n❌ Products without activation records:');
      productsWithoutActivation.forEach(product => {
        console.log(`  - ${product.name} (${product.id})`);
      });
    }
    
    // Check what the mobile app would see
    console.log('\n📱 MOBILE APP SIMULATION:');
    
    // Simulate getActiveSubcategories
    const visibleSubcategories = subcategoryActivationsSnapshot.docs.filter(doc => 
      doc.data().isActive ?? false
    ).length;
    
    // Simulate getActiveProducts  
    const visibleProducts = productActivationsSnapshot.docs.filter(doc => 
      doc.data().isActive ?? false
    ).length;
    
    console.log(`Subcategories visible in mobile app: ${visibleSubcategories}`);
    console.log(`Products visible in mobile app: ${visibleProducts}`);
    
    if (visibleSubcategories === 0) {
      console.log('🚨 NO SUBCATEGORIES VISIBLE - This explains why request creation shows no subcategories!');
    }
    
    if (visibleProducts === 0) {
      console.log('🚨 NO PRODUCTS VISIBLE - This explains why price comparison shows no products!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the debug
debugMissingData()
  .then(() => {
    console.log('\n✅ Debug completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Debug failed:', error);
    process.exit(1);
  });
