const database = require('./services/database');

async function checkCountryProducts() {
  try {
    console.log('Checking country_products table...\n');

    // Check total count
    const countResult = await database.query(
      'SELECT COUNT(*) as total FROM country_products WHERE country_code = $1',
      ['LK']
    );
    console.log(`Total country products for LK: ${countResult.rows[0].total}`);

    // Check active products
    const activeCountResult = await database.query(
      'SELECT COUNT(*) as total FROM country_products WHERE country_code = $1 AND is_active = true',
      ['LK']
    );
    console.log(`Active country products for LK: ${activeCountResult.rows[0].total}`);

    // Get sample of products with their master product info
    const sampleResult = await database.query(`
      SELECT 
        cp.id as country_product_id,
        cp.product_id,
        cp.is_active as country_active,
        mp.name as product_name,
        mp.is_active as master_active
      FROM country_products cp
      LEFT JOIN master_products mp ON cp.product_id = mp.id
      WHERE cp.country_code = $1
      ORDER BY mp.name
      LIMIT 10
    `, ['LK']);

    console.log('\nSample products:');
    sampleResult.rows.forEach(row => {
      console.log(`- ${row.product_name} (ID: ${row.product_id})`);
      console.log(`  Country active: ${row.country_active}, Master active: ${row.master_active}`);
    });

    // Check what the API endpoint would return
    console.log('\nTesting API query (same as endpoint):');
    const apiResult = await database.query(`
      SELECT 
        mp.id,
        mp.name,
        mp.slug,
        mp.brand_id,
        mp.base_unit,
        mp.is_active,
        mp.created_at,
        mp.updated_at,
        cp.is_active AS country_specific_active,
        COALESCE(cp.is_active, mp.is_active) AS country_enabled,
        cp.id AS country_product_id
      FROM master_products mp
      LEFT JOIN country_products cp 
        ON mp.id = cp.product_id 
       AND cp.country_code = $1
      WHERE mp.is_active = true
      ORDER BY mp.name
      LIMIT 10
    `, ['LK']);

    console.log('API would return:');
    apiResult.rows.forEach(row => {
      console.log(`- ${row.name} (country_enabled: ${row.country_enabled})`);
    });

  } catch (error) {
    console.error('Error checking country products:', error);
  }
}

checkCountryProducts();
