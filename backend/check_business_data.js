const db = require('./services/database');

async function checkBusinessData() {
  try {
    const result = await db.query('SELECT * FROM business_verifications ORDER BY created_at DESC LIMIT 1');
    console.log('=== Business Verification Data ===');
    if (result.rows.length > 0) {
      const record = result.rows[0];
      console.log(JSON.stringify(record, null, 2));
    } else {
      console.log('No business verification records found');
    }
  } catch (error) {
    console.error('Error:', error);
  }
  process.exit(0);
}

checkBusinessData();
