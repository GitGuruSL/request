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

async function checkCategoryActivations() {
  console.log('🔍 Checking category activation status for LK...');
  
  const countryCode = 'LK';
  
  try {
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    const categoriesMap = new Map();
    categoriesSnapshot.docs.forEach(doc => {
      categoriesMap.set(doc.id, doc.data());
    });
    
    // Get category activations for LK
    const activationsQuery = query(
      collection(db, 'country_categories'), 
      where('country', '==', countryCode)
    );
    const activationsSnapshot = await getDocs(activationsQuery);
    
    console.log(`\n📂 Category Activations for ${countryCode}:`);
    
    const activeCategories = [];
    const inactiveCategories = [];
    
    activationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const categoryId = data.categoryId;
      const isActive = data.isActive;
      const categoryData = categoriesMap.get(categoryId);
      
      const categoryInfo = {
        id: categoryId,
        name: categoryData?.name || 'Unknown',
        type: categoryData?.type || 'Unknown',
        isActive: isActive
      };
      
      if (isActive) {
        activeCategories.push(categoryInfo);
      } else {
        inactiveCategories.push(categoryInfo);
      }
    });
    
    console.log(`\n✅ ACTIVE Categories (${activeCategories.length}):`);
    activeCategories.forEach(cat => {
      console.log(`  ✅ ${cat.name || cat.id} (${cat.type})`);
    });
    
    console.log(`\n❌ INACTIVE Categories (${inactiveCategories.length}):`);
    inactiveCategories.forEach(cat => {
      console.log(`  ❌ ${cat.name || cat.id} (${cat.type})`);
    });
    
    // Check if there are categories without activation records
    const activatedCategoryIds = new Set(activationsSnapshot.docs.map(doc => doc.data().categoryId));
    const categoriesWithoutActivation = [];
    
    categoriesSnapshot.docs.forEach(doc => {
      if (!activatedCategoryIds.has(doc.id)) {
        const data = doc.data();
        categoriesWithoutActivation.push({
          id: doc.id,
          name: data.name || 'Unknown',
          type: data.type || 'Unknown'
        });
      }
    });
    
    if (categoriesWithoutActivation.length > 0) {
      console.log(`\n⚠️  Categories WITHOUT activation records (${categoriesWithoutActivation.length}):`);
      categoriesWithoutActivation.forEach(cat => {
        console.log(`  ⚠️  ${cat.name || cat.id} (${cat.type})`);
      });
    }
    
    console.log(`\n📊 Summary:`);
    console.log(`- Total categories: ${categoriesSnapshot.docs.length}`);
    console.log(`- Active: ${activeCategories.length}`);
    console.log(`- Inactive: ${inactiveCategories.length}`);
    console.log(`- Without activation: ${categoriesWithoutActivation.length}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the check
checkCategoryActivations()
  .then(() => {
    console.log('\n✅ Category check completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Category check failed:', error);
    process.exit(1);
  });
