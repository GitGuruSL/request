const database = require('./services/database');
const BusinessNotificationService = require('./services/business-notification-service');

async function testBusinessCategorization() {
  try {
    console.log('🧪 Testing Business Categorization System');
    console.log('=' .repeat(50));

    // 1. Check current business data
    console.log('\n📊 Current Business Data:');
    const businesses = await database.query(`
      SELECT business_name, business_type, business_category, categories, is_verified, status
      FROM business_verifications 
      ORDER BY business_name
    `);

    businesses.rows.forEach(biz => {
      console.log(`  ${biz.business_name}:`);
      console.log(`    Type: ${biz.business_type}`);
      console.log(`    Old Category: ${biz.business_category}`);
      console.log(`    Categories: ${JSON.stringify(biz.categories)}`);
      console.log(`    Verified: ${biz.is_verified}, Status: ${biz.status}`);
      console.log('');
    });

    // 2. Test access rights for each business
    console.log('\n🔐 Testing Access Rights:');
    for (const biz of businesses.rows) {
      if (biz.is_verified && biz.status === 'approved') {
        const userId = await database.queryOne('SELECT id FROM users WHERE display_name LIKE $1', [`%${biz.business_name.split(' ')[0]}%`]);
        if (userId) {
          const rights = await BusinessNotificationService.getBusinessAccessRights(userId.id);
          console.log(`  ${biz.business_name} (${userId.id}):`);
          console.log(`    Can Add Prices: ${rights.canAddPrices}`);
          console.log(`    Can Respond to Delivery: ${rights.canRespondToDelivery}`);
          console.log(`    Can Respond to Products: ${rights.canRespondToProducts}`);
          console.log(`    Categories: ${JSON.stringify(rights.categories)}`);
          console.log('');
        }
      }
    }

    // 3. Test notification targeting
    console.log('\n🎯 Testing Notification Targeting:');
    
    // Get a sample electronics category ID
    const electronicsCategory = await database.queryOne(`
      SELECT id FROM categories WHERE name ILIKE '%electronics%' LIMIT 1
    `);

    if (electronicsCategory) {
      console.log(`Testing with Electronics category: ${electronicsCategory.id}`);
      
      const deliveryBusinesses = await BusinessNotificationService.getDeliveryBusinesses('LK');
      console.log(`  Delivery businesses: ${deliveryBusinesses.length}`);
      deliveryBusinesses.forEach(b => console.log(`    - ${b.businessName}`));

      const productBusinesses = await BusinessNotificationService.getCategoryMatchingBusinesses(
        electronicsCategory.id, null, 'LK'
      );
      console.log(`  Product businesses for electronics: ${productBusinesses.length}`);
      productBusinesses.forEach(b => console.log(`    - ${b.businessName}`));
    }

    // 4. Suggest improvements
    console.log('\n💡 Suggestions:');
    const unverifiedCount = businesses.rows.filter(b => !b.is_verified || b.status !== 'approved').length;
    if (unverifiedCount > 0) {
      console.log(`  - ${unverifiedCount} businesses need verification to receive notifications`);
    }

    const emptyCategories = businesses.rows.filter(b => 
      b.business_type === 'product_selling' && 
      (!b.categories || b.categories.length === 0)
    ).length;
    if (emptyCategories > 0) {
      console.log(`  - ${emptyCategories} product-selling businesses need category assignments`);
    }

    console.log('\n✅ Test completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    process.exit(0);
  }
}

// Run the test
testBusinessCategorization();
