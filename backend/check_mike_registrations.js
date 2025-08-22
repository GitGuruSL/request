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

async function checkMikeRegistrations() {
  try {
    // First check users table structure
    const tableStructure = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    
    console.log('👥 Users table structure:');
    tableStructure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}`);
    });
    
    // Find Mike Rose user (check common column names)
    const userResult = await pool.query(`
      SELECT id, display_name, email 
      FROM users 
      WHERE LOWER(display_name) LIKE '%mike%' OR LOWER(email) LIKE '%mike%'
      LIMIT 5
    `);
    
    if (userResult.rows.length === 0) {
      console.log('❌ No user found matching "mike"');
      // Show first few users for reference
      const allUsers = await pool.query(`SELECT id, display_name, email FROM users LIMIT 5`);
      console.log('👥 Sample users:');
      allUsers.rows.forEach(user => console.log(`  - ${user.display_name} (${user.email})`));
      return;
    }
    
    const user = userResult.rows[0];
    console.log('👤 Found user:', user);
    
    // Check driver registration
    const driverResult = await pool.query(`
      SELECT dv.*, vt.name as vehicle_type_name 
      FROM driver_verifications dv
      LEFT JOIN vehicle_types vt ON dv.vehicle_type_id = vt.id
      WHERE dv.user_id = $1
    `, [user.id]);
    
    console.log('🚗 Driver registrations:', driverResult.rows);
    
    // Check business registration
    const businessResult = await pool.query(`
      SELECT * FROM business_verifications 
      WHERE user_id = $1
    `, [user.id]);
    
    console.log('🏢 Business registrations:', businessResult.rows);
    
    // Check current requests to see what should be filtered
    const requestsResult = await pool.query(`
      SELECT id, title, request_type, metadata 
      FROM requests 
      WHERE status = 'active'
      ORDER BY request_type, created_at DESC
    `);
    
    console.log('\n📝 Current active requests by type:');
    const requestsByType = requestsResult.rows.reduce((acc, req) => {
      if (!acc[req.request_type]) acc[req.request_type] = [];
      acc[req.request_type].push(req);
      return acc;
    }, {});
    
    Object.keys(requestsByType).forEach(type => {
      console.log(`\n${type.toUpperCase()} requests (${requestsByType[type].length}):`);
      requestsByType[type].forEach(req => {
        console.log(`  - ${req.title} (${req.id})`);
        if (req.metadata && req.metadata.vehicle_type_id) {
          console.log(`    Vehicle Type ID: ${req.metadata.vehicle_type_id}`);
        }
      });
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

checkMikeRegistrations();
