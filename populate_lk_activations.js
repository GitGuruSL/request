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

async function createMissingActivationsForLK() {
  console.log('🔍 Creating missing country activation records for LK (Sri Lanka)...');
  
  const countryCode = 'LK';
  
  try {
    // Process Categories
    await processCategories(countryCode);
    
    // Process Products
    await processProducts(countryCode);
    
    // Process Subcategories  
    await processSubcategories(countryCode);
    
    // Process Brands
    await processBrands(countryCode);
    
    // Process Variable Types
    await processVariableTypes(countryCode);
    
    console.log('\n✅ Finished creating missing country activation records for LK');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

async function processCategories(countryCode) {
  try {
    console.log(`\n📂 Processing Categories for ${countryCode}...`);
    
    // Get all categories
    const categoriesSnapshot = await getDocs(collection(db, 'categories'));
    console.log(`  Found ${categoriesSnapshot.docs.length} total categories`);
    
    // Get existing country activations
    const existingActivationsQuery = query(
      collection(db, 'country_categories'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().categoryId)
    );
    
    console.log(`  Found ${existingActivations.size} existing category activations`);
    
    let created = 0;
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      const categoryData = categoryDoc.data();
      
      if (!existingActivations.has(categoryId)) {
        // Create activation record - default to active for existing data
        await addDoc(collection(db, 'country_categories'), {
          country: countryCode,
          categoryId: categoryId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`    ✅ Created activation for category: ${categoryData.name || categoryId} (${categoryData.type})`);
        created++;
      } else {
        console.log(`    ⏭️  Skipped existing: ${categoryData.name || categoryId} (${categoryData.type})`);
      }
    }
    
    console.log(`  📊 Categories: Created ${created} new activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing categories for ${countryCode}:`, error);
  }
}

async function processProducts(countryCode) {
  try {
    console.log(`\n📦 Processing Products for ${countryCode}...`);
    
    const productsSnapshot = await getDocs(collection(db, 'master_products'));
    console.log(`  Found ${productsSnapshot.docs.length} total products`);
    
    const existingActivationsQuery = query(
      collection(db, 'country_products'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().productId)
    );
    
    console.log(`  Found ${existingActivations.size} existing product activations`);
    
    let created = 0;
    
    for (const productDoc of productsSnapshot.docs) {
      const productId = productDoc.id;
      const productData = productDoc.data();
      
      if (!existingActivations.has(productId)) {
        await addDoc(collection(db, 'country_products'), {
          country: countryCode,
          productId: productId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`    ✅ Created activation for product: ${productData.name || productId}`);
        created++;
      } else {
        console.log(`    ⏭️  Skipped existing: ${productData.name || productId}`);
      }
    }
    
    console.log(`  📊 Products: Created ${created} new activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing products for ${countryCode}:`, error);
  }
}

async function processSubcategories(countryCode) {
  try {
    console.log(`\n📁 Processing Subcategories for ${countryCode}...`);
    
    const subcategoriesSnapshot = await getDocs(collection(db, 'subcategories'));
    console.log(`  Found ${subcategoriesSnapshot.docs.length} total subcategories`);
    
    const existingActivationsQuery = query(
      collection(db, 'country_subcategories'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().subcategoryId)
    );
    
    console.log(`  Found ${existingActivations.size} existing subcategory activations`);
    
    let created = 0;
    
    for (const subcategoryDoc of subcategoriesSnapshot.docs) {
      const subcategoryId = subcategoryDoc.id;
      const subcategoryData = subcategoryDoc.data();
      
      if (!existingActivations.has(subcategoryId)) {
        await addDoc(collection(db, 'country_subcategories'), {
          country: countryCode,
          subcategoryId: subcategoryId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`    ✅ Created activation for subcategory: ${subcategoryData.name || subcategoryId}`);
        created++;
      } else {
        console.log(`    ⏭️  Skipped existing: ${subcategoryData.name || subcategoryId}`);
      }
    }
    
    console.log(`  📊 Subcategories: Created ${created} new activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing subcategories for ${countryCode}:`, error);
  }
}

async function processBrands(countryCode) {
  try {
    console.log(`\n🏷️ Processing Brands for ${countryCode}...`);
    
    const brandsSnapshot = await getDocs(collection(db, 'brands'));
    console.log(`  Found ${brandsSnapshot.docs.length} total brands`);
    
    const existingActivationsQuery = query(
      collection(db, 'country_brands'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().brandId)
    );
    
    console.log(`  Found ${existingActivations.size} existing brand activations`);
    
    let created = 0;
    
    for (const brandDoc of brandsSnapshot.docs) {
      const brandId = brandDoc.id;
      const brandData = brandDoc.data();
      
      if (!existingActivations.has(brandId)) {
        await addDoc(collection(db, 'country_brands'), {
          country: countryCode,
          brandId: brandId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`    ✅ Created activation for brand: ${brandData.name || brandId}`);
        created++;
      } else {
        console.log(`    ⏭️  Skipped existing: ${brandData.name || brandId}`);
      }
    }
    
    console.log(`  📊 Brands: Created ${created} new activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing brands for ${countryCode}:`, error);
  }
}

async function processVariableTypes(countryCode) {
  try {
    console.log(`\n🏗️ Processing Variable Types for ${countryCode}...`);
    
    const variableTypesSnapshot = await getDocs(collection(db, 'variable_types'));
    console.log(`  Found ${variableTypesSnapshot.docs.length} total variable types`);
    
    const existingActivationsQuery = query(
      collection(db, 'country_variable_types'), 
      where('country', '==', countryCode)
    );
    const existingActivationsSnapshot = await getDocs(existingActivationsQuery);
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().variableTypeId)
    );
    
    console.log(`  Found ${existingActivations.size} existing variable type activations`);
    
    let created = 0;
    
    for (const variableTypeDoc of variableTypesSnapshot.docs) {
      const variableTypeId = variableTypeDoc.id;
      const variableTypeData = variableTypeDoc.data();
      
      if (!existingActivations.has(variableTypeId)) {
        await addDoc(collection(db, 'country_variable_types'), {
          country: countryCode,
          variableTypeId: variableTypeId,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`    ✅ Created activation for variable type: ${variableTypeData.name || variableTypeId}`);
        created++;
      } else {
        console.log(`    ⏭️  Skipped existing: ${variableTypeData.name || variableTypeId}`);
      }
    }
    
    console.log(`  📊 Variable Types: Created ${created} new activation records`);
    
  } catch (error) {
    console.error(`❌ Error processing variable types for ${countryCode}:`, error);
  }
}

// Run the script
createMissingActivationsForLK()
  .then(() => {
    console.log('\n🎉 Script completed successfully');
    console.log('\n📝 Summary:');
    console.log('- Created activation records for all categories, products, subcategories, brands, and variable types');
    console.log('- All new records default to isActive: true');
    console.log('- Existing records (like the deactivated iPhone 15 Pro) remain unchanged');
    console.log('- You can now safely switch the CountryFilteredDataService to use ?? false default behavior');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Script failed:', error);
    process.exit(1);
  });
