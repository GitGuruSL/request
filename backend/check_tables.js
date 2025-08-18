const dbService = require('./services/database');

async function showTables() {
  try {
    const result = await dbService.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
    );
    console.log('Available database tables:');
    result.rows.forEach(row => console.log('- ' + row.table_name));
    
    // Show table counts for some key tables
    console.log('\nTable row counts:');
    const tables = ['users', 'categories', 'subcategories', 'brands', 'products', 'countries', 'cities', 'vehicles', 'variable_types'];
    
    for (const table of tables) {
      try {
        const countResult = await dbService.query(`SELECT COUNT(*) as count FROM ${table}`);
        console.log(`- ${table}: ${countResult.rows[0].count} rows`);
      } catch (e) {
        console.log(`- ${table}: table not found or error`);
      }
    }
    
    process.exit(0);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
}

showTables();
