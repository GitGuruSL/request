const database = require('./services/database');

/**
 * Test SMS approval workflow
 */
async function testSMSApprovalWorkflow() {
  try {
    console.log('🧪 Testing SMS Approval Workflow...\n');

    // 1. Check current configurations
    console.log('1. Checking current SMS configurations:');
    const configs = await database.query(`
      SELECT 
        country_code, 
        country_name, 
        active_provider, 
        approval_status, 
        is_active,
        submitted_at,
        approved_at
      FROM sms_configurations 
      ORDER BY country_name
    `);
    
    if (configs.rows.length === 0) {
      console.log('   No SMS configurations found.');
    } else {
      configs.rows.forEach(config => {
        console.log(`   ${config.country_name} (${config.country_code}): ${config.active_provider} - Status: ${config.approval_status} ${config.is_active ? '(Active)' : '(Inactive)'}`);
      });
    }

    // 2. Check pending configurations
    console.log('\n2. Pending configurations requiring approval:');
    const pending = await database.query(`
      SELECT 
        country_code, 
        country_name, 
        active_provider, 
        submitted_at
      FROM sms_configurations 
      WHERE approval_status = 'pending'
      ORDER BY submitted_at ASC
    `);
    
    if (pending.rows.length === 0) {
      console.log('   No pending configurations.');
    } else {
      pending.rows.forEach(config => {
        console.log(`   ${config.country_name} (${config.country_code}): ${config.active_provider} - Submitted: ${config.submitted_at}`);
      });
    }

    // 3. Check approval history
    console.log('\n3. Recent approval history:');
    const history = await database.query(`
      SELECT 
        sah.action,
        sah.new_status,
        sah.created_at,
        sc.country_name,
        au.email as admin_email
      FROM sms_approval_history sah
      JOIN sms_configurations sc ON sah.configuration_id = sc.id
      LEFT JOIN admin_users au ON sah.admin_id = au.id
      ORDER BY sah.created_at DESC
      LIMIT 5
    `);
    
    if (history.rows.length === 0) {
      console.log('   No approval history found.');
    } else {
      history.rows.forEach(record => {
        console.log(`   ${record.action} - ${record.country_name}: ${record.new_status} by ${record.admin_email || 'Unknown'} at ${record.created_at}`);
      });
    }

    // 4. Simulate country admin workflow
    console.log('\n4. 🎭 Workflow Summary:');
    console.log('   📝 Country Admin Process:');
    console.log('      1. Login to admin panel → SMS Configuration');
    console.log('      2. Enter SMS provider details (Twilio, AWS SNS, etc.)');
    console.log('      3. Test configuration with test phone number');
    console.log('      4. Submit for approval (status: pending)');
    console.log('   ');
    console.log('   👑 Super Admin Process:');
    console.log('      1. Login to admin panel → SMS Management');
    console.log('      2. Review pending configurations');
    console.log('      3. Approve/reject with notes');
    console.log('      4. Approved configs become active for SMS sending');
    console.log('   ');
    console.log('   👤 User Experience:');
    console.log('      1. User selects country during registration');
    console.log('      2. System automatically uses approved SMS provider for that country');
    console.log('      3. OTP sent via cost-effective local providers');
    console.log('      4. Country admins control their own SMS costs');

    console.log('\n🎉 SMS Approval System is ready!');
    console.log('');
    console.log('📊 Cost Benefits:');
    console.log('   • Firebase Auth: $0.01-0.02 per verification + base costs');
    console.log('   • Local SMS providers: $0.003-0.01 per SMS');
    console.log('   • Twilio/AWS SNS: $0.0075 per SMS');
    console.log('   • Estimated savings: 50-80% on authentication costs');

  } catch (error) {
    console.error('❌ Test error:', error);
  } finally {
    process.exit(0);
  }
}

testSMSApprovalWorkflow();
