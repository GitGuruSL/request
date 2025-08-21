// Test business verifications data in database
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

async function checkBusinessVerifications() {
  try {
    console.log('🔄 Checking business verifications data...');
    
    // Check if business_verifications table exists
    const tableCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'business_verifications'
    `);
    
    if (tableCheck.rows.length === 0) {
      console.log('❌ business_verifications table does not exist');
      return;
    }
    
    console.log('✅ business_verifications table exists');
    
    // Get table structure
    const structure = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'business_verifications'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Table structure:');
    structure.rows.forEach(col => {
      console.log(`  ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
    // Get count of records
    const count = await pool.query('SELECT COUNT(*) FROM business_verifications');
    console.log(`\n📊 Total records: ${count.rows[0].count}`);
    
    // Get sample data focusing on document URLs
    const sampleData = await pool.query(`
      SELECT 
        id, 
        business_name,
        status,
        business_license_url,
        tax_certificate_url,
        insurance_document_url,
        business_logo_url,
        created_at
      FROM business_verifications 
      ORDER BY created_at DESC 
      LIMIT 3
    `);
    
    console.log('\n📄 Sample records:');
    sampleData.rows.forEach((row, index) => {
      console.log(`\n  Record ${index + 1}:`);
      console.log(`    ID: ${row.id}`);
      console.log(`    Business Name: ${row.business_name}`);
      console.log(`    Status: ${row.status}`);
      console.log(`    Business License URL: ${row.business_license_url || 'NULL'}`);
      console.log(`    Tax Certificate URL: ${row.tax_certificate_url || 'NULL'}`);
      console.log(`    Insurance Document URL: ${row.insurance_document_url || 'NULL'}`);
      console.log(`    Business Logo URL: ${row.business_logo_url || 'NULL'}`);
      console.log(`    Created: ${row.created_at}`);
      
      // Check if this record has any document URLs
      const hasUrls = row.business_license_url || row.tax_certificate_url || 
                     row.insurance_document_url || row.business_logo_url;
      console.log(`    Has Documents: ${hasUrls ? 'YES' : 'NO'}`);
    });
    
    // Check for records with document URLs
    const withDocs = await pool.query(`
      SELECT COUNT(*) 
      FROM business_verifications 
      WHERE business_license_url IS NOT NULL 
         OR tax_certificate_url IS NOT NULL 
         OR insurance_document_url IS NOT NULL 
         OR business_logo_url IS NOT NULL
    `);
    
    console.log(`\n📎 Records with document URLs: ${withDocs.rows[0].count} out of ${count.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkBusinessVerifications();
