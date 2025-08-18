const DatabaseService = require('./services/database');

async function testFullCategoryFlow() {
  try {
    console.log('🧪 Testing full category flow for Flutter app...\n');
    
    // Test 1: Get item categories
    console.log('1️⃣ Testing item categories:');
    const itemCategories = await DatabaseService.query(`
      SELECT id, name, type 
      FROM categories 
      WHERE type = 'item' AND is_active = true 
      ORDER BY name;
    `);
    
    console.log(`   Found ${itemCategories.rows.length} item categories:`);
    itemCategories.rows.forEach(cat => {
      console.log(`   - ${cat.name} (${cat.id})`);
    });
    
    // Test 2: Get subcategories for first item category
    if (itemCategories.rows.length > 0) {
      const firstCategory = itemCategories.rows[0];
      console.log(`\n2️⃣ Testing subcategories for "${firstCategory.name}":`);
      
      const subcategories = await DatabaseService.query(`
        SELECT id, name, category_id 
        FROM sub_categories 
        WHERE category_id = $1 AND is_active = true 
        ORDER BY name;
      `, [firstCategory.id]);
      
      console.log(`   Found ${subcategories.rows.length} subcategories:`);
      subcategories.rows.forEach(sub => {
        console.log(`   - ${sub.name} (${sub.id})`);
      });
    }
    
    // Test 3: Test service categories
    console.log('\n3️⃣ Testing service categories:');
    const serviceCategories = await DatabaseService.query(`
      SELECT id, name, type 
      FROM categories 
      WHERE type = 'service' AND is_active = true 
      ORDER BY name;
    `);
    
    console.log(`   Found ${serviceCategories.rows.length} service categories:`);
    serviceCategories.rows.forEach(cat => {
      console.log(`   - ${cat.name} (${cat.id})`);
    });
    
    // Test 4: Test rental categories
    console.log('\n4️⃣ Testing rental categories:');
    const rentalCategories = await DatabaseService.query(`
      SELECT id, name, type 
      FROM categories 
      WHERE type = 'rent' AND is_active = true 
      ORDER BY name;
    `);
    
    console.log(`   Found ${rentalCategories.rows.length} rental categories:`);
    rentalCategories.rows.forEach(cat => {
      console.log(`   - ${cat.name} (${cat.id})`);
    });
    
    console.log('\n✅ Category flow test completed!');
    
  } catch (error) {
    console.error('❌ Error testing category flow:', error);
  } finally {
    process.exit();
  }
}

testFullCategoryFlow();
