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

async function checkTables() {
  try {
    // Check all tables with 'subscription' in name
    console.log('=== TABLES WITH SUBSCRIPTION ===');
    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE '%subscription%'
    `);
    console.log('Subscription tables:', tables.rows.map(r => r.table_name));
    
    // Check all tables with 'vehicle' in name
    console.log('\n=== TABLES WITH VEHICLE ===');
    const vehicleTables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE '%vehicle%'
    `);
    console.log('Vehicle tables:', vehicleTables.rows.map(r => r.table_name));
    
    // Check subscription_plans_new table specifically
    console.log('\n=== SUBSCRIPTION_PLANS_NEW TABLE ===');
    try {
      const subPlansNew = await pool.query('SELECT * FROM subscription_plans_new LIMIT 3');
      console.log('Columns:', Object.keys(subPlansNew.rows[0] || {}));
      console.log('Row count:', subPlansNew.rowCount);
      if (subPlansNew.rows.length > 0) {
        console.log('Sample data:', subPlansNew.rows[0]);
      }
    } catch (err) {
      console.log('subscription_plans_new table does not exist');
    }
    
    // Check vehicle_types table
    console.log('\n=== VEHICLE_TYPES TABLE ===');
    try {
      const vehicleTypes = await pool.query('SELECT * FROM vehicle_types LIMIT 3');
      console.log('Columns:', Object.keys(vehicleTypes.rows[0] || {}));
      console.log('Row count:', vehicleTypes.rowCount);
      if (vehicleTypes.rows.length > 0) {
        console.log('Sample data:', vehicleTypes.rows[0]);
      }
    } catch (err) {
      console.log('vehicle_types table does not exist');
    }
    
    pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    pool.end();
  }
}

checkTables();
