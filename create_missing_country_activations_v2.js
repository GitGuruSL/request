const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, addDoc, query, where } = require('firebase/firestore');

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

async function createMissingCountryActivations() {
  console.log('🔍 Creating missing country activation records...');
  
  try {
    // Get all countries
    const countriesSnapshot = await getDocs(collection(db, 'countries'));
    const countries = countriesSnapshot.docs.map(doc => ({
      id: doc.id,
      code: doc.data().code,
      name: doc.data().name
    }));
    
    console.log(`📊 Found ${countries.length} countries`);
    
    for (const country of countries) {
      console.log(`\n🌍 Processing ${country.name} (${country.code})...`);
      
      // Process Categories
      await processCategories(country.code);
      
      // Process Subcategories  
      await processSubcategories(country.code);
      
      // Process Products
      await processProducts(country.code);
      
      // Process Brands
      await processBrands(country.code);
      
      // Process Variable Types
      await processVariableTypes(country.code);
    }
    
    console.log('\n✅ Finished creating missing country activation records');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function processCategories(countryCode) {
  try {
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    
    // Get existing country activations
    const existingActivationsQuery = query(
      collection(db, 'country_categories'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().categoryId)
    );
    
    let created = 0;
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      
      if (!existingActivations.has(categoryId)) {
        // Create activation record - default to active for existing data
        await addDoc(collection(db, 'country_categories'), {
          country: countryCode,
          categoryId: categoryId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        created++;
      }
    }
    
    console.log(`  📂 Categories: Created ${created} activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing categories for ${countryCode}:`, error);
  }
}

async function processSubcategories(countryCode) {
  try {
    const subcategoriesSnapshot = await getDocs(collection(db, 'subcategories'));
    const existingActivationsQuery = query(
      collection(db, 'country_subcategories'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().subcategoryId)
    );
    
    let created = 0;
    
    for (const subcategoryDoc of subcategoriesSnapshot.docs) {
      const subcategoryId = subcategoryDoc.id;
      
      if (!existingActivations.has(subcategoryId)) {
        await addDoc(collection(db, 'country_subcategories'), {
          country: countryCode,
          subcategoryId: subcategoryId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        created++;
      }
    }
    
    console.log(`  📁 Subcategories: Created ${created} activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing subcategories for ${countryCode}:`, error);
  }
}

async function processProducts(countryCode) {
  try {
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    const existingActivationsQuery = query(
      collection(db, 'country_products'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().productId)
    );
    
    let created = 0;
    
    for (const productDoc of productsSnapshot.docs) {
      const productId = productDoc.id;
      
      if (!existingActivations.has(productId)) {
        await addDoc(collection(db, 'country_products'), {
          country: countryCode,
          productId: productId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        created++;
      }
    }
    
    console.log(`  📦 Products: Created ${created} activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing products for ${countryCode}:`, error);
  }
}

async function processBrands(countryCode) {
  try {
    const brandsSnapshot = await getDocs(collection(db, 'brands'));
    const existingActivationsQuery = query(
      collection(db, 'country_brands'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().brandId)
    );
    
    let created = 0;
    
    for (const brandDoc of brandsSnapshot.docs) {
      const brandId = brandDoc.id;
      
      if (!existingActivations.has(brandId)) {
        await addDoc(collection(db, 'country_brands'), {
          country: countryCode,
          brandId: brandId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        created++;
      }
    }
    
    console.log(`  🏷️ Brands: Created ${created} activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing brands for ${countryCode}:`, error);
  }
}

async function processVariableTypes(countryCode) {
  try {
    const variableTypesSnapshot = await getDocs(collection(db, 'variable_types'));
    const existingActivationsQuery = query(
      collection(db, 'country_variable_types'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().variableTypeId)
    );
    
    let created = 0;
    
    for (const variableTypeDoc of variableTypesSnapshot.docs) {
      const variableTypeId = variableTypeDoc.id;
      
      if (!existingActivations.has(variableTypeId)) {
        await addDoc(collection(db, 'country_variable_types'), {
          country: countryCode,
          variableTypeId: variableTypeId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        created++;
      }
    }
    
    console.log(`  🏗️ Variable Types: Created ${created} activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing variable types for ${countryCode}:`, error);
  }
}

// Run the script
createMissingCountryActivations()
  .then(() => {
    console.log('\n🎉 Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Script failed:', error);
    process.exit(1);
  });
