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

async function checkTables() {
  try {
    console.log('🔍 Checking PostgreSQL tables...\n');
    
    // Get all tables
    const result = await pool.query(`
      SELECT table_name, table_schema 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('📊 All tables in database:');
    result.rows.forEach(row => {
      console.log(`   ${row.table_name}`);
    });
    
    console.log('\n🌍 Country-related tables:');
    const countryTables = result.rows.filter(row => row.table_name.includes('country'));
    countryTables.forEach(row => {
      console.log(`   ${row.table_name}`);
    });
    
    // Check admin_users table structure
    console.log('\n👨‍💼 admin_users table structure:');
    const adminUsersStructure = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'admin_users' 
      ORDER BY ordinal_position
    `);
    
    if (adminUsersStructure.rows.length > 0) {
      adminUsersStructure.rows.forEach(row => {
        console.log(`   ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    } else {
      console.log('   ❌ admin_users table not found!');
    }
    
    // Check for missing core tables
    console.log('\n🔍 Checking for core tables:');
    const coreTables = [
      'users', 'admin_users', 'categories', 'subcategories', 'brands', 
      'vehicle_types', 'subscription_plans', 'master_products', 'variable_types',
      'module_management', 'countries', 'cities'
    ];
    
    const existingTables = result.rows.map(row => row.table_name);
    
    coreTables.forEach(tableName => {
      const exists = existingTables.includes(tableName);
      console.log(`   ${tableName}: ${exists ? '✅ EXISTS' : '❌ MISSING'}`);
    });
    
  } catch (error) {
    console.error('Error checking tables:', error);
  } finally {
    await pool.end();
  }
}

checkTables();
