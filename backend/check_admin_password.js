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

async function checkPassword() {
  try {
    const result = await pool.query('SELECT email, password_hash FROM admin_users WHERE email = $1', ['superadmin@request.lk']);
    console.log('Admin user password info:', result.rows[0]);
    console.log('Password hash exists:', !!result.rows[0]?.password_hash);
    console.log('Password hash length:', result.rows[0]?.password_hash?.length);
    pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    pool.end();
  }
}

checkPassword();
