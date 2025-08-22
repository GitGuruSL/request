require('dotenv').config();
const pool = require('./services/database');

async function checkResponseLocation() {
  try {
    console.log('🔍 Checking response location data...');
    
    // Get the latest response record
    const result = await pool.query(`
      SELECT 
        id, request_id, user_id, message, price, currency, 
        location_address, location_latitude, location_longitude, 
        country_code, metadata, created_at
      FROM responses 
      ORDER BY created_at DESC 
      LIMIT 1
    `);
    
    if (result.rows.length === 0) {
      console.log('❌ No responses found');
      return;
    }
    
    const response = result.rows[0];
    console.log('📋 Latest Response Details:');
    console.log('  ID:', response.id);
    console.log('  Request ID:', response.request_id);
    console.log('  Message:', response.message);
    console.log('  Price:', response.price);
    console.log('  Currency:', response.currency);
    console.log('  Location Address:', response.location_address);
    console.log('  Location Latitude:', response.location_latitude);
    console.log('  Location Longitude:', response.location_longitude);
    console.log('  Country Code:', response.country_code);
    console.log('  Metadata:', response.metadata);
    console.log('  Created At:', response.created_at);
    
    console.log('\n✅ Location data check complete!');
    
  } catch (error) {
    console.error('❌ Error checking response location:', error);
  } finally {
    await pool.end();
  }
}

checkResponseLocation();
