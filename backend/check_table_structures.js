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

async function checkTableStructures() {
  try {
    console.log('🔍 Checking table structures...\n');
    
    const tables = [
      'app_countries',
      'sub_categories', 
      'subscription_plans_new',
      'variables'
    ];
    
    for (const tableName of tables) {
      console.log(`📊 ${tableName} table structure:`);
      
      const result = await pool.query(`
        SELECT column_name, data_type, is_nullable, column_default 
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position
      `, [tableName]);
      
      if (result.rows.length > 0) {
        result.rows.forEach(row => {
          console.log(`   ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
        });
      } else {
        console.log(`   ❌ Table ${tableName} not found!`);
      }
      console.log('');
    }
    
  } catch (error) {
    console.error('Error checking table structures:', error);
  } finally {
    await pool.end();
  }
}

checkTableStructures();
