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

async function checkAdmin() {
  try {
    console.log('Checking admin_users data...');
    const data = await pool.query('SELECT email, role, password_hash FROM admin_users WHERE email = $1', ['superadmin@request.lk']);
    console.log('Admin user found:', data.rows.length > 0);
    if (data.rows.length > 0) {
      const user = data.rows[0];
      console.log('Email:', user.email);
      console.log('Role:', user.role);
      console.log('Has password_hash:', !!user.password_hash);
      console.log('Password_hash length:', user.password_hash ? user.password_hash.length : 0);
      console.log('Password_hash value:', user.password_hash);
      console.log('Password_hash type:', typeof user.password_hash);
    }
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkAdmin();
