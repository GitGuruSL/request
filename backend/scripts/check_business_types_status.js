// Quick diagnostics for business types tables
const db = require('../services/database');

async function main() {
  const code = (process.argv[2] || 'LK').toUpperCase();
  try {
    const hasCbt = await db.query('SELECT 1 FROM information_schema.tables WHERE table_schema=\'public\' AND table_name=\'country_business_types\'');
    console.log('country_business_types exists:', hasCbt.rows.length > 0);
    const bt = await db.query('SELECT COUNT(*)::int AS c FROM business_types WHERE is_active = true');
    console.log('business_types active rows:', bt.rows[0]?.c || 0);
    if (hasCbt.rows.length) {
      const cbt = await db.query('SELECT COUNT(*)::int AS c FROM country_business_types WHERE country_code = $1', [code]);
      console.log(`country_business_types rows for ${code}:`, cbt.rows[0]?.c || 0);
      const sample = await db.query('SELECT id, name, country_code, is_active FROM country_business_types WHERE country_code=$1 ORDER BY display_order, name LIMIT 5', [code]);
      console.log('sample:', sample.rows);
    }
    process.exit(0);
  } catch (e) {
    console.error('Diagnostics error:', e);
    process.exit(1);
  }
}

main();
