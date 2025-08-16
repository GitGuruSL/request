/**
 * Auto-activate all variable types, categories, subcategories, etc. for a new country
 * This script should be run whenever a country is enabled in the country management system
 */

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, addDoc, query, where } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: 'AIzaSyAjxs8ydLyj_g1VgQFW4q2RJYp8jqvV7Wk',
  authDomain: 'request-marketplace.firebaseapp.com',
  projectId: 'request-marketplace',
  storageBucket: 'request-marketplace.appspot.com',
  messagingSenderId: '1098833929119',
  appId: '1:1098833929119:web:4e62b8de5f6fec8a8b8e4c'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

/**
 * Auto-activate all data types for a specific country
 * @param {string} countryCode - The country code (e.g., 'LK', 'US', 'IN')
 * @param {string} countryName - The country name (e.g., 'Sri Lanka', 'United States')
 * @param {string} createdBy - User ID who enabled the country
 * @param {string} createdByName - User name who enabled the country
 */
async function autoActivateCountryData(countryCode, countryName, createdBy = 'system', createdByName = 'System') {
  console.log(`🚀 Auto-activating all data for country: ${countryName} (${countryCode})`);
  
  try {
    // 1. Auto-activate all variable types
    await autoActivateVariableTypes(countryCode, countryName, createdBy, createdByName);
    
    // 2. Auto-activate all categories
    await autoActivateCategories(countryCode, countryName, createdBy, createdByName);
    
    // 3. Auto-activate all subcategories
    await autoActivateSubcategories(countryCode, countryName, createdBy, createdByName);
    
    // 4. Auto-activate all brands
    await autoActivateBrands(countryCode, countryName, createdBy, createdByName);
    
    // 5. Auto-activate all products
    await autoActivateProducts(countryCode, countryName, createdBy, createdByName);
    
    // 6. Auto-activate all vehicle types
    await autoActivateVehicleTypes(countryCode, countryName, createdBy, createdByName);
    
    console.log(`🎉 Successfully auto-activated all data for ${countryName}!`);
    
  } catch (error) {
    console.error(`❌ Error auto-activating data for ${countryName}:`, error);
    throw error;
  }
}

/**
 * Auto-activate all variable types for a country
 */
async function autoActivateVariableTypes(countryCode, countryName, createdBy, createdByName) {
  console.log(`📊 Auto-activating variable types for ${countryCode}...`);
  
  // Get all variable types
  const variableTypesSnapshot = await getDocs(collection(db, 'variable_types'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_variable_types'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().variableTypeId));
  
  let activatedCount = 0;
  
  for (const varTypeDoc of variableTypesSnapshot.docs) {
    const varTypeData = varTypeDoc.data();
    
    // Skip if already activated
    if (existingIds.has(varTypeDoc.id)) {
      console.log(`⚠️  Variable type "${varTypeData.name}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_variable_types'), {
      country: countryCode,
      countryName: countryName,
      variableTypeId: varTypeDoc.id,
      variableTypeName: varTypeData.name,
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated variable type: ${varTypeData.name}`);
    activatedCount++;
  }
  
  console.log(`📊 Variable types: ${activatedCount} new activations created for ${countryCode}`);
}

/**
 * Auto-activate all categories for a country
 */
async function autoActivateCategories(countryCode, countryName, createdBy, createdByName) {
  console.log(`📁 Auto-activating categories for ${countryCode}...`);
  
  // Get all categories
  const categoriesSnapshot = await getDocs(collection(db, 'categories'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_categories'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().categoryId));
  
  let activatedCount = 0;
  
  for (const categoryDoc of categoriesSnapshot.docs) {
    const categoryData = categoryDoc.data();
    
    // Skip if already activated
    if (existingIds.has(categoryDoc.id)) {
      console.log(`⚠️  Category "${categoryData.category}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_categories'), {
      country: countryCode,
      countryName: countryName,
      categoryId: categoryDoc.id,
      categoryName: categoryData.category, // Use 'category' field
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated category: ${categoryData.category}`);
    activatedCount++;
  }
  
  console.log(`📁 Categories: ${activatedCount} new activations created for ${countryCode}`);
}

/**
 * Auto-activate all subcategories for a country
 */
async function autoActivateSubcategories(countryCode, countryName, createdBy, createdByName) {
  console.log(`📂 Auto-activating subcategories for ${countryCode}...`);
  
  // Get all subcategories
  const subcategoriesSnapshot = await getDocs(collection(db, 'subcategories'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_subcategories'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().subcategoryId));
  
  let activatedCount = 0;
  
  for (const subcategoryDoc of subcategoriesSnapshot.docs) {
    const subcategoryData = subcategoryDoc.data();
    
    // Skip if already activated
    if (existingIds.has(subcategoryDoc.id)) {
      console.log(`⚠️  Subcategory "${subcategoryData.subcategory}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_subcategories'), {
      country: countryCode,
      countryName: countryName,
      subcategoryId: subcategoryDoc.id,
      subcategoryName: subcategoryData.subcategory, // Use 'subcategory' field
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated subcategory: ${subcategoryData.subcategory}`);
    activatedCount++;
  }
  
  console.log(`📂 Subcategories: ${activatedCount} new activations created for ${countryCode}`);
}

/**
 * Auto-activate all brands for a country
 */
async function autoActivateBrands(countryCode, countryName, createdBy, createdByName) {
  console.log(`🏷️  Auto-activating brands for ${countryCode}...`);
  
  // Get all brands
  const brandsSnapshot = await getDocs(collection(db, 'brands'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_brands'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().brandId));
  
  let activatedCount = 0;
  
  for (const brandDoc of brandsSnapshot.docs) {
    const brandData = brandDoc.data();
    
    // Skip if already activated
    if (existingIds.has(brandDoc.id)) {
      console.log(`⚠️  Brand "${brandData.name}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_brands'), {
      country: countryCode,
      countryName: countryName,
      brandId: brandDoc.id,
      brandName: brandData.name,
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated brand: ${brandData.name}`);
    activatedCount++;
  }
  
  console.log(`🏷️  Brands: ${activatedCount} new activations created for ${countryCode}`);
}

/**
 * Auto-activate all products for a country
 */
async function autoActivateProducts(countryCode, countryName, createdBy, createdByName) {
  console.log(`📦 Auto-activating products for ${countryCode}...`);
  
  // Get all products
  const productsSnapshot = await getDocs(collection(db, 'products'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_products'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().productId));
  
  let activatedCount = 0;
  
  for (const productDoc of productsSnapshot.docs) {
    const productData = productDoc.data();
    
    // Skip if already activated
    if (existingIds.has(productDoc.id)) {
      console.log(`⚠️  Product "${productData.name}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_products'), {
      country: countryCode,
      countryName: countryName,
      productId: productDoc.id,
      productName: productData.name,
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated product: ${productData.name}`);
    activatedCount++;
  }
  
  console.log(`📦 Products: ${activatedCount} new activations created for ${countryCode}`);
}

/**
 * Auto-activate all vehicle types for a country
 */
async function autoActivateVehicleTypes(countryCode, countryName, createdBy, createdByName) {
  console.log(`🚗 Auto-activating vehicle types for ${countryCode}...`);
  
  // Get all vehicle types
  const vehicleTypesSnapshot = await getDocs(collection(db, 'vehicle_types'));
  
  // Check existing activations for this country
  const existingActivationsSnapshot = await getDocs(
    query(collection(db, 'country_vehicle_types'), where('country', '==', countryCode))
  );
  const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().vehicleTypeId));
  
  let activatedCount = 0;
  
  for (const vehicleTypeDoc of vehicleTypesSnapshot.docs) {
    const vehicleTypeData = vehicleTypeDoc.data();
    
    // Skip if already activated
    if (existingIds.has(vehicleTypeDoc.id)) {
      console.log(`⚠️  Vehicle type "${vehicleTypeData.name}" already activated for ${countryCode}`);
      continue;
    }
    
    // Create activation record
    await addDoc(collection(db, 'country_vehicle_types'), {
      country: countryCode,
      countryName: countryName,
      vehicleTypeId: vehicleTypeDoc.id,
      vehicleTypeName: vehicleTypeData.name,
      isActive: true, // Auto-activate by default
      createdAt: new Date(),
      updatedAt: new Date(),
      createdBy: createdBy,
      updatedBy: createdBy,
      createdByName: createdByName,
      updatedByName: createdByName
    });
    
    console.log(`✅ Activated vehicle type: ${vehicleTypeData.name}`);
    activatedCount++;
  }
  
  console.log(`🚗 Vehicle types: ${activatedCount} new activations created for ${countryCode}`);
}

// Example usage:
// autoActivateCountryData('US', 'United States', 'admin_user_id', 'Admin User');
// autoActivateCountryData('IN', 'India', 'admin_user_id', 'Admin User');

module.exports = {
  autoActivateCountryData,
  autoActivateVariableTypes,
  autoActivateCategories,
  autoActivateSubcategories,
  autoActivateBrands,
  autoActivateProducts,
  autoActivateVehicleTypes
};

// If running directly from command line
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.log('Usage: node auto_activate_country_data.js <countryCode> <countryName> [createdBy] [createdByName]');
    console.log('Example: node auto_activate_country_data.js US "United States" admin_123 "Admin User"');
    process.exit(1);
  }
  
  const [countryCode, countryName, createdBy, createdByName] = args;
  autoActivateCountryData(countryCode, countryName, createdBy, createdByName)
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}
