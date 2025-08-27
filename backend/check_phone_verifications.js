const db = require('./services/database');

(async () => {
  try {
    console.log('📋 Checking phone_verifications table structure...');
    
    // Check table structure
    const structure = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'phone_verifications' 
      ORDER BY ordinal_position
    `);
    
    console.log('Columns:');
    structure.rows.forEach(col => {
      console.log(`   ${col.column_name}: ${col.data_type}`);
    });
    
    // Check recent phone verifications
    console.log('\n📱 Recent phone verifications (last hour):');
    const recent = await db.query(`
      SELECT phone, otp_type, status, created_at, attempts 
      FROM phone_verifications 
      WHERE created_at > NOW() - INTERVAL '1 hour' 
      ORDER BY created_at DESC 
      LIMIT 5
    `);
    
    if (recent.rows.length > 0) {
      recent.rows.forEach(r => {
        console.log(`   ${r.phone}: ${r.otp_type} - ${r.status} (${r.attempts} attempts)`);
        console.log(`      Created: ${r.created_at}`);
      });
    } else {
      console.log('   No recent OTP requests');
    }
    
    // Check all phone verifications in last 24 hours
    console.log('\n📊 All phone verifications (last 24 hours):');
    const all24h = await db.query(`
      SELECT COUNT(*) as total,
             COUNT(CASE WHEN status = 'verified' THEN 1 END) as verified,
             COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
             COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired
      FROM phone_verifications 
      WHERE created_at > NOW() - INTERVAL '24 hours'
    `);
    
    if (all24h.rows[0]) {
      const stats = all24h.rows[0];
      console.log(`   Total: ${stats.total}`);
      console.log(`   Verified: ${stats.verified}`);
      console.log(`   Pending: ${stats.pending}`);
      console.log(`   Expired: ${stats.expired}`);
    }
    
  } catch(e) {
    console.error('❌ Error checking phone verifications:', e.message);
  } finally {
    process.exit(0);
  }
})();
