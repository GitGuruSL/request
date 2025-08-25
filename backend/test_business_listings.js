const { pool } = require('./services/database');

async function findBusinessUserId() {
  try {
    // First check what columns exist
    const columnsResult = await pool.query(
      "SELECT column_name FROM information_schema.columns WHERE table_name = 'business_verifications'"
    );
    console.log('Available columns:', columnsResult.rows.map(row => row.column_name));
    
    // Now check for user with different possible column names
    const result = await pool.query(
      'SELECT user_id FROM business_verifications WHERE user_id = $1', 
      ['FKqy4Qfqh4gzwHV9WqZ7g2sFkKs1']
    );
    
    if (result.rows.length > 0) {
      console.log('Business user_id:', result.rows[0].user_id);
      
      // Now test the API with the correct user_id
      const listingsResult = await pool.query(`
        SELECT 
          pl.id,
          pl.title,
          pl.price,
          ps.staged_price,
          CASE 
            WHEN ps.id IS NOT NULL AND ps.is_processed = false THEN true 
            ELSE false 
          END as has_pending_changes
        FROM price_listings pl
        LEFT JOIN price_staging ps ON pl.id = ps.price_listing_id AND ps.is_processed = false
        WHERE pl.business_id = $1
      `, [result.rows[0].user_id]);
      
      console.log('Price listings for this business:');
      listingsResult.rows.forEach(row => {
        console.log(`- ${row.title}: $${row.price} ${row.has_pending_changes ? '(STAGING: $' + row.staged_price + ')' : '(ACTIVE)'}`);
      });
    } else {
      console.log('Business not found with that user_id, trying to find any business...');
      
      // Find any business that has price listings
      const anyBusinessResult = await pool.query(`
        SELECT DISTINCT pl.business_id, COUNT(*) as listing_count
        FROM price_listings pl
        GROUP BY pl.business_id
        LIMIT 5
      `);
      
      console.log('Businesses with listings:', anyBusinessResult.rows);
    }
  } catch (error) {
    console.error('Error:', error);
  }
  
  process.exit(0);
}

findBusinessUserId();
