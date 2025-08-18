require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.PGUSER,
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  password: process.env.PGPASSWORD,
  port: process.env.PGPORT,
  ssl: { rejectUnauthorized: false }
});

async function checkUsersTable() {
  try {
    const result = await pool.query(`
      SELECT column_name, is_nullable, data_type, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('=== USERS TABLE STRUCTURE ===');
    result.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable}, default: ${row.column_default})`);
    });
    
    // Check if there are any existing users
    const userCount = await pool.query('SELECT COUNT(*) FROM users');
    console.log(`\nTotal users: ${userCount.rows[0].count}`);
    
    // Check a sample user if any exist
    if (parseInt(userCount.rows[0].count) > 0) {
      const sample = await pool.query('SELECT * FROM users LIMIT 1');
      console.log('\nSample user structure:');
      console.log('Columns:', Object.keys(sample.rows[0]));
    }
    
    pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    pool.end();
  }
}

checkUsersTable();
