const DatabaseService = require('./services/database');

async function testElectronicsSubcategories() {
  try {
    console.log('🔌 Testing Electronics subcategories...\n');
    
    const electronicsId = '732f29d3-637b-4c20-9c6d-e90f472143f7';
    
    const subcategories = await DatabaseService.query(`
      SELECT id, name, category_id, is_active 
      FROM sub_categories 
      WHERE category_id = $1 
      ORDER BY name;
    `, [electronicsId]);
    
    console.log(`📊 Found ${subcategories.rows.length} subcategories for Electronics:`);
    subcategories.rows.forEach(sub => {
      console.log(`   - ${sub.name} (${sub.id}) - Active: ${sub.is_active}`);
    });
    
    // Also test the API endpoint
    console.log('\n🌐 Testing API endpoint equivalent:');
    const apiResult = await DatabaseService.findMany('sub_categories', 
      { category_id: electronicsId, is_active: true }, 
      { orderBy: 'name', orderDirection: 'ASC' }
    );
    
    console.log(`📊 API-style query found ${apiResult.length} active subcategories:`);
    apiResult.forEach(sub => {
      console.log(`   - ${sub.name} (${sub.id})`);
    });
    
  } catch (error) {
    console.error('❌ Error testing Electronics subcategories:', error);
  } finally {
    process.exit();
  }
}

testElectronicsSubcategories();
