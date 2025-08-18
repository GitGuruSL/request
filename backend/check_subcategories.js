const DatabaseService = require('./services/database');

async function checkSubcategoriesStructure() {
  try {
    console.log('🔍 Checking sub_categories table structure...');
    
    const subcategoriesInfo = await DatabaseService.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'sub_categories'
      ORDER BY ordinal_position;
    `);
    
    console.log('📋 Sub_categories table columns:');
    subcategoriesInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Sample subcategories data
    const sampleSubs = await DatabaseService.query(`
      SELECT * FROM sub_categories LIMIT 5;
    `);
    
    console.log('📊 Sample subcategories data:');
    sampleSubs.rows.forEach(sub => {
      console.log(`  - ID: ${sub.id}, Name: ${sub.name}, Category ID: ${sub.category_id}`);
    });
    
  } catch (error) {
    console.error('❌ Error checking subcategories structure:', error);
  } finally {
    process.exit();
  }
}

checkSubcategoriesStructure();
