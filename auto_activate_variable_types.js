/**
 * Simple auto-activation script for variable types only
 * This can be called when a country is enabled to automatically create activation records
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
 * Auto-activate all variable types for a specific country
 * @param {string} countryCode - The country code (e.g., 'LK', 'US', 'IN')
 * @param {string} countryName - The country name (e.g., 'Sri Lanka', 'United States')
 * @param {string} createdBy - User ID who enabled the country
 * @param {string} createdByName - User name who enabled the country
 */
async function autoActivateVariableTypesForCountry(countryCode, countryName, createdBy = 'system', createdByName = 'System') {
  console.log(`🚀 Auto-activating variable types for country: ${countryName} (${countryCode})`);
  
  try {
    // Get all variable types
    const variableTypesSnapshot = await getDocs(collection(db, 'variable_types'));
    console.log(`📊 Found ${variableTypesSnapshot.docs.length} variable types in database`);
    
    // Check existing activations for this country
    const existingActivationsSnapshot = await getDocs(
      query(collection(db, 'country_variable_types'), where('country', '==', countryCode))
    );
    const existingIds = new Set(existingActivationsSnapshot.docs.map(doc => doc.data().variableTypeId));
    console.log(`📋 Found ${existingIds.size} existing activations for ${countryCode}`);
    
    let activatedCount = 0;
    let skippedCount = 0;
    
    for (const varTypeDoc of variableTypesSnapshot.docs) {
      const varTypeData = varTypeDoc.data();
      
      // Skip if already activated
      if (existingIds.has(varTypeDoc.id)) {
        console.log(`⚠️  Variable type "${varTypeData.name}" already activated for ${countryCode}`);
        skippedCount++;
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
    
    console.log(`\n🎉 Summary for ${countryCode}:`);
    console.log(`   ✅ ${activatedCount} new variable types activated`);
    console.log(`   ⚠️  ${skippedCount} variable types already activated`);
    console.log(`   📊 Total: ${activatedCount + skippedCount}/${variableTypesSnapshot.docs.length} variable types`);
    
    return {
      success: true,
      activated: activatedCount,
      skipped: skippedCount,
      total: variableTypesSnapshot.docs.length
    };
    
  } catch (error) {
    console.error(`❌ Error auto-activating variable types for ${countryName}:`, error);
    throw error;
  }
}

/**
 * Clean up test activations (helper function)
 */
async function cleanupTestActivations(countryCode) {
  console.log(`🧹 Cleaning up test activations for ${countryCode}...`);
  
  const snapshot = await getDocs(
    query(collection(db, 'country_variable_types'), where('country', '==', countryCode))
  );
  
  for (const doc of snapshot.docs) {
    await doc.ref.delete();
    console.log(`🗑️  Deleted activation: ${doc.data().variableTypeName}`);
  }
  
  console.log(`✅ Cleaned up ${snapshot.docs.length} test activations`);
}

module.exports = {
  autoActivateVariableTypesForCountry,
  cleanupTestActivations
};

// Command line usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length >= 1 && args[0] === 'cleanup') {
    const countryCode = args[1] || 'TEST';
    cleanupTestActivations(countryCode)
      .then(() => process.exit(0))
      .catch(error => {
        console.error('Error:', error);
        process.exit(1);
      });
    return;
  }
  
  if (args.length < 2) {
    console.log('Usage: node auto_activate_variable_types.js <countryCode> <countryName> [createdBy] [createdByName]');
    console.log('       node auto_activate_variable_types.js cleanup [countryCode]');
    console.log('');
    console.log('Examples:');
    console.log('  node auto_activate_variable_types.js US "United States" admin_123 "Admin User"');
    console.log('  node auto_activate_variable_types.js cleanup TEST');
    process.exit(1);
  }
  
  const [countryCode, countryName, createdBy, createdByName] = args;
  autoActivateVariableTypesForCountry(countryCode, countryName, createdBy, createdByName)
    .then((result) => {
      console.log(`\n✅ Script completed successfully:`, result);
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}
