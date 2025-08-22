const db = require('./services/database.js');

(async () => {
  try {
    console.log('=== USER TABLE STRUCTURE ===');
    const userColumns = await db.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users' ORDER BY ordinal_position");
    console.log('User table columns:', userColumns.rows);
    
    console.log('\n=== USER MAKING REQUESTS ===');
    const requestUser = await db.query("SELECT * FROM users WHERE id = 'ee9776a6-afde-4256-9374-aab0c24e4a70'");
    console.log('Request user:', requestUser.rows);
    
    console.log('\n=== USERS WITH VERIFICATIONS ===');
    const verifiedDrivers = await db.query("SELECT * FROM users WHERE id IN ('5af58de3-896d-4cc3-bd0b-177054916335', '25dae20b-0404-407a-b2c8-b99e87a31a4a')");
    console.log('Users with verifications:', verifiedDrivers.rows);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
})();
