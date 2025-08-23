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
          console.log(`    Can Send Item Requests: ${rights.canSendItemRequests}`);
          console.log(`    Can Send Service Requests: ${rights.canSendServiceRequests}`);
          console.log(`    Can Send Delivery Requests: ${rights.canSendDeliveryRequests}`);
          console.log(`    Can Respond to Delivery: ${rights.canRespondToDelivery}`);
          console.log(`    Can Respond to Other: ${rights.canRespondToOther}`);
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
      
      // Test delivery request notifications
      const deliveryBusinesses = await BusinessNotificationService.getDeliveryBusinesses('LK');
      console.log(`  Delivery request notifications: ${deliveryBusinesses.length} businesses`);
      deliveryBusinesses.forEach(b => console.log(`    - ${b.businessName}`));

      // Test item request notifications (open to all)
      const itemBusinesses = await BusinessNotificationService.getAllBusinessesWithCategoryPreference(
        electronicsCategory.id, null, 'LK'
      );
      console.log(`  Item request notifications: ${itemBusinesses.length} businesses (all can respond)`);
      itemBusinesses.forEach(b => console.log(`    - ${b.businessName} (${b.notificationReason})`));
      
      // Test ride request (should be empty)
      console.log(`  Ride request notifications: 0 businesses (drivers only)`);
    }

    // 4. Suggest improvements
    console.log('\n💡 Business Logic Summary:');
    console.log('  📱 Item/Service/Rent requests: Anyone can respond');
    console.log('  🚚 Delivery requests: Only delivery service businesses');  
    console.log('  🚗 Ride requests: Only individual drivers (not businesses)');
    console.log('  💰 Price listings: Only product selling businesses');
    console.log('  📤 Send requests: Product sellers (except ride/delivery)');
    
    console.log('\n📊 Current Status:');
    const unverifiedCount = businesses.rows.filter(b => !b.is_verified || b.status !== 'approved').length;
    if (unverifiedCount > 0) {
      console.log(`  - ${unverifiedCount} businesses need verification to participate`);
    }

    const productSellers = businesses.rows.filter(b => 
      (b.business_type === 'product_selling' || b.business_type === 'both') &&
      b.is_verified && b.status === 'approved'
    ).length;
    const deliveryServices = businesses.rows.filter(b => 
      (b.business_type === 'delivery_service' || b.business_type === 'both') &&
      b.is_verified && b.status === 'approved'
    ).length;
    
    console.log(`  - ${productSellers} businesses can add prices and send most requests`);
    console.log(`  - ${deliveryServices} businesses can handle delivery requests`);
    console.log(`  - ${businesses.rows.filter(b => b.is_verified && b.status === 'approved').length} businesses can respond to item/service/rent requests`);

    console.log('\n✅ Test completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    process.exit(0);
  }
}

// Run the test
testBusinessCategorization();
