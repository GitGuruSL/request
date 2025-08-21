// Check admin users in database
const { Pool } = require('pg');

const pool = new Pool({
  host: 'requestdb.cq70gkkamvcs.us-east-1.rds.amazonaws.com',
  port: 5432,
  database: 'request',
  user: 'requestadmindb',
  password: 'RequestMarketplace2024!',
  ssl: {
    rejectUnauthorized: false
  }
});

async function checkAdminUsers() {
  try {
    console.log('🔄 Checking admin users...');
    
    // Check if admin_users table exists
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'admin_users'
    `);
    
    if (tableCheck.rows.length === 0) {
      console.log('❌ admin_users table does not exist');
      return;
    }
    
    console.log('✅ admin_users table exists');
    
    // Get admin users
    const adminUsers = await pool.query(`
      SELECT id, email, name, role, country_code, is_active, created_at
      FROM admin_users 
      ORDER BY created_at
    `);
    
    console.log(`\n📊 Total admin users: ${adminUsers.rows.length}`);
    
    if (adminUsers.rows.length > 0) {
      console.log('\n👥 Admin Users:');
      adminUsers.rows.forEach((user, index) => {
        console.log(`\n  User ${index + 1}:`);
        console.log(`    ID: ${user.id}`);
        console.log(`    Email: ${user.email}`);
        console.log(`    Name: ${user.name}`);
        console.log(`    Role: ${user.role}`);
        console.log(`    Country: ${user.country_code || 'N/A'}`);
        console.log(`    Active: ${user.is_active}`);
        console.log(`    Created: ${user.created_at}`);
      });
      
      // Find super admin
      const superAdmin = adminUsers.rows.find(user => user.role === 'super_admin');
      if (superAdmin) {
        console.log('\n👑 Super Admin found:', superAdmin.email);
      } else {
        console.log('\n⚠️ No super admin found');
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkAdminUsers();
