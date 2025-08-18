const DatabaseService = require('./services/database');

async function checkCategoriesTableStructure() {
  try {
    console.log('🔍 Checking categories table structure...');
    
    // Check categories table structure
    const categoriesInfo = await DatabaseService.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'categories'
      ORDER BY ordinal_position;
    `);
    
    console.log('📋 Categories table columns:');
    categoriesInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Check subcategories table structure  
    const subcategoriesInfo = await DatabaseService.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'subcategories' OR table_name = 'sub_categories'
      ORDER BY table_name, ordinal_position;
    `);
    
    console.log('📋 Subcategories table columns:');
    subcategoriesInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    // Sample some data
    const sampleCategories = await DatabaseService.query(`
      SELECT * FROM categories LIMIT 5;
    `);
    
    console.log('📊 Sample categories data:');
    sampleCategories.rows.forEach(cat => {
      console.log(`  - ID: ${cat.id}, Name: ${cat.name}, Type: ${cat.type || 'NULL'}`);
    });
    
  } catch (error) {
    console.error('❌ Error checking table structure:', error);
  } finally {
    process.exit();
  }
}

checkCategoriesTableStructure();
