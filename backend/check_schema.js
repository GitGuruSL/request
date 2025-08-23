const db = require('./services/database');

(async () => {
  try {
    console.log('=== Country Products Table ===');
    const countryProducts = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'country_products' 
      ORDER BY ordinal_position
    `);
    console.log('Country Products Columns:', countryProducts.rows);

    console.log('\n=== Price Listings Table ===');
    const priceListings = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'price_listings' 
      ORDER BY ordinal_position
    `);
    console.log('Price Listings Columns:', priceListings.rows);

    console.log('\n=== Sample Country Products ===');
    const sample = await db.query('SELECT * FROM country_products LIMIT 5');
    console.log('Sample Data:', sample.rows);

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit();
  }
})();
