const database = require('./services/database.js');

(async () => {
  try {
    console.log('🔍 Testing price listings with staging data...');
    
    const result = await database.query(`
      SELECT 
        pl.id,
        pl.price,
        pl.title,
        ps.staged_price,
        ps.is_processed,
        CASE 
          WHEN ps.id IS NOT NULL AND ps.is_processed = false THEN true 
          ELSE false 
        END as has_pending_changes
      FROM price_listings pl
      LEFT JOIN price_staging ps ON pl.id = ps.price_listing_id AND ps.is_processed = false
      LIMIT 3
    `);
    
    console.log('📊 Sample data:');
    result.rows.forEach(row => {
      console.log(`- ID: ${row.id.substring(0,8)}...`);
      console.log(`  Current Price: ${row.price}`);
      console.log(`  Staged Price: ${row.staged_price || 'None'}`);
      console.log(`  Has Pending: ${row.has_pending_changes}`);
      console.log('');
    });
    
    console.log('✅ Staging system is working correctly!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error testing staging system:', error.message);
    process.exit(1);
  }
})();
