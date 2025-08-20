const database = require('./services/database');

async function testBusinessQuery() {
  try {
    const userId = '5af58de3-896d-4cc3-bd0b-177054916335';
    
    console.log('🔍 Querying business verification...');
    const query = `
      SELECT bv.*
      FROM business_verifications bv
      WHERE bv.user_id = $1
    `;
    
    const result = await database.query(query, [userId]);
    
    if (result.rows.length === 0) {
      console.log('❌ No business verification found');
      process.exit(0);
    }

    const row = result.rows[0];
    console.log('🏢 Raw business verification data:');
    console.log('- Status:', row.status);
    console.log('- Is Verified:', row.is_verified);
    console.log('- Phone Verified:', row.phone_verified);
    console.log('- Email Verified:', row.email_verified);
    console.log('- Business Name:', row.business_name);
    console.log('- Country:', row.country);
    console.log('- Created:', row.created_at);
    
    // Transform data like the API does
    const transformedData = {
      ...row,
      businessName: row.business_name,
      businessEmail: row.business_email,
      businessPhone: row.business_phone,
      businessAddress: row.business_address,
      businessCategory: row.business_category,
      businessDescription: row.business_description,
      licenseNumber: row.license_number,
      taxId: row.tax_id,
      countryName: row.country_name,
      isVerified: row.is_verified,
      phoneVerified: row.phone_verified,
      emailVerified: row.email_verified,
      status: row.status
    };
    
    console.log('\n📦 Transformed API response would be:');
    console.log(JSON.stringify({
      success: true,
      data: transformedData
    }, null, 2));
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testBusinessQuery();
