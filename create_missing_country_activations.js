const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
  admin.initializeApp({
    projectId: 'request-marketplace'
  });
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error);
  console.log('💡 Make sure you are logged in: firebase login');
  process.exit(1);
}

const db = admin.firestore();

async function createMissingCountryActivations() {
  console.log('🔍 Creating missing country activation records...');
  
  try {
    // Get all countries
    const countriesSnapshot = await db.collection('countries').get();
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
    const categoriesSnapshot = await db.collection('categories').get();
    
    // Get existing country activations
    const existingActivationsSnapshot = await db.collection('country_categories')
      .where('country', '==', countryCode)
      .get();
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().categoryId)
    );
    
    let created = 0;
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      
      if (!existingActivations.has(categoryId)) {
        // Create activation record - default to active for existing data
        await db.collection('country_categories').add({
          country: countryCode,
          categoryId: categoryId,
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    const subcategoriesSnapshot = await db.collection('subcategories').get();
    const existingActivationsSnapshot = await db.collection('country_subcategories')
      .where('country', '==', countryCode)
      .get();
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().subcategoryId)
    );
    
    let created = 0;
    
    for (const subcategoryDoc of subcategoriesSnapshot.docs) {
      const subcategoryId = subcategoryDoc.id;
      
      if (!existingActivations.has(subcategoryId)) {
        await db.collection('country_subcategories').add({
          country: countryCode,
          subcategoryId: subcategoryId,
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    const productsSnapshot = await db.collection('master_products').get();
    const existingActivationsSnapshot = await db.collection('country_products')
      .where('country', '==', countryCode)
      .get();
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().productId)
    );
    
    let created = 0;
    
    for (const productDoc of productsSnapshot.docs) {
      const productId = productDoc.id;
      
      if (!existingActivations.has(productId)) {
        await db.collection('country_products').add({
          country: countryCode,
          productId: productId,
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    const brandsSnapshot = await db.collection('brands').get();
    const existingActivationsSnapshot = await db.collection('country_brands')
      .where('country', '==', countryCode)
      .get();
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().brandId)
    );
    
    let created = 0;
    
    for (const brandDoc of brandsSnapshot.docs) {
      const brandId = brandDoc.id;
      
      if (!existingActivations.has(brandId)) {
        await db.collection('country_brands').add({
          country: countryCode,
          brandId: brandId,
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    const variableTypesSnapshot = await db.collection('variable_types').get();
    const existingActivationsSnapshot = await db.collection('country_variable_types')
      .where('country', '==', countryCode)
      .get();
    
    const existingActivations = new Set(
      existingActivationsSnapshot.docs.map(doc => doc.data().variableTypeId)
    );
    
    let created = 0;
    
    for (const variableTypeDoc of variableTypesSnapshot.docs) {
      const variableTypeId = variableTypeDoc.id;
      
      if (!existingActivations.has(variableTypeId)) {
        await db.collection('country_variable_types').add({
          country: countryCode,
          variableTypeId: variableTypeId,
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
