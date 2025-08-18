require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PGHOST,
  port: process.env.PGPORT,
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  ssl: { rejectUnauthorized: false }
});

async function checkBusinessProductsTable() {
  try {
    console.log('🔍 Checking business_products table structure...\n');
    
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'business_products'
      ORDER BY ordinal_position
    `);
    
    if (result.rows.length > 0) {
      console.log('📊 business_products table structure:');
      result.rows.forEach(row => {
        console.log(`   ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    } else {
      console.log('   ❌ Table business_products not found!');
    }
    
    // Also check app_countries for duplicates
    console.log('\n🔍 Checking app_countries duplicates...');
    const duplicates = await pool.query(`
      SELECT code, COUNT(*) as count 
      FROM app_countries 
      GROUP BY code 
      HAVING COUNT(*) > 1
    `);
    
    if (duplicates.rows.length > 0) {
      console.log('📊 Duplicate country codes:');
      duplicates.rows.forEach(row => {
        console.log(`   ${row.code}: ${row.count} entries`);
      });
    } else {
      console.log('   ✅ No duplicates found');
    }
    
  } catch (error) {
    console.error('Error checking tables:', error);
  } finally {
    await pool.end();
  }
}

checkBusinessProductsTable();
