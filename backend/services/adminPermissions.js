const dbService = require('./database');

/**
 * Standard permissions for all admin users
 */
const STANDARD_PERMISSIONS = {
  // Request Management
  requestManagement: true,
  responseManagement: true,
  priceListingManagement: true,
  
  // Business Management
  productManagement: true,
  businessManagement: true,
  driverVerification: true,
  
  // Vehicle Management
  vehicleManagement: true,
  countryVehicleTypeManagement: true,
  
  // City Management
  cityManagement: true,
  
  // User & Module Management
  userManagement: true,
  subscriptionManagement: true,
  promoCodeManagement: true,
  moduleManagement: true,
  
  // Product Catalog Management
  categoryManagement: true,
  subcategoryManagement: true,
  brandManagement: true,
  variableTypeManagement: true,
  
  // Country-specific Management (for country admins)
  countryProductManagement: true,
  countryCategoryManagement: true,
  countrySubcategoryManagement: true,
  countryBrandManagement: true,
  countryVariableTypeManagement: true,
  countryVehicleTypeManagement: true,
  
  // Content Management
  contentManagement: true,
  countryPageManagement: true,
  
  // Legal & Payment (available for country admins too)
  paymentMethodManagement: true,
  legalDocumentManagement: true,
  
  // SMS Configuration
  smsConfiguration: true
};

/**
 * Permissions only for super admins
 */
const SUPER_ADMIN_ONLY_PERMISSIONS = {
  adminUsersManagement: true
};

/**
 * Get default permissions for a new admin user based on their role
 * @param {string} role - 'super_admin' or 'country_admin'
 * @returns {object} - Complete permissions object
 */
function getDefaultPermissionsForRole(role) {
  let permissions = { ...STANDARD_PERMISSIONS };
  
  if (role === 'super_admin') {
    permissions = { ...permissions, ...SUPER_ADMIN_ONLY_PERMISSIONS };
  }
  
  return permissions;
}

/**
 * Auto-activate data for a new country
 * @param {string} countryCode - Country code (e.g., 'LK', 'US')
 * @param {string} countryName - Country name (e.g., 'Sri Lanka', 'United States')
 * @param {string} adminUserId - ID of admin creating the activation
 * @param {string} adminUserName - Name of admin creating the activation
 */
async function autoActivateCountryData(countryCode, countryName, adminUserId, adminUserName) {
  console.log(`🔄 Auto-activating data for country: ${countryName} (${countryCode})`);
  
  try {
    // Define the collections and their table mappings
    const collections = [
      { name: 'variable_types', activationTable: 'country_variable_types', nameField: 'name' },
      { name: 'categories', activationTable: 'country_categories', nameField: 'category' },
      { name: 'subcategories', activationTable: 'country_subcategories', nameField: 'subcategory' },
      { name: 'brands', activationTable: 'country_brands', nameField: 'name' },
      { name: 'products', activationTable: 'country_products', nameField: 'name' },
      { name: 'vehicle_types', activationTable: 'country_vehicle_types', nameField: 'name' }
    ];
    
    for (const collection of collections) {
      console.log(`   📋 Processing ${collection.name}...`);
      
      // Get all items from the main table
      const items = await dbService.query(`SELECT id, ${collection.nameField} FROM ${collection.name} WHERE is_active = true`);
      
      let activatedCount = 0;
      let skippedCount = 0;
      
      for (const item of items.rows) {
        // Check if activation already exists
        const existing = await dbService.query(
          `SELECT id FROM ${collection.activationTable} WHERE country = $1 AND ${collection.name.slice(0, -1)}_id = $2`,
          [countryCode, item.id]
        );
        
        if (existing.rows.length === 0) {
          // Create activation record
          await dbService.query(
            `INSERT INTO ${collection.activationTable} (
              country, 
              country_name, 
              ${collection.name.slice(0, -1)}_id, 
              ${collection.name.slice(0, -1)}_name, 
              is_active, 
              created_at, 
              updated_at, 
              created_by, 
              created_by_name
            ) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $6, $7)`,
            [
              countryCode,
              countryName,
              item.id,
              item[collection.nameField],
              true,
              adminUserId,
              adminUserName
            ]
          );
          activatedCount++;
        } else {
          skippedCount++;
        }
      }
      
      console.log(`   ✅ ${collection.name}: ${activatedCount} activated, ${skippedCount} already existed`);
    }
    
    console.log(`🎉 Auto-activation completed for ${countryName}!`);
    
  } catch (error) {
    console.error(`❌ Error during auto-activation for ${countryName}:`, error);
    throw error;
  }
}

module.exports = {
  getDefaultPermissionsForRole,
  autoActivateCountryData,
  STANDARD_PERMISSIONS,
  SUPER_ADMIN_ONLY_PERMISSIONS
};
