const { Pool } = require('pg');
require('dotenv').config({ path: '.env.rds' });

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

async function testConnection() {
    try {
        console.log('🔗 Testing RDS database connection...');
        console.log(`📍 Connecting to: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
        console.log(`🗄️  Database: ${process.env.DB_NAME}`);
        console.log(`👤 User: ${process.env.DB_USERNAME}`);
        
        const client = await pool.connect();
        
        const result = await client.query('SELECT version(), current_database(), current_user, now()');
        console.log('\n✅ Database connection successful!');
        console.log('=======================================');
        console.log('📋 Database Information:');
        console.log(`   Version: ${result.rows[0].version.split(' ').slice(0, 2).join(' ')}`);
        console.log(`   Database: ${result.rows[0].current_database}`);
        console.log(`   User: ${result.rows[0].current_user}`);
        console.log(`   Current Time: ${result.rows[0].now}`);
        
        // Test if we can create tables
        console.log('\n🧪 Testing table creation permissions...');
        try {
            await client.query('CREATE TABLE IF NOT EXISTS connection_test (id SERIAL PRIMARY KEY, test_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
            await client.query('INSERT INTO connection_test DEFAULT VALUES');
            const testResult = await client.query('SELECT COUNT(*) as count FROM connection_test');
            console.log(`✅ Table operations successful! Test records: ${testResult.rows[0].count}`);
            await client.query('DROP TABLE connection_test');
            console.log('✅ Cleanup successful!');
        } catch (error) {
            console.log('❌ Table creation test failed:', error.message);
        }
        
        client.release();
        
        console.log('\n🎉 RDS Database is ready for migration!');
        console.log('=======================================');
        console.log('🔜 Next Steps:');
        console.log('   1. Create database schema: node create-schema.js');
        console.log('   2. Export Firebase data: node firebase-export.js');
        console.log('   3. Import data to PostgreSQL: node import-data.js');
        
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Database connection failed!');
        console.error('=======================================');
        console.error('Error:', error.message);
        console.error('\nPossible solutions:');
        console.error('1. Check if the database password is correct');
        console.error('2. Verify security group allows connections from your IP');
        console.error('3. Ensure the RDS instance is in "available" status');
        console.error('4. Check network connectivity');
        
        process.exit(1);
    }
}

console.log('🚀 Request Marketplace - RDS Connection Test');
console.log('==============================================');
testConnection();
